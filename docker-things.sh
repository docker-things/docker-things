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
    showNormal "\nUsage: $0 [build|install|start|stop|kill|get|update|delete|self-install] [THING]\n"
    exit 1
}

function checkDependencies() {
    for BIN in $DEPENDENCIES; do
        if [ "`which $BIN`" == "" ]; then
            showRed "[ERROR] Dependency not found: \"$BIN\""
            exit
        fi
    done
}

# Self install
function selfInstall() {
    showGreen "\nInstalling docker-things..."
    BIN_FILE="/usr/bin/docker-things"
    CFG_FILE="`pwd`/config.sh"
    THIS_FILE="`pwd`/docker-things.sh"
    sudo sh -c "
        cat \"$CFG_FILE\" > $BIN_FILE \
     && cat \"$THIS_FILE\" | grep -v '. config.sh' >> $BIN_FILE \
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
    cat "$REPOS_PATH/$1/config.sh" | grep -v 'DOCKER_CMD=' | grep -v 'BACKUP_PATH=' > "$REPOS_PATH/$1/config.sh.tmp"
    echo "DOCKER_CMD='$DOCKER_CMD'" >> "$REPOS_PATH/$1/config.sh.tmp"
    echo "BACKUP_PATH='$BACKUP_PATH'" >> "$REPOS_PATH/$1/config.sh.tmp"
    rm -f "$REPOS_PATH/$1/config.sh"
    mv "$REPOS_PATH/$1/config.sh.tmp" "$REPOS_PATH/$1/config.sh"
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
