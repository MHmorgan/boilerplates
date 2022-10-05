#!/usr/bin/env zsh

source ~/lib/common.zsh


# Commands setup ##############################################################

set -A COMMAND_NAMES
set -A COMMANDS_DESC

COMMAND_NAMES+=(-h --help help)

# Command template:
#COMMAND_NAMES+=(<name>)
#COMMANDS_DESC+=(<one-line description>)
#function <name> { ... }


# Arguments ###################################################################

usage() {
	echo "Usage: script <cmd>"
	echo
    echo "Commands:"
	for desc in $COMMANDS_DESC; do
		echo "  $desc"
	done | sort
	if (( $# > 1)); then
		error $1
		shift
	fi
	exit $1
}

cmd=$COMMAND_NAMES[(r)$1*]
shift &> /dev/null  # Suppress error message when called without arguments

case $cmd in
	-h|--help|help|"")
		usage 0
		;;
	*)
		$cmd $@
		;;
esac
