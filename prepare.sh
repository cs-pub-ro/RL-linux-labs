#!/bin/bash
# RL Labs prepare script

set -e
export SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
_RL_INTERNAL="rlrullz"

function _help() {
	echo "Syntax: $0 LAB_NAME [EXERCISE]"
	exit 1
}

if [ "$EUID" -ne 0 ]; then
	echo "ERROR: This script must be run as root!" >&2
	exit
fi

LABS_AVAILABLE=(lab7)

LAB=$1
if [[ -z "$LAB" ]]; then _help; fi 

LAB_SRC="$SRC/$LAB"
if [[ ! -f "$LAB_SRC/prepare.sh" ]]; then
	echo "Invalid lab specified: $LAB" >&2
	exit 2
fi
EX=$2

_RL_INTERNAL="rlrullz"  # we are legit, baby

# first, run/load the common prepare routines
. "$SRC/base/prepare_common.sh"
# then run the lab's prepare script
. "$SRC/$LAB/prepare.sh"

