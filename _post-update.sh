#!/bin/bash
# RL Labs post-update hook

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

BUILD_MODULES=(base lab-ip lab-iptables lab-nat lab-clients lab-mitm)
for module in "${BUILD_MODULES[@]}"; do
	# build docker images
	cd "$RL_SCRIPTS_SRC/$module/"
	./build.sh
done

