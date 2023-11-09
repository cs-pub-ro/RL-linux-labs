#!/bin/bash
# Lab 7 prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

# all configurable containers
declare -a RL_CFG_CONTAINERS=(red green blue)
# bash array with container/interface IPs
declare -A RL_CFG_IPS=(
	['host/veth-red']="192.168.1.1/24"
	['host/veth-green']="192.168.2.1/24"
	['host/veth-blue']="192.168.3.1/24"
	['red/red-eth0']="192.168.1.2/24"
	['green/green-eth0']="192.168.2.2/24"
	['blue/blue-eth0']="192.168.3.2/24"
)
RL_CFG_DNS="8.8.8.8"

# Resets to the initial lab configuration state
function lab_setup_reset() {
	rl_stop_topology
	rl_docker_setup_nobridge
	rl_cfg_cleanall
	rl_start_topology "$LAB_SRC/topology.py"

	rl_cfg_flush_ip
	rl_cfg_set_ifstate down
	rl_cfg_set_hosts
	# don't setup DNS / IP addresses
}

function lab_setup_ex6() {
	RL_CFG_IPS["host/veth-red"]="7.7.7.1"
	RL_CFG_IPS["red/red-eth0"]="7.7.7.2/24"
	rl_cfg_set_ipv4
	rl_cfg_set_ifstate up
	rl_cfg_set_ip_forward
	rl_cfg_set_ct_routes
}

function lab_setup_ex7() {
	# let's spice this up a bit ;)
	RL_CFG_IPS["host/veth-blue"]="15.15.15.0"
	RL_CFG_IPS["blue/blue-eth0"]="15.15.15.2"
	rl_cfg_set_ipv4
	rl_cfg_set_ifstate up
	rl_cfg_set_ip_forward
	@silent rl_cfg_set_ct_routes || true
	# muwhaahahaa :P
	rl_ctexec "blue" ip li set down dev blue-eth0
}

# special lab flags for persistence across reboots
if [[ "$EX" == "--persist-boot" ]]; then
	rl_stop_topology
	# no cleanups, just re-start the [persistent] topology
	rl_start_topology --exec "$LAB_SRC/topology.py" --persist
	exit 0
fi


if [[ -z "$EX" || "$EX" == "ex1" ]]; then
	lab_setup_reset

elif [[ "$EX" == "ex6" ]]; then
	lab_setup_reset
	lab_setup_ex6

elif [[ "$EX" == "ex7" ]]; then
	lab_setup_reset
	lab_setup_ex7

elif [[ "$EX" == "ex9" ]]; then
	rl_stop_topology
	rl_docker_setup_nobridge
	rl_cfg_cleanall
	rl_install_persist_topo "lab-ip"
	systemctl restart rl-topology
else
	echo "ERROR: invalid lab argument: '$EX'" >&2
	exit 1
fi

