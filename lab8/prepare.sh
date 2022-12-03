#!/bin/bash
# Lab 8 prepare script

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

function lab_create_users() {
	@silent echo "Creating user ana on host"
	# create user ana on host
	@silent userdel -r ana &>/dev/null || true  
	useradd -m -d /home/ana -s /bin/bash -l ana
	echo "ana:student" | chpasswd
	mkdir -p /home/ana/.ssh

	chown -R ana:ana /home/ana/.ssh/
	# (note: this debugging exercise has been deleted :(( ;
	#  but it can be used for ex 12 demo, for extra debugging)
	# chmod 777 /home/ana/.ssh/ 

	@silent echo "Creating users bogdan + corina on blue"
	rl_ctexec --shell blue - <<-ENDBASHSCRIPT
	# userdel -r bogdan > /dev/null 2>&1
	useradd -m -d /home/bogdan -s /bin/bash -l bogdan
	echo 'bogdan:student' | chpasswd
	su - bogdan -c 'mkdir ~/.ssh'
	[[ -f "/home/bogdan/.ssh/id_rsa" ]] || \\
		su - bogdan -c 'ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa'
	# userdel -r corina > /dev/null 2>&1"
	useradd -m -d /home/corina -s /bin/bash -l corina
	echo 'corina:student' | chpasswd
	ENDBASHSCRIPT
}

function lab_create_artifacts(){
	# Create large file in student@green'.
	rl_ctexec --shell green - <<-ENDBASHSCRIPT
	dd if=/dev/urandom of=/home/student/file-100M.dat bs=1M count=100 > /dev/null 2>&1
	chown student:student ~student/file-100M.dat > /dev/null 2>&1
	ENDBASHSCRIPT

	# Create 10M files in student@host
	dd if=/dev/urandom of=/home/student/host-file-10M.dat bs=1M count=10 > /dev/null 2>&1
	chown student:student /home/student/host-file-10M.dat
	# Create 10M files in corina@blue
	rl_ctexec --shell blue - <<-ENDBASHSCRIPT
	dd if=/dev/urandom of=/home/corina/blue-file-10M.dat bs=1M count=10 > /dev/null 2>&1
	chown corina:corina ~corina/blue-file-10M.dat
	ENDBASHSCRIPT

	# Create folders in student@host.
	rm -fr /home/student/assignment
	mkdir /home/student/assignment
	echo "x - 1 = 0" > /home/student/assignment/linear.txt
	echo "x^2 - 3x + 2 = 0" > /home/student/assignment/quadratic.txt
	echo "x^3 - 6x^2 + 11x -6 = 0" > /home/student/assignment/cubic.txt
	chown -R student:student /home/student/assignment
	# Create folders in corina@blue.
	rl_ctexec --shell blue - <<-ENDBASHSCRIPT
	rm -rf /home/corina/solution
	mkdir -p /home/corina/solution
	echo "x = 1" > /home/corina/solution/linear.txt
	echo "x1 = 1, x2 = 2" > /home/corina/solution/quadratic.txt
	echo "x1 = 1, x2 = 2, x3 = 3" > /home/corina/solution/cubic.txt
	chown -R corina:corina ~corina/solution
	ENDBASHSCRIPT

	# Ana proiecte
	rm -fr /home/ana/proiecte
	mkdir /home/ana/proiecte
	echo "ana" > /home/ana/proiecte/ana.txt
	echo "are" > /home/ana/proiecte/are.txt
	echo "mere" > /home/ana/proiecte/mere.txt
	chown -R ana:ana /home/ana/proiecte
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

if [[ -z "$EX" || "$EX" == "ex1" ]]; then
	lab_setup_reset
	lab_create_users
	lab_create_artifacts

else
	echo "ERROR: invalid lab argument: '$EX'" >&2
	exit 1
fi

