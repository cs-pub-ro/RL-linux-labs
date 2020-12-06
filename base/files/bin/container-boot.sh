#!/bin/bash
# Runs at container boot time

# import container's environment variables from systemd
. <(xargs -0 bash -c 'printf "export %q\n" "$@"' -- < /proc/1/environ)

# save RL_PS1_FORMAT to profile
printf "RL_PS1_FORMAT=\"%s\"\n" "$RL_PS1_FORMAT" > /etc/profile.d/rl.sh

sysctl -w net.ipv6.conf.all.disable_ipv6=0

