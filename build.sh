#!/bin/bash
# RL Labs build script

export RL_SCRIPTS_SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
set -e
if [ "$EUID" -ne 0 ]; then
	echo "ERROR: This script must be run as root!" >&2
	exit
fi

# run post-update hooks
(
	_RL_INTERNAL="rlrullz"
	export RL_SCRIPTS_SRC
	. "$RL_SCRIPTS_SRC/_post-update.sh"
)

echo "Lab scripts successfully built!"

