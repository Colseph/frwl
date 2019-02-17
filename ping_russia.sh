#!/bin/bash

#MUST BE RUN WITH SUPERUSER traceroute -I NEEDS IT!

#run script from an empty folder. It will create needed subfolders
#Also, use a filesystem that timestamps properly just in case you mix up
#old and new. Every time you restart this thing it will overwrite the old stuff.

#~~~~~~~~~~~~~#
#~ Variables ~#
#~~~~~~~~~~~~~#

#~the $( cd "$(dirname "$0")" ; pwd -P) part is basically ./ except makes it a full path
#~only needed if you use tmux_wrapper.sh, see tmux_wrapper section in README to see why this is important
LOG_FILE="$( cd "$(dirname "$0")" ; pwd -P )/frwl.log" #log is for debugging, and thus very verbose, recommend to set to /dev/null to disable
SERVER_LIST="$( cd "$(dirname "$0")" ; pwd -P )/servers.txt" #insert IP list here
SERVER_NUM=10 #seems like a decent enough default value?
WORKING_DIR="$( cd "$(dirname "$0")" ; pwd -P )/working_dir" #directory for uncompressed raw data
TARBALL_DIR="$( cd "$(dirname "$0")" ; pwd -P )/from_russia_with_love_comp" #directory for compressed tarballs

#~~~stuff below this shouldnt need editing~~~(unless you know what your doing)
TIMEZONE=$(date +”%Z”)
DEPENDENCIES=(traceroute tar); #not every distro has these pre-installed
SELECTED_SERVERS="$( cd "$(dirname "$0")" ; pwd -P )/selected_servers.txt" #location to store random servers chosen by script
ITER_SAVE_FILE="$( cd "$(dirname "$0")" ; pwd -P )/iter_save" #file for keeping track of ITER values
COMP_ITER_SAVE_FILE="$( cd "$(dirname "$0")" ; pwd -P )/comp_iter_saves" #file for keeping track of COMP_ITER values
SAVE_FILE_DELIM='---' #delimiter used in save files. its escaped so you can use almost anything. parenthesis will break it, and maybe other characters i havent tested

#~~~~~~~~~~~~~#
#~ Functions ~#
#~~~~~~~~~~~~~#

_log() {
    #~just a log function
    #~case logic for nice formating
    case $1 in
        date)
            #~appends date to front
            printf '%s\n' "`date +%Y-%m-%d_%T` ---  [$$]$2" >> $LOG_FILE
            ;;
        *)
            #~just logs
            printf '%s\n' "$@" >> [$$]$LOG_FILE
            ;;
    esac
}

_checkPath() {
    #~verifies paths exist/creates if needed
    [ -e "$1" ] || mkdir -p "$1"
    _log date "[_checkPath]checking directory $1"
}

_tarBall() {
    #~creates tarball of collected data with id/timestamp
    tar cjf "$TARBALL_DIR/$SERVER/$COMP_ITER.$TIME.$SERVER.tar.xz" "$WORKING_DIR/$SERVER"/* && rm -rf "$WORKING_DIR/$SERVER"/*
    _log date "[_tarBall]created tarball '$COMP_ITER.$TIME.$SERVER.tar.xz'"
    COMP_ITER=$(_increment "$COMP_ITER_SAVE_FILE")
    _log date "[_tarBall]COMP_ITER: $COMP_ITER"
    ITER=$(_increment 0 "$ITER_SAVE_FILE")
}

_updateDirs() {
    #~check if if theres any updates to SERVER_LIST and make required directories
    while read LINE; do
        if [[ ! "$LINE" == *"#"* ]]; then
            _checkPath "$WORKING_DIR/$LINE"
            _checkPath "$TARBALL_DIR/$LINE"
        fi
    done < "$SELECTED_SERVERS"
}

_verifyServerList() {
    #~gets user defined amount of random lines from $SERVER_LIST
    #~if server_new.txt doesnt already exist
    #~might grab comments, so selected servers might be less than wanted
    if [ -e "$SELECTED_SERVERS" ]; then
        _log date "[_verifyServerList]$SELECTED_SERVERS already exists"
    else
        _log date "[_verifyServerList]$SELECTED_SERVERS not found, creating w/ up to ($SERVER_NUM) ips"
            shuf -n $SERVER_NUM "$SERVER_LIST" > "$SELECTED_SERVERS"
    fi
    _log date "[_verifyServerList]$SELECTED_SERVERS verified with ips: "
    _log "$(cat "$SELECTED_SERVERS")"
}

_checkDeps() {
    #~check dependencies
    for p in "${DEPENDENCIES[@]}"; do
        if ! [ -x "$(which $p)" ]; then
            _log date "[_checkDeps]FATAL: $p is not installed or in the scripts PATH. exiting.."
            printf '%s\n' "FATAL: $p is not installed or in the scripts PATH. exiting.."; exit 1;
        fi
    done

    if [ ! -f "$SERVER_LIST" ] ; then
        _log date "[_checkDeps]FATAL: missing $SERVER_LIST exiting.."
      printf '$s\n' "FATAL: missing server list! please check the \$SERVER_LIST variable and verify '$SERVER_LIST' exists. exiting.."
      exit
    fi
}

_increment() {
    #~keeps ITER and COMP_ITER straight using a save file of sorts
    #~takes option and filename as arguments
    case $1 in
        0)
            #~triggers on tar - sets iter back to zero
            [[ "$(cat "$2")" == *"${SERVER}${SAVE_FILE_DELIM}"* ]] || printf '%s\n' "${SERVER}${SAVE_FILE_DELIM}0" >> "$2"
            sed -i "s/${SERVER}$(_escapeString "$SAVE_FILE_DELIM")\([0-9]\+\)/${SERVER}$(_escapeString "$SAVE_FILE_DELIM")0/g" "$2"
            printf '%s' '0' #returns 0 as value
            _log date "[_increment]set value for $SERVER in $2 to 0"
            ;;
        *)
            #~adds to save file it doesnt exist
            [[ "$(cat "$1")" == *"${SERVER}${SAVE_FILE_DELIM}"* ]] || printf '%s\n' "${SERVER}${SAVE_FILE_DELIM}0" >> "$1"
            #~grabs current iter state from list
            RETURN_VAL=$(cat "$1" | grep "${SERVER}$(_escapeString "$SAVE_FILE_DELIM")")
            _log date "[_increment]RETURN_VAL: '$RETURN_VAL' (pre parse)"
            RETURN_VAL=${RETURN_VAL#*"$SAVE_FILE_DELIM"}
            _log date "[_increment]RETURN_VAL: '$RETURN_VAL' (post parse)"
            #~increments value in the save file for next read
            sed -i "s/${SERVER}$(_escapeString "$SAVE_FILE_DELIM")\([0-9]\+\)/${SERVER}$(_escapeString "$SAVE_FILE_DELIM")$(($RETURN_VAL + 1))/g" "$1"
            printf '%s' "$RETURN_VAL" #retuns value read from $1
            _log date "[_increment]read value for $SERVER in $1 as $RETURN_VAL, and set new as $(($RETURN_VAL + 1)) "
            ;;
    esac
}

_randomDir() {
    #~just here in case i decide to use a hashed directory
    #~gets a random 3-level directory
    RETURN_VAL=$(dd if=/dev/urandom bs=512 count=1 2>&1 | md5sum | tail -1 | awk '{printf $1}' | cut -b1,2 --output-delimiter=/)
    printf '%s' "$RETURN_VAL"
    _log date "[_randomDir]returned value: $RETURN_VAL"
}

_escapeString() {
    #~escapes supplied string
    #~this allows users to use what would normally be considered regex expressions as part of the SAVE_FILE_DELIMITER
    printf '%q' "$1"
    _log date "[_escapeString]escaping '$1' --> '$(printf '%q' "$1")'"
}

#~~~~~~~~~~~~~~~~#
#~ script_start ~#
#~~~~~~~~~~~~~~~~#
_log date "[main]script start"
_checkDeps
_verifyServerList
_updateDirs
#~log variables
_log "[main]SCRIPT_VARIABLES:"
_log "LOG_FILE: $LOG_FILE"
_log "SERVER_LIST: $SERVER_LIST"
_log "SERVER_NUM: $SERVER_NUM"
_log "WORKING_DIR: $WORKING_DIR"
_log "TARBALL_DIR: $TARBALL_DIR"
_log "TIMEZONE: $TIMEZONE"
_log "DEPENDENCIES:[${DEPENDENCIES[@]}]"
_log "ITER_SAVE_FILE: $ITER_SAVE_FILE"
_log "COMP_ITER_SAVE_FILE: $COMP_ITER_SAVE_FILE"
_log "SAVE_FILE_DELIM: '$SAVE_FILE_DELIM'"

while true
do
    while read LINE; do
        if [[ ! "$LINE" == *"#"* ]] && [[ -n "$LINE" ]]; then
            #~filters comments(#) and blanks lines
            SERVER=$LINE #only for better readability
            TIME=$(date +%s)
            SIZE=$(du -s -B 50M "$WORKING_DIR/$SERVER" | awk '{printf $1}')
            ITER=$(_increment "$ITER_SAVE_FILE")
            _log "[main]LOOP_VARIABLES:"
            _log "SERVER: $SERVER"
            _log "TIME: $TIME"
            _log "SIZE: $SIZE"
            _log "ITER: $ITER"
            traceroute -I $SERVER > "$WORKING_DIR/$SERVER/$ITER.$TIME.old"
            ECODE=$?
            _log "[main]traceroute -I $SERVER completed w/ result: $ECODE"
            [ $SIZE -gt 1 ] && _tarBall
            traceroute -I $SERVER > "$WORKING_DIR/$SERVER/$ITER.$TIME.new"
            ECODE=$?
            _log "[main]traceroute -I $SERVER completed w/ result: $ECODE"
        fi
    done < "$SELECTED_SERVERS"
done
