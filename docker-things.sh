#!/bin/bash

DEPENDENCIES="bash docker git"

# WhereAmI function
function get_script_dir() {
     SOURCE="${BASH_SOURCE[0]}"
     while [ -h "$SOURCE" ]; do
          DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
          SOURCE="$( readlink "$SOURCE" )"
          [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
     done
     DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
     echo "$DIR"
}
cd "$(get_script_dir)"

# Load the config
. config.sh

# Output functions
function showNormal() { echo -e "\033[00m$@"; }
function showGreen() { echo -e "\033[01;32m$@\033[00m"; }
function showYellow() { echo -e "\033[01;33m$@\033[00m"; }
function showRed() { echo -e "\033[01;31m$@\033[00m"; }

# Launch the required action
function main() {
    checkDependencies
    if [ $# -lt 2 ]; then
        runCommand $@
    else
        for THING in ${@:2}; do
            runCommand "$1" "$THING"
        done
    fi
}
function runCommand() {
    case "$1" in
        "list")         listThings         ;;
        "build")        passCMD build $2   ;;
        "install")      passCMD install $2 ;;
        "start")        passCMD start $2   ;;
        "stop")         passCMD stop $2    ;;
        "kill")         passCMD kill $2    ;;
        "get")          getThing $2        ;;
        "update")       updateThing $2     ;;
        "delete")       deleteThing $2     ;;
        "self-install") selfInstall        ;;
        *)              showUsage          ;;
    esac
}

# Usage
function showUsage() {
    showNormal "\nUsage: $0 [OPTION] [THING]\n"
    showNormal "OPTIONS:"
    showNormal "  list         - List available things"
    showNormal "  build        - Build docker image"
    showNormal "  install      - Install app launcher (get & build if needed)"
    showNormal "  start        - Start docker image"
    showNormal "  stop         - Stop docker image"
    showNormal "  kill         - Kill docker image"
    showNormal "  get          - Get repository"
    showNormal "  update       - Update repository"
    showNormal "  delete       - Delete app"
    showNormal "  self-install - Install this script in /usr/bin"
    showNormal ""
    exit 1
}

# List available things
function listThings() {
    THINGS=(
        android-studio
        chromium
        dropbox
        duckdns
        firefox
        keepass
        mattermost
        smarthome
        sublimetext
        thunderbird
        tunneling-service
        )
    showNormal "Available things:"

    for THING in ${THINGS[@]}; do
        if [ -f "/usr/bin/$THING" ]; then
            showGreen " - $THING"
        else
            showNormal " - $THING"
        fi
    done
    exit
}

# Self install
function selfInstall() {
    showGreen "\nInstalling docker-things..."
    BIN_FILE="/usr/bin/docker-things"
    CFG_FILE="`pwd`/config.sh"
    THIS_FILE="`pwd`/docker-things.sh"
    sudo sh -c "
        cat \"$CFG_FILE\" > $BIN_FILE \
     && cat \"$THIS_FILE\" | grep -v '. config.sh' | grep -v 'self-install' >> $BIN_FILE \
     && chmod +x \"$BIN_FILE\" \
     "

    showGreen "\nScript installed @ $BIN_FILE..."
}

# Passthrough calls
function passCMD() {
    if [ "$1" == "build" ]; then
        getThing "$2"
    elif [ "$1" == "install" ]; then
        passCMD build "$2"
    fi
    showGreen "\n${1^}ing $2..."
    checkRepo "$2"
    cd "$REPOS_PATH/$2"
    bash docker.sh "$1"
}

# Repo related
function getThing() {
    showGreen "\nGetting $1..."
    if [ -d "$REPOS_PATH/$1/.git" ]; then
        showNormal "\nRepository already exists!"
    else
        mkdir -p "$REPOS_PATH"
        git clone "https://github.com/docker-things/$1.git" "$REPOS_PATH/$1"
        checkRepo "$1"
    fi
    configThing "$1"
    buildDependencies "$1"
}
function updateThing() {
    showGreen "\nUpdating $1..."
    checkRepo "$1"
    cd "$REPOS_PATH/$1" && git checkout . && git pull
    configThing "$1"
    buildDependencies "$1"
}
function deleteThing() {
    showGreen "\nDeleting $1..."
    rm -rf "$REPOS_PATH/$1"
}
function configThing() {
    showGreen "\nConfiguring $1..."
    for ((i=0; i<${#REPOS_CONFIG[@]}; i+=2)); do
        VAR_NAME="${REPOS_CONFIG[i]}"
        VAR_VALUE="${REPOS_CONFIG[i+1]}"
        if [ "`cat "$REPOS_PATH/$1/config.sh" | grep "$VAR_NAME="`" != "" ]; then
            cat "$REPOS_PATH/$1/config.sh" | grep -v "$VAR_NAME=" > "$REPOS_PATH/$1/config.sh.tmp"
            echo "$VAR_NAME='$VAR_VALUE'" >> "$REPOS_PATH/$1/config.sh.tmp"
            rm -f "$REPOS_PATH/$1/config.sh"
            mv "$REPOS_PATH/$1/config.sh.tmp" "$REPOS_PATH/$1/config.sh"
        fi
    done
}
function buildDependencies() {
    checkRepo "$1"
    if [ -f "$REPOS_PATH/$1/.dependencies" ]; then
        for DEPENDENCY in `cat "$REPOS_PATH/$1/.dependencies"`; do
            passCMD build "$DEPENDENCY"
        done
    fi
}

# Checks
function checkDependencies() {
    for BIN in $DEPENDENCIES; do
        if [ "`which $BIN`" == "" ]; then
            showRed "[ERROR] Dependency not found: \"$BIN\""
            exit
        fi
    done
}
function checkRepo() {
    if [ ! -d "$REPOS_PATH/$1" ]; then
        showRed "\n[ERROR][$1] Repository doesn't exist!"
        exit 1
    fi
    if [ ! -d "$REPOS_PATH/$1/.git" ]; then
        showRed "\n[ERROR][$1] Repository doesn't contain \".git\"!"
        exit 1
    fi
    if [ ! -f "$REPOS_PATH/$1/docker.sh" ]; then
        showRed "\n[ERROR][$1] Repository doesn't contain \"docker.sh\"!"
        exit 1
    fi
    if [ ! -f "$REPOS_PATH/$1/config.sh" ]; then
        showRed "\n[ERROR][$1] Repository doesn't contain \"config.sh\"!"
        exit 1
    fi
}

# Actually do stuff
main $@
