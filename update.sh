#!/bin/bash
# RL Labs update script

export RL_SCRIPTS_SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

set -e
if [ "$EUID" -ne 0 ]; then
	echo "ERROR: This script must be run as root!" >&2
	exit
fi

(
	cd "$RL_SCRIPTS_SRC"
	remote=update
	remote_branch=update/master

	echo "Fetching from $remote..."
	git fetch $remote

	if git merge-base --is-ancestor $remote_branch HEAD; then
		echo 'Already up-to-date'
		exit 0
	fi

	if [[ "$1" == "--force" ]]; then
		git reset --hard
	fi
	if git merge-base --is-ancestor HEAD $remote_branch; then
		echo 'Fast-forward possible. Merging...'
		git merge --ff-only --stat $remote_branch
	else
		echo 'Fast-forward not possible. Rebasing...'
		git rebase --preserve-merges --stat $remote_branch
	fi
)

# run post-update hook
(
	_RL_INTERNAL="rlrullz"
	export RL_SCRIPTS_SRC
	. "$RL_SCRIPTS_SRC/_post-update.sh"
)

rm -f "${RL_SCRIPTS_SRC}/.update-required"

echo "Lab scripts updated successfully!"

