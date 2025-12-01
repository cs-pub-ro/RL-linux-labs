#!/bin/bash
# Runs at container boot time

# export container's environment variables to file
xargs -0 bash -c 'printf "%q\n" "$@"' -- < /proc/1/environ | \
	grep -Ev '^(PATH|DEBIAN_FRONTEND|HOME)=' > /etc/environment
# import those environment variables
set -a
source /etc/environment
set +a

# save RL_PS1_FORMAT to profile
printf "RL_PS1_FORMAT=\"%s\"\n" "$RL_PS1_FORMAT" > /etc/profile.d/rl.sh

sysctl -w net.ipv6.conf.all.disable_ipv6=0

# append current hostname to /etc/hosts
HOSTS_CONFIG=$(sed -e 's/^127\.0\.0\.1\s.*/127.0.0.1 localhost '"$(hostname)"'/' /etc/hosts)
if [[ -n "$HOSTS_CONFIG" ]]; then echo -n "$HOSTS_CONFIG" >/etc/hosts; fi

# workaround: wait for interface to appear
NET_WAIT_TIMEOUT=${NET_WAIT_TIMEOUT:-15}
NET_WAIT_EXTRA_DELAY=${NET_WAIT_EXTRA_DELAY:-4}
if [[ -n "$NET_WAIT_ONLINE_IFACE" ]]; then
	sed -i -E -e 's/^#?WAIT_ONLINE_IFACE=.*/WAIT_ONLINE_IFACE='"$NET_WAIT_ONLINE_IFACE"'/' /etc/default/networking
	wait_s=$NET_WAIT_TIMEOUT
	while : ; do
		ALL_OK=1
		for iface in $NET_WAIT_ONLINE_IFACE; do
			if [[ ! -e "/sys/class/net/$iface" && "$(cat "/sys/class/net/$iface/operstate")" != "up" ]]; then
				ALL_OK=
			fi
		done
		if [[ -n "$ALL_OK" ]]; then break; fi
		sleep 1
		[[ "$((wait_s--))" -gt 0 ]] || break
	done
	[[ -n "$ALL_OK" ]] || echo "Timed out while waiting for interfaces: $NET_WAIT_ONLINE_IFACE!" >&2
	sleep "$NET_WAIT_EXTRA_DELAY"
fi

