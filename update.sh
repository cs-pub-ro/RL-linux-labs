#!/bin/bash
# RL Labs update script

export RL_SCRIPTS_SRC="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

set -e
if [ "$EUID" -ne 0 ]; then
	echo "ERROR: This script must be run as root!" >&2
	exit
fi

DO_FETCH=1
FORCE=
BRANCH=master
while [[ $# -gt 0 ]]; do
	case "$1" in
		--no-fetch)
			DO_FETCH=0 ;;
		--force)
			FORCE=1 ;;
		--branch)
			BRANCH="$2"; shift ;;
		*)
			echo "Invalid argument: $1" >&2
			exit 1 ;;
	esac
	shift
done

if [[ "$DO_FETCH" == "1" ]]; then
(
	cd "$RL_SCRIPTS_SRC"
	remote=update
	remote_branch=update/$BRANCH

	echo "Fetching from $remote..."
	git fetch "$remote"

	if git merge-base --is-ancestor $remote_branch HEAD; then
		echo 'Already up-to-date'
		exit 0
	fi

	if [[ "$FORCE" == "1" ]]; then
		git reset --hard
	fi
	if [[ "$(git rev-parse --abbrev-ref HEAD)" != "$BRANCH" ]]; then
		if git rev-parse --verify "$BRANCH" &>/dev/null; then
			git checkout "$BRANCH"
		else
			git checkout -b "$BRANCH" "$remote_branch"
			exit 0
		fi
	fi
	if git merge-base --is-ancestor HEAD "$remote_branch"; then
		echo 'Fast-forward possible. Merging...'
		git merge --ff-only --stat "$remote_branch"
	else
		echo 'Fast-forward not possible. Resetting...'
		git reset --hard "$remote_branch"
	fi
)
fi

# run post-update hook
(
	_RL_INTERNAL="rlrullz"
	export RL_SCRIPTS_SRC
	. "$RL_SCRIPTS_SRC/_post-update.sh"
)

rm -f "${RL_SCRIPTS_SRC}/.update-required"

echo "Lab scripts updated successfully!"

