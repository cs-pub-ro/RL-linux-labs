#!/bin/bash
# Lab 11 prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

# all configurable containers
declare -a RL_CFG_CONTAINERS=(red green blue)
# bash array with container/interface IPs
declare -A RL_CFG_IPS=(
	['host/mitm-bridge']="192.168.0.100/22"
	['red/red-eth0']="192.168.1.2/22"
	['green/green-eth0']="192.168.2.2/22"
	['blue/blue-eth0']="192.168.3.2/22"
)
RL_CFG_CT_DEFAULT_ROUTE="192.168.0.100"
RL_CFG_DNS="8.8.8.8"


function lab_prepare_mitm(){
	# local network topology
	ip link add name mitm-bridge type bridge || true
	ip link set mitm-bridge up	
}

function lab_setup_mitm() {
	ip link set veth-red master mitm-bridge
	ip link set veth-green master mitm-bridge
	ip link set veth-blue master mitm-bridge
}


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
	rl_cfg_internet_connectivity
	rl_ssh_provision_keys --users student,host
}

lab_prepare_mitm
lab_setup_reset
lab_setup_mitm

if [[ -z "$EX" || "$EX" == "ex1" ]]; then
	true

elif [[ "$EX" == "ex12" ]]; then
	true

else
	echo "ERROR: invalid lab argument: '$EX'" >&2
	exit 1
fi
