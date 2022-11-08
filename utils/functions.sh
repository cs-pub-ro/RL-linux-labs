#!/bin/bash
# Bash utility functions for rl-labs

RL_LABS_HOME=${RL_LABS_HOME:-/opt/rl-labs}

function smoke() {
	if [ -d "${RL_LABS_HOME}/smoke-test" ]; then
		sudo "${RL_LABS_HOME}/smoke-test/run.sh" add
		sudo "${RL_LABS_HOME}/smoke-test/run.sh" clean
	fi
}

function go() {
	#[ "$(docker ps | grep $1 )" ]  && docker exec -it mn.$1 /bin/bash -c "cd && /bin/bash" 
	[ "$(docker ps | grep $1 )" ]  && docker exec --user student -it mn.$1 /bin/bash -c "cd && exec /bin/bash" 
}

function rr() {
	echo "We don't do that here!" ; exit 1
	# [ "$(docker ps | grep $1 )" ]  && docker restart mn.$1  
	#Danger: Container will be disconnected from controller and network
	#todo: check if there is any way to reconnect to controller and ovs
}

function start_lab() {
	if [[ -f "${RL_LABS_HOME}/.update-required" ]]; then
		echo "Please run 'update_lab' first!" >&2
		return 1
	fi
	sudo "${RL_LABS_HOME}/prepare.sh" "$@"
}

function force_stop_lab() {
	sudo mn -c -v output
}

function stop_lab() {
	# todo: maybe a for loop?
	kill %$(jobs | grep -i topology.py | cut -c2) &>/dev/null || true
	force_stop_lab 
}

function update_lab() {
	sudo "${RL_LABS_HOME}/update.sh" "$@"
}

