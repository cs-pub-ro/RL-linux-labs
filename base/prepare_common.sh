#!/bin/bash
# Common lab prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit 1
fi

. "$SRC/utils/functions.sh"

# utility functions
function _debug() {
	if [[ -n "$DEBUG" ]]; then echo "$@"; fi
}
function @silent() {
	if [[ -z "$DEBUG" ]]; then
		"$@" &>/dev/null
	else
		"$@"
	fi
}

# disables docker networking autoconfiguration features altogether
function lab_dockerNoBridge() {
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
		systemctl disable --now docker.socket
		systemctl enable docker.service
	fi
}

function lab_runTopology() {
	local LOG="/tmp/.containernet-stdout"
	local GUARD_FILE="/tmp/.containernet-init"
	local SCRIPT_PID=$$
	rm -f "$LOG" "$GUARD_FILE"
	(
		PYTHONPATH="$SRC/base/python/" nohup \
			python3 "$@" &>"$LOG"
	)&
	(
		touch "$LOG"
		tail -q -f --pid "$SCRIPT_PID" "$LOG"
	)&
	local TAIL_PID=$!
	# wait for the topology to init
	echo "Wait for containernet to start..."
	local SLEEP_DELAYS=(2 3 4 6 8 10 10 10 10 10 10)  # times out after this
	local I=0
	while [[ ! -f "$GUARD_FILE" ]]; do
		if [[ -z "${SLEEP_DELAYS[$I]}" ]]; then echo "FATAL: Operation timed out!"; return 1; fi
		sleep "${SLEEP_DELAYS[$I]}"
		I="$(( "$I" + 1 ))"
		echo "Still waiting..."
	done
	lab_applyMTU
	echo "Containernet successfully started!"
}

function lab_applyMTU() {
	@silent ip link set mtu 1450 dev veth-red
	@silent ip link set mtu 1450 dev veth-green
	@silent ip link set mtu 1450 dev veth-blue
	for ct in red green blue; do
		docker exec "mn.$ct" /bin/bash -c "ip link set mtu 1450 dev $ct-eth0"
	done
}

function check_container() {
	[ "$( docker container inspect -f '{{.State.Running}}' "$1" 2>/dev/null )" == "true" ]
}

function lab_cleanall() {
	(
		set +e  # ignore errors
		stop_lab  # make sure the topology is stopped
		systemctl stop docker

		_debug "Clean IPv4 config"
		@silent ip add flush dev veth-red
		@silent ip add flush dev veth-green
		@silent ip add flush dev veth-blue

		_debug "Enable host-container links"
		@silent ip link set dev veth-red up
		@silent ip link set dev vff0000 up
		@silent ip link set dev veth-green up
		@silent ip link set dev v00ff00 up
		@silent ip link set dev veth-blue up
		@silent ip link set dev v0000ff up

		_debug "Reset iptables"
		iptables -P INPUT ACCEPT
		iptables -P FORWARD ACCEPT
		iptables -P OUTPUT ACCEPT
		iptables -t nat -F
		iptables -t mangle -F
		iptables -F
		iptables -X

		_debug "Reset sysctl"
		sysctl -w net.ipv4.ip_forward=0
		systemctl start docker

	) || true
}

# generates /etc/hosts contents for a given host, optionally with extra lines
function lab_gen_etc_hosts() {
	local HOST_SELF="$1"; shift
	local HOSTS_EXTRA=""
	for host_line in "$@"; do
		HOSTS_EXTRA+="$host_line"$'\n'
	done
	cat <<- EOF
	127.0.0.1   localhost ${HOST_SELF}
	${HOSTS_EXTRA}
	# The following lines are desirable for IPv6 capable hosts
	::1     ip6-localhost ip6-loopback
	fe00::0 ip6-localnet
	ff00::0 ip6-mcastprefix
	ff02::1 ip6-allnodes
	ff02::2 ip6-allrouters
	EOF
}

