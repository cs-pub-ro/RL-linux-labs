#!/bin/bash

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

# remove Docker's NO IP overrides (used for containernet only)
cat << EOF > /etc/docker/daemon.json
{
  "features": {"buildkit": true}
}
EOF
systemctl restart docker

