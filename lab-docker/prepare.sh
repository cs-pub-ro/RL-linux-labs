#!/bin/bash

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

# remove Docker's NO IP overrides (used for containernet only)
cat << EOF > /etc/docker/daemon.json
{
  "mtu": 1450,
  "features": {"buildkit": true},
  "default-address-pools": [
    { "base": "10.226.0.0/12", "size": 24 }
  ]
}
EOF
systemctl restart docker

