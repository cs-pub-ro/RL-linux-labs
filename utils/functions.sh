#!/bin/bash
# Bash utility functions (& aliases) for the RL Lab VM.
# Automatically loaded inside the student's shell.

RL_LABS_HOME=${RL_LABS_HOME:-/opt/rl-labs}

function rl_smoke() {
	if [ -d "${RL_LABS_HOME}/smoke-test" ]; then
		sudo "${RL_LABS_HOME}/smoke-test/run.sh" add
		sudo "${RL_LABS_HOME}/smoke-test/run.sh" clean
	fi
}

function rl_go() {
	if [ -n "$(docker container ls -q --filter name="mn.$1")" ]; then
		docker exec --user student -it mn.$1 /bin/bash -c "cd && exec /bin/bash" 
	else
		"Container '$1' is not running!" >&2
		return 1
	fi
}

function rl_start_lab() {
	if [[ -f "${RL_LABS_HOME}/.update-required" ]]; then
		echo "Please run 'update_lab' first!" >&2
		return 1
	fi
	sudo "${RL_LABS_HOME}/prepare.sh" "$@"
}

function rl_stop_lab() {
	sudo "${RL_LABS_HOME}/prepare.sh" --stop
}

function rl_update_lab() {
	sudo "${RL_LABS_HOME}/update.sh" "$@"
}

if [[ $- == *i* ]]; then
	# aliases (only for interactive shells)
	function go() { rl_go "$@"; }
	function start_lab() { rl_start_lab "$@"; }
	function stop_lab() { rl_stop_lab "$@"; }
	function restart_lab() { rl_restart_lab "$@"; }
	function update_lab() { rl_update_lab "$@"; }
fi

