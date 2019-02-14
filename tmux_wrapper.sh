#!/usr/bin/env bash
#~tmux_wrapper - starts user specified amount of tmux windows running ping_russia.sh
: '
the script only creates tmux sessions if they dont exist, so you can put this in your crontab and it will auto restart
instance that have crashed and burned.

creates a sub directory for each session, then start each instance in its own sub directory
**you need to change the following paths in ping_russia.sh
TARBALL_DIR, and SERVER_LIST need to be full static paths, NOT RELATIVE
ie.
"/home/$USER/downloads/git/frwl/frwl_tarballs"
"/home/$USER/downloads/git/frwl/servers.txt"
otherwise youll have to fish the tarballs out of each of the sub directories.
and the script will fail because it cant find ./servers.txt
(ping_russia.sh will automatically put tarballs in subdirectories by server name)

also this is all an experiment, ive never done this before and idk how resource intensive it is, so youll want to change stuff according to your setup
'

#~~~~~~~~~~#
#~ Config ~#
#~~~~~~~~~~#

LOG_FILE="/dev/null" #logging /dev/null for no loggint, &1 for STDOUT
TMUX_DIR="./tmux_dir" #all the subdirectories for each tmux session will be in here(so you dont have 500+ dirs in your root)
SESSION_NUM=500 #idk you might want to change this
SESSION_NAME="FRWLx$SESSION_NUM" #name for the tmux session
NAMING_FORMAT='frwl-%03d' #printf - for directory and tmux window names - crazy people can change the padding to %03d etc for over 999 sessions...

#~~~~~~~~~~~~~#
#~ Functions ~#
#~~~~~~~~~~~~~#

_log() {
	#~just a log function
	#~case logic for nice formating
	case $1 in
		date)
			#~appends date to front
			printf '%s\n' "`date +%Y-%m-%d_%T` ---  $2" >> $LOG_FILE
			;;
		*)
			#~just logs
			printf '%s\n' "$@" >> $LOG_FILE
			;;
	esac
}

_checkPath() {
	#~verifies paths exist/creates if needed
	[ -e "$1" ] || mkdir -p "$1"
	_log date "[_checkPath]checking directory $1"
}

#~~~~~~~~~~~~~~~~#
#~ script_start ~#
#~~~~~~~~~~~~~~~~#
_log date "[main]script start"

for ((SESSION=1; SESSION<=$SESSION_NUM; SESSION++)); do
	#~create some variables for better readability
	CRNT_NAME="$(printf "$NAMING_FORMAT" $SESSION)"
	_checkPath "$TMUX_DIR/$CRNT_NAME"
	#CMND="cd '$TMUX_DIR/$CRNT_NAME'; bash $(dirname "$0")/ping_russia.sh'"
	CMND="cd '$TMUX_DIR/$CRNT_NAME'; touch it_worked.txt; read"

	tmux has-session -t "$SESSION_NAME" &&\
	tmux new-window -a -t "$SESSION_NAME" -n "$CRNT_NAME" -d "$CMND"\
	|| tmux new -s "$SESSION_NAME" -n "$CRNT_NAME" -d "$CMND"
done
