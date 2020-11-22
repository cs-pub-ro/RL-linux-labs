#!/bin/bash
# Common lab prepare script

if [[ "$_RL_INTERNAL" != "rlrullz" ]]; then
	echo "ERROR: This script is not runnable!" >&2
	exit
fi

. "$SRC/utils/functions.sh"

# utility functions
function _debug() {
	if [[ -n "$DEBUG" ]]; then echo "$@"; fi
}
function @silent() {
	if [[ -z "$DEBUG" ]]; then
		"$@" &>/dev/null
	else
		"$@"
	fi
}

function lab_runTopology() {
	local PIPE="/tmp/.containernet-stdin"
	local LOG="/tmp/.containernet-stdout"
	rm -f "$PIPE" "$LOG"
	# mkfifo "$PIPE"
	# nohup python3 "$@" >"$LOG" 2>&1 <"$PIPE" &
	nohup python3 "$@" &>"$LOG" &
	tail -F "$LOG" &
}

function check_container() {
	[ "$( docker container inspect -f '{{.State.Running}}' "$1" 2>/dev/null )" == "true" ]
}

function lab_cleanall() {
	(
		set +e  # ignore errors
		stop_lab  # make sure the topology is stopped

		_debug "Clean ip_forward"
		sysctl -w net.ipv4.ip_forward=0

		_debug "Clean IPv4 config"
		@silent ip add flush dev veth-red
		@silent ip add flush dev veth-green
		@silent ip add flush dev veth-blue

		_debug "Enable host-container links"
		@silent ip link set dev veth-red up
		@silent ip link set dev vff0000 up
		@silent ip link set dev veth-green up
		@silent ip link set dev v00ff00 up
		@silent ip link set dev veth-blue up
		@silent ip link set dev v0000ff up
	) || true
}

