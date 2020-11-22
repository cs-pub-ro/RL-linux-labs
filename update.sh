#!/bin/bash
# RL Labs update script

export SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

set -e
if [ "$EUID" -ne 0 ]; then
	echo "ERROR: This script must be run as root!" >&2
	exit
fi

(
	cd "$SRC"
	remote=update
	remote_branch=update/master

	echo "Fetching from $remote..."
	git fetch $remote

	if git merge-base --is-ancestor $remote_branch HEAD; then
		echo 'Already up-to-date'
		exit 0
	fi

	if git merge-base --is-ancestor HEAD $remote_branch; then
		echo 'Fast-forward possible. Merging...'
		git merge --ff-only --stat $remote_branch
	else
		echo 'Fast-forward not possible. Rebasing...'
		if [[ "$1" == "--force" ]]; then
			git reset --hard
		fi
		git rebase --preserve-merges --stat $remote_branch
	fi
)

# run post-update hook
(
	_RL_INTERNAL="rlrullz"
	export SRC
	. "$SRC/_post-update.sh"
)

echo "Lab scripts updated successfully!"

