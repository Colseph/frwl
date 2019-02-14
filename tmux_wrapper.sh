#!/usr/bin/env bash
#~tmux_wrapper - starts user specified amount of tmux windows running ping_russia.sh
: '
the script only creates tmux WINDOWS if they dont exist, so you can put this in your crontab and it will auto restart
instance that have crashed and burned.

creates a sub directory for each session, then start each instance in its own sub directory
**you need to change the following paths in ping_russia.sh
TARBALL_DIR, SERVER_LIST need to be full static paths, NOT RELATIVE
its also recommended to use a static path for WORKING_DIR also IF your not running a unique ip per session
(which is not implimented yet)
then sessions sharing ips will pool files - problems:
	- clobbering (w/ 500 instances running, your bound to get duplicates)
	- incorrect ITER numbers(this is something w/ the iteration script in general)(but since its the timestamps were after,
	i dont think itll cause massive problems)
ie.
"/home/$USER/downloads/git/frwl/frwl_tarballs"
"/home/$USER/downloads/git/frwl/servers.txt"
"/home/$USER/downloads/git/frwl/working_dir"
otherwise youll have to fish the tarballs out of each of the sub directories.
and the script will fail because it cant find ./servers.txt
(ping_russia.sh will automatically put tarballs in subdirectories by server name)

its also recommented to create a new servers.txt with the total amount of servers you want to trace
ie 
	`mv servers.txt servers_original.txt; shuf -n 400 servers_original.txt` > servers.txt` #now servers.txt only has 400 randomly selected ips in it
this way youll get max of 20GB raw data, (50M*400ServersAvailable)/1000M vs this example:
if i had ping_russia.sh set to 10 servers, and i had 500 instances running in tmux, thers a POSSIBILITY(if every server is unique)
to be tracing 5000 servers and have a max of (10Servers*500Instances*50M)/1000M = 250GB of raw uncompressed data..

but idk you now your system, you can choose what you want to do.

also this is all an experiment, ive never done this before and idk how resource intensive it is, so youll want to change stuff according to your setup
'

#~~~~~~~~~~#
#~ Config ~#
#~~~~~~~~~~#

LOG_FILE="/dev/null" #logging /dev/null for no loggint, &1 for STDOUT
TMUX_DIR="./tmux_dir" #all the subdirectories for each tmux session will be in here(so you dont have 500+ dirs in your root)
PING_RUSSIA="$( cd "$(dirname "$0")" ; pwd -P )/ping_russia.sh" #location of ping_russia.sh - default same dir as tmux_wrapper.sh
SESSION_NUM=500 #idk you might want to change this
SESSION_NAME="FRWLx$SESSION_NUM" #name for the tmux session
NAMING_FORMAT='frwl-%03d' #printf - for directory and tmux window names - crazy people can change the padding to %04d etc for over 999 sessions...

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
	CMND="cd '$TMUX_DIR/$CRNT_NAME'; bash '$PING_RUSSIA'"

	#~if session doesnt exist creates a new one w/ a temporary window
	#~this is because i cant choose the window number for the first
	#~and i want each window number to match the session number
	#~so if a window dies, it will be recreated in the right spot
	tmux has-session -t "$SESSION_NAME" ||\
	tmux new -s "$SESSION_NAME" -n "initial_window" -d "sleep 30"
	#~then if window with $SESSION number doesnt exist, its created
	tmux select-window -t "$SESSION_NAME:$SESSION" ||\
	tmux new-window -a -t "$SESSION_NAME:$SESSION" -n "$CRNT_NAME" -d "$CMND"
done
