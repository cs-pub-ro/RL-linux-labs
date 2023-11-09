#!/bin/bash
# Lab 9 prepare script

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
	rl_cfg_set_ipv4
	rl_cfg_set_ifstate up
	rl_cfg_set_hosts
	rl_cfg_set_ct_routes
	rl_cfg_set_ct_resolv
	rl_cfg_set_ip_forward
	rl_ssh_provision_keys --users student,host
}

if [[ -z "$EX" || "$EX" == "ex1" ]]; then
	lab_setup_reset

else
	echo "ERROR: invalid lab argument: '$EX'" >&2
	exit 1
fi

