#!/bin/bash
# Common lab prepare routines

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit 1
fi

. "$RL_SCRIPTS_SRC/utils/functions.sh"

RL_LAB_CONFIG_DIR="/etc/rl-labs"
RL_RUNTIME_DIR="/run/rl-labs"
RL_MN_LOGFILE="/var/log/rl-labs.log"
RL_MN_NOTIFY_FILE="${RL_RUNTIME_DIR}/.notify-started"


# utility debug printing functions
function _debug() {
	if [[ -n "$DEBUG" ]]; then echo "$@" >&2; fi
}
function @silent() {
	if [[ -z "$DEBUG" ]]; then
		"$@" &>/dev/null
	else
		"$@"
	fi
}

# Executes the given command inside a container (using its configured shell)
# Basically, it's a wrapper for docker-exec, but allows for extra functionality
# like --shell for shell command execution.
# Also recognizes the special 'host' name, doing direct command execution in this
# case.
function rl_ctexec() {
	# parse cmdline args
	local USE_SHELL=
	local -a DOCKER_ARGS=()
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
			-s | --shell )
				USE_SHELL="1" ;;
			-i | --stdin )
				DOCKER_ARGS+=("-i") ;;
			-*)
				echo "Unexpected option: $1"; return 1 ;;
			*) break ;;
		esac; shift;
	done
	local CT="$1"; shift
	if [[ -n "$USE_SHELL" ]]; then
		# stringify shell parameters
		local STR_CMD="$*"
		if [[ $# -gt 1 ]]; then\
			# multiple arguments => shell escape them
			STR_CMD="$(printf "%q " "${@}")";
		elif [[ "$STR_CMD" == "-" ]]; then
			# read shell script from stdin
			STR_CMD=$(</dev/stdin)
		fi
		set -- /bin/bash -c "$STR_CMD"
	fi
	_debug "ctexec: $CT: $(printf "'%s' " "$@")"
	if [[ "$CT" == "host" ]]; then
		"${@}"
	else
		docker exec "${DOCKER_ARGS[@]}" "mn.$CT" "${@}"
	fi
}

# disable docker bridge network + dhcp/iptables autoconfiguration features
function rl_docker_setup_nobridge() {
	cat <<-EOF > /tmp/docker-daemon.json
	{
		"mtu": 1450,
		"exec-opts": ["native.cgroupdriver=systemd"],
		"features": { "buildkit": true },
		"experimental": true,
		"cgroup-parent": "docker.slice",
		"iptables": false,
		"bridge": "none",
		"ip-forward": false,
		"ipv6": true
	}
	EOF
	if ! cmp /tmp/docker-daemon.json /etc/docker/daemon.json >/dev/null 2>&1; then
		cp -f /tmp/docker-daemon.json /etc/docker/daemon.json
		systemctl -q disable --now docker.socket
		systemctl -q enable docker.service
		systemctl -q restart docker
	fi
}

function rl_start_topology() {
	mkdir -p "$RL_RUNTIME_DIR"
	rm -f "$RL_MN_NOTIFY_FILE"
	if [[ "$1" == "--exec" ]]; then
		# execute synchronously
		shift
		export PYTHONPATH="$RL_SCRIPTS_SRC/base/python/"
		exec python3 "$@"
	fi
	# otherwise, start in background:
	(
		export PYTHONPATH="$RL_SCRIPTS_SRC/base/python/"
		nohup python3 "$@" &>"$RL_MN_LOGFILE"
	)&
	local SCRIPT_PID=$!
	(
		touch "$RL_MN_LOGFILE"
		tail -q -f --pid "$SCRIPT_PID" "$RL_MN_LOGFILE"
	)&
	local TAIL_PID=$!
	# wait for the topology to init
	echo "Wait for ContainerNet to start..."
	local SLEEP_DELAYS=(2 4 7 8 10 10 10 10 10 10 10 10 10)  # times out after this
	local I=0
	while [[ ! -f "$RL_MN_NOTIFY_FILE" ]]; do
		if [[ -z "${SLEEP_DELAYS[$I]}" ]]; then echo "FATAL: Operation timed out!"; return 1; fi
		sleep "${SLEEP_DELAYS[$I]}"
		I="$(( "$I" + 1 ))"
		echo "Still waiting..."
	done
	echo "ContainerNet successfully started!"
}

function rl_stop_topology() {
	kill %$(jobs | grep -i topology.py | cut -c2) &>/dev/null || true
	mn -c -v output
}

# Installs the given topology as persistent service (across reboots)
function rl_install_persist_topo() {
	cp "$RL_SCRIPTS_SRC/base/rl-topology.service" -f /etc/systemd/system/rl-topology.service
	mkdir -p "$RL_LAB_CONFIG_DIR"
	echo "RL_LAB=$1" > "$RL_LAB_CONFIG_DIR/persist-environment"
	chmod 755 /etc/systemd/system/rl-topology.service
	systemctl -q daemon-reload
	systemctl -q enable rl-topology
	echo "Persistent rl-topology service enabled!"
}

# Checks the running status of a MiniNet container
function rl_ct_check() {
	[ "$( docker container inspect -f '{{.State.Running}}' "mn.$1" 2>/dev/null )" == "true" ]
}

function rl_ct_wait_for_boot() {
	local cmd='systemctl is-system-running 2>/dev/null'
	 "$1" 'while [[ ! "$('"$cmd"')" =~ (running|degraded) ]]; do sleep 1; done'
}

# Cleans up all networking configuration & stops/removes all MN containers
function rl_cfg_cleanall() {
	(
		set +e  # ignore errors
		# kill any leftover mininet containers
		local MN_CONTAINERS="$(docker ps -q -a --filter 'label=com.containernet')"
		if [[ -n "$MN_CONTAINERS" ]]; then
			_debug "Killing leftover containers..."
			docker kill $MN_CONTAINERS
			docker container rm --force $MN_CONTAINERS
			_debug "reset: kill $MN_CONTAINERS"
		fi

		_debug "reset: iptables"
		iptables -P INPUT ACCEPT
		iptables -P FORWARD ACCEPT
		iptables -P OUTPUT ACCEPT
		iptables -t nat -F
		iptables -t mangle -F
		iptables -F
		iptables -X

		_debug "reset: sysctl"
		@silent sysctl -w net.ipv4.ip_forward=0

	) || true
}

# generates /etc/hosts contents for a given host
function rl_cfg_gen_etc_hosts {
	local NAME="$1"; shift
	local HOSTS_EXTRA=""
	for host_line in "$@"; do
		HOSTS_EXTRA+="$host_line"$'\n'
	done
	cat <<- EOF
	127.0.0.1   localhost ${NAME}
	${HOSTS_EXTRA}
	# The following lines are desirable for IPv6 capable hosts
	::1     ip6-localhost ip6-loopback
	fe00::0 ip6-localnet
	ff00::0 ip6-mcastprefix
	ff02::1 ip6-allnodes
	ff02::2 ip6-allrouters
	EOF
}

# Flushes the IP addresses on all host / container interfaces
function rl_cfg_flush_ip() {
	local CTNAME IFNAME
	_debug "cfg: flush IPs..."
	for key in "${!RL_CFG_IPS[@]}"; do
		CTNAME="${key%%/*}"  # extract left-side of '/' (delete the other)
		IFNAME="${key##*/}"  # right side of '/'
		rl_ctexec "$CTNAME" ip addr flush dev "$IFNAME"
	done
}

# Configures the IP addresses on the requested containers.
# Syntax: rl_cfg_set_ipv4 [CONTAINERS...]
# Where CONTAINERS is an optional list of containers to set IP addresses to.
# If empty, all containers will be setup.
function rl_cfg_set_ipv4() {
	local CTNAME IFNAME
	_debug "cfg: set IPv4..."
	for key in "${!RL_CFG_IPS[@]}"; do
		CTNAME="${key%%/*}"; IFNAME="${key##*/}"
		# filter by hostname or cfg key (containing interface name)
		if [[ -z "$*" || ( " $* " =~ " $CTNAME " ) || (" $* " =~ " $key ") ]]; then
			rl_ctexec "$CTNAME" ip addr add "${RL_CFG_IPS["$key"]}" dev "$IFNAME"
		fi
	done
}

# Returns the IP address of the requested container/interface.
function rl_cfg_get_ipv4() {
	local key="$1/$2"
	local IP="${RL_CFG_IPS["$key"]}"
	if [[ -z "$IP" ]]; then
		echo "No IPv4 set for $key!">&2
		return 1
	fi
	# remove mask from the IP definition
	IP="${IP%%/*}"
	echo -n "$IP"
}

# Sets all host/container interfaces to up/down (first argument).
function rl_cfg_set_ifstate() {
	local CTNAME IFNAME
	local IFSTATE="$1"
	_debug "cfg: set if state $IFSTATE..."
	for key in "${!RL_CFG_IPS[@]}"; do
		CTNAME="${key%%/*}"; IFNAME="${key##*/}"
		rl_ctexec "$CTNAME" ip link set "$IFSTATE" dev "$IFNAME"
	done
}

# Sets up /etc/hosts for all declared containers ($RL_CFG_CONTAINERS).
# Requires the following network interface name conventions: 
# 'veth-$ct' on host, '$ct-eth0' on the container
# Alternatively, set the RL_CFG_CT_DEFAULT_ROUTE variable for the containers.
function rl_cfg_set_hosts() {
	local -a HOST_HOSTS=()
	_debug "cfg: set /etc/hosts..."
	for ct in "${RL_CFG_CONTAINERS[@]}"; do
		local -a CT_HOSTS=()
		if [[ -n "$RL_CFG_CT_DEFAULT_ROUTE" ]]; then
			CT_HOSTS+=("${RL_CFG_CT_DEFAULT_ROUTE} host")
		else
			CT_HOSTS+=("$(rl_cfg_get_ipv4 "host" "veth-$ct") host")
		fi
		for other in "${RL_CFG_CONTAINERS[@]}"; do
			if [[ "$ct" == "$other" ]]; then continue; fi
			CT_HOSTS+=("$(rl_cfg_get_ipv4 "$other" "$other-eth0") $other")
		done
		HOST_HOSTS+=("$(rl_cfg_get_ipv4 "$ct" "$ct-eth0") $ct")
		rl_cfg_gen_etc_hosts "$ct" "${CT_HOSTS[@]}" | \
			rl_ctexec -i "$ct" cp /dev/stdin /etc/hosts
	done
	rl_cfg_gen_etc_hosts "host" "${HOST_HOSTS[@]}" | \
		rl_ctexec -i "host" cp /dev/stdin /etc/hosts
}

# Setups default routes for all declared containers ($RL_CFG_CONTAINERS).
function rl_cfg_set_ct_routes() {
	_debug "cfg: set default gateways..."
	for ct in "${RL_CFG_CONTAINERS[@]}"; do
		local DEFAULT_GW=
		if [[ -n "$RL_CFG_CT_DEFAULT_ROUTE" ]]; then
			DEFAULT_GW="${RL_CFG_CT_DEFAULT_ROUTE}"
		else
			DEFAULT_GW="$(rl_cfg_get_ipv4 "host" "veth-$ct")"
		fi
		rl_ctexec "$ct" ip route add default via "$DEFAULT_GW"
	done
}

function rl_cfg_set_ip_forward() {
	@silent sysctl -w net.ipv4.ip_forward=1
}

function rl_cfg_set_masquerade() {
	_debug "cfg: iptables: add MASQUERADE"
	@silent iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE || true
	iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
}

# Sets up DNS resolver for the declared containers ($RL_CFG_CONTAINERS).
# Takes the DNS target from $RL_CFG_DNS.
function rl_cfg_set_ct_resolv() {
	_debug "cfg: set DNS: $RL_CFG_DNS"
	for ct in "${RL_CFG_CONTAINERS[@]}"; do
		rl_ctexec --shell "$ct" "echo nameserver \"$RL_CFG_DNS\" >/etc/resolv.conf"
	done
}

function rl_cfg_internet_connectivity() {
	rl_cfg_set_ct_routes
	rl_cfg_set_ct_resolv
	rl_cfg_set_ip_forward
	rl_cfg_set_masquerade
	_debug "cfg: Internet connectivity was setup!"
}

## SSH key management routines

# Safety routine for doing an initial backup of host's authorized_keys (as
# provisioned by cloud-init)
function rl_ssh_host_backup_authkeys() {
	if [[ ! -f "$RL_LAB_CONFIG_DIR/authorized_keys_backup" ]]; then
		mkdir -p "$RL_LAB_CONFIG_DIR"
		cp -f "/home/student/.ssh/authorized_keys" "$RL_LAB_CONFIG_DIR/authorized_keys_backup"
	fi
}

# Ensures that the VM's authorized_keys have the original provisioned keys
# + correct permissions / ownership
function rl_ssh_host_check_fix_authkeys() {
	local AUTHKEYS="/home/student/.ssh/authorized_keys"
	if [[ ! -f "$RL_LAB_CONFIG_DIR/authorized_keys_backup" ]]; then
		echo "CRITICAL BUG: Original authorized_keys were not backed up!" >&2
		exit 1
	fi
	while read -r pubkey; do
		rl_ssh_ct_authorize_key "host" "student" "$pubkey"
	done < "$RL_LAB_CONFIG_DIR/authorized_keys_backup"
}

# Appends a public key to the requested container / user account's authorized_keys file
# Syntax: rl_ssh_ct_authorize_key CONTAINER_NAME USER PUBKEY
# Also allows manging host's keys (use 'host' as CONTAINER_NAME).
function rl_ssh_ct_authorize_key() {
	local CT="$1" CTUSER="$2" PUBKEY="$3"
	local CTHOME="/home/$CTUSER"
	if [[ "$CTUSER" == "root" ]]; then
		CTHOME="/$CTUSER"
	fi
	rl_ctexec --shell "$CT" - <<-ENDBASHSCRIPT
	PUBKEY=${PUBKEY@Q}
	# note: run those as root because of possibly bad permissions
	mkdir -p "$CTHOME/.ssh"
	[[ -f "$CTHOME/.ssh/authorized_keys" ]] || \\
		touch "$CTHOME/.ssh/authorized_keys"
	chown "$CTUSER:$CTUSER" "$CTHOME/.ssh" -R
	chmod 700 "$CTHOME/.ssh" -R
	if ! grep -Fxq "\$PUBKEY" "$CTHOME/.ssh/authorized_keys"; then
		echo "\$PUBKEY" | su "$CTUSER" -c 'cat >> $CTHOME/.ssh/authorized_keys'
	fi
	ENDBASHSCRIPT
}

# Generates a SSH keypair (as 'id_rsa') for the requested host and user.
# Syntax: rl_ssh_ct_gen_keys CONTAINER USER
# Also accepts the 'host' name (like the `authorize_key` function above)
function rl_ssh_ct_gen_keys() {
	local CT="$1" CTUSER="$2"
	local CTHOME="/home/$CTUSER"
	if [[ "$CTUSER" == "root" ]]; then
		CTHOME="/$CTUSER"
	fi
	rl_ctexec --shell "$CT" - <<-ENDBASHSCRIPT
	mkdir -p "$CTHOME/.ssh"
	# fix ssh permissions
	chown "$CTUSER:$CTUSER" "$CTHOME/.ssh" -R
	chmod 700 "$CTHOME/.ssh" -R
	[[ -f "$CTHOME/.ssh/id_rsa" ]] || \\
		su "$CTUSER" -c 'ssh-keygen -q -t rsa -N "" -f "$CTHOME/.ssh/id_rsa"'
	ENDBASHSCRIPT
}

# Returns the default public key of a container / user pair.
# Syntax: rl_ssh_ct_get_pubkey CONTAINER USER
function rl_ssh_ct_get_pubkey() {
	local CT="$1" CTUSER="$2"
	local CTHOME="/home/$CTUSER"
	if [[ "$CTUSER" == "root" ]]; then
		CTHOME="/$CTUSER"
	fi
	rl_ctexec --shell "$CT" - <<-ENDBASHSCRIPT
	if [[ ! -f "$CTHOME/.ssh/id_rsa.pub" ]]; then
		echo "$CT: No public key exists for '$CTUSER'" >&2
		exit 1
	fi
	cat "$CTHOME/.ssh/id_rsa.pub"
	ENDBASHSCRIPT
}

# Provisions SSH keys for host + all containers (both 'root' and 'student' users)
# TODO: implement arguments for restricting containers / users
function rl_ssh_provision_keys() {
	local -a ALL_KEYS=()
	{
		rl_ssh_host_backup_authkeys
		rl_ssh_ct_gen_keys host student
		rl_ssh_ct_gen_keys host root
		ALL_KEYS+=("$(rl_ssh_ct_get_pubkey host student)")
		ALL_KEYS+=("$(rl_ssh_ct_get_pubkey host root)")
		for ct in "${RL_CFG_CONTAINERS[@]}"; do
			rl_ssh_ct_gen_keys "$ct" student
			rl_ssh_ct_gen_keys "$ct" root
			ALL_KEYS+=("$(rl_ssh_ct_get_pubkey "$ct" student)")
			ALL_KEYS+=("$(rl_ssh_ct_get_pubkey "$ct" root)")
		done

		for pubkey in "${ALL_KEYS[@]}"; do
			rl_ssh_ct_authorize_key host student "$pubkey"
			rl_ssh_ct_authorize_key host root "$pubkey"
			for ct in "${RL_CFG_CONTAINERS[@]}"; do
				rl_ssh_ct_authorize_key "$ct" student "$pubkey"
				rl_ssh_ct_authorize_key "$ct" root "$pubkey"
			done
		done
		rl_ssh_host_check_fix_authkeys
	} || {
		# restore ssh keys on failure
		rl_ssh_host_check_fix_authkeys
		return 1
	}
}

