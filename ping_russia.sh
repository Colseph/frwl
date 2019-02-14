#!/bin/bash

#MUST BE RUN WITH SUPERUSER traceroute -I NEEDS IT!

#run script from an empty folder. It will create needed subfolders
#Also, use a filesystem that timestamps properly just in case you mix up
#old and new. Every time you restart this thing it will overwrite the old stuff.

#~~~~~~~~~~~~~#
#~ Variables ~#
#~~~~~~~~~~~~~#

LOG_FILE="/dev/null" #logging is disabled by default as we want to fill out HDDs w/ DATA not un-needed logs
ITER=0
COMP_ITER=0
SERVER_LIST="./servers.txt" #insert any server IP here
SERVER_NUM=10 #seems like a decent enough default value?
WORKING_DIR="./working_dir" #directory for uncompressed raw data
TARBALL_DIR="./from_russia_with_love_comp" #directory for compressed tarballs
DEPENDENCIES=(traceroute tar); #not every distro has these pre-installed

#~~~~~~~~~~~~~#
#~ Functions ~#
#~~~~~~~~~~~~~#

_log() {
	#~just a log function
	#~case logic for nice formating
	#~logging is kept to a minimum to keep log files small
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

_tarBall() {
	#~creates tarball of collected data with id/timestamp
	tar cjf "$TARBALL_DIR/$COMP_ITER.$TIME.$SERVER.tar.xz" "$WORKING_DIR"/* --remove-files
	_log date "[_tarBall]created tarball '$COMP_ITER.$TIME.$SERVER.tar.xz'"
	COMP_ITER=$(( COMP_ITER + 1 ))
	ITER=0
	_updateDirs
}

_updateDirs() {
	#~check if if theres any updates to SERVER_LIST and make required directories
	while read LINE; do
		if [[ ! "$LINE" == *"#"* ]]; then
			_checkPath "$WORKING_DIR/$LINE"
			_checkPath "$TARBALL_DIR/$LINE"
		fi
	done < "./selected_servers.txt"
}

_verifyServerList() {
	#~gets user defined amount of random lines from $SERVER_LIST
	#~if server_new.txt doesnt already exist
	#~might grab comments, so selected servers might be less than wanted
	if [ -e "./selected_servers.txt" ]; then
		_log date "[_verifyServerList]selected_servers.txt already exists"
	else
		_log date "[_verifyServerList]selected_servers.txt not found, creating w/ ($SERVER_NUM) ips"
	       	shuf -n $SERVER_NUM "$SERVER_LIST" > "./selected_servers.txt"
	fi
	_log date "[_verifyServerList]server_new.txt verified with ips: "
	_log "$(cat "./selected_servers.txt")"
}

#~~~~~~~~~~~~~~~~#
#~ script_start ~#
#~~~~~~~~~~~~~~~~#
_log date "[main]script start"

for p in "${DEPENDENCIES[@]}"; do
	if ! [ -x "$(command -v $p)" ]; then
        echo "$p is not installed"; exit 1;
    fi
done

_verifyServerList
while true
do
	_updateDirs
	while read LINE; do
		if [[ ! "$LINE" == *"#"* ]] && [[ -n "$LINE" ]]; then
			#~filters comments(#) and blanks lines
			SERVER=$LINE #only for better readability
			TIME=$(date +%s)
			SIZE=$(du -B 50M "$WORKING_DIR/$SERVER/" | cut -d "	" -f 1)
			traceroute -I $SERVER > "$WORKING_DIR/$SERVER/$ITER.$TIME.old"
			ITER=$(( ITER + 1 ))
			[ $SIZE -gt 1 ] && _tarBall
			traceroute -I $SERVER > "$WORKING_DIR/$SERVER/$ITER.$TIME.new"
		fi
	done < "./selected_servers.txt"
done
