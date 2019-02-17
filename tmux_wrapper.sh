#!/usr/bin/env bash
#~tmux_wrapper - starts user specified amount of tmux windows running ping_russia.sh
: '
the script only creates tmux WINDOWS if they dont exist, so you can put this in your crontab and it will auto restart
instance that have crashed and burned.

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
    #~this is because i cant choose the window number for the first window of a session
    #~and i want each window number to match the session number
    #~so if a window dies, it will be recreated in the right spot
    tmux has-session -t "$SESSION_NAME" ||\
    tmux new -s "$SESSION_NAME" -n "initial_window" -d "sleep 30"
    #~then if window with $SESSION number doesnt exist, its created
    tmux select-window -t "$SESSION_NAME:$SESSION" ||\
    tmux new-window -a -t "$SESSION_NAME:$SESSION" -n "$CRNT_NAME" -d "$CMND"
done
