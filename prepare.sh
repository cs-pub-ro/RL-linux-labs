#!/bin/bash
# RL Labs prepare script

set -e
export RL_SCRIPTS_SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
_RL_INTERNAL="rlrullz"

function _help() {
	echo "Syntax: $0 LAB [EXERCISE]" >&2
	echo "  > LAB: 'lab<X>', prefix required! e.g. lab7" >&2
	echo "  > EXERCISE: 'ex<Y>', prefix required! e.g. ex1" >&2
	exit 1
}

if [ "$EUID" -ne 0 ]; then
	echo "ERROR: This script must be run as root!" >&2
	exit
fi

# load the common prepare routines
. "$RL_SCRIPTS_SRC/base/prepare_common.sh"

LAB=$1
if [[ -z "$LAB" ]]; then _help; fi 

if [[ "$LAB" == "--force-clean" ]]; then
	systemctl -q stop rl-topology || true
	rl_stop_topology
	rl_cfg_cleanall
	exit 0
fi

LAB_SRC="$RL_SCRIPTS_SRC/$LAB"
if [[ ! -f "$LAB_SRC/prepare.sh" ]]; then
	echo "Invalid argument: $LAB" >&2
	exit 2
fi
EX=$2

_RL_INTERNAL="rlrullz"  # we are legit, baby

# then run the lab's prepare script
. "$RL_SCRIPTS_SRC/$LAB/prepare.sh"

