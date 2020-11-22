#!/bin/bash
# Common lab prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

lab_cleanall

echo "Starting ContainerNet..."
lab_runTopology "$LAB_SRC/topology.py"

