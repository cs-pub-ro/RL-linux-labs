#!/bin/bash
# Runs at container boot time

# import container's environment variables from systemd
. <(xargs -0 bash -c 'printf "export %q\n" "$@"' -- < /proc/1/environ)

# save RL_PS1_FORMAT to profile
printf "RL_PS1_FORMAT=\"%s\"\n" "$RL_PS1_FORMAT" > /etc/profile.d/rl.sh

sysctl -w net.ipv6.conf.all.disable_ipv6=0

# append current hostname to /etc/hosts
HOSTS_CONFIG=$(sed -e 's/^127\.0\.0\.1\s.*/127.0.0.1 localhost '$(hostname)'/' /etc/hosts)
if [[ -n "$HOSTS_CONFIG" ]]; then echo -n "$HOSTS_CONFIG" >/etc/hosts; fi

# workaround: wait for interface to appear
if [[ -n "$NET_WAIT_ONLINE_IFACE" ]]; then
	sed -i -E -e 's/^#?WAIT_ONLINE_IFACE=.*/WAIT_ONLINE_IFACE='$NET_WAIT_ONLINE_IFACE'/' /etc/default/networking
	wait_s=10
	IFACE_PATH="/sys/class/net/$NET_WAIT_ONLINE_IFACE"
	until [[ -e "$IFACE_PATH" ]]; do
		sleep 1
		[[ "$((wait_s--))" -gt 0 ]] || break
	done
	ls -l "$IFACE_PATH"
fi

