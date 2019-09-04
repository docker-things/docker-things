#!/bin/bash

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
function scriptRun() {
    echo "${@:2}"
    exit
    for THING in "${@:2}"; do
        case "$1" in
            "build")        passCMD build $THING   ;;
            "install")      passCMD install $THING ;;
            "start")        passCMD start $THING   ;;
            "stop")         passCMD stop $THING    ;;
            "kill")         passCMD kill $THING    ;;
            "get")          getThing $THING        ;;
            "update")       updateThing $THING     ;;
            "delete")       deleteThing $THING     ;;
            "self-install") selfInstall            ;;
            *)              showUsage              ;;
        esac
    done
}

# Usage
function showUsage() {
    showNormal "\nUsage: $0 [build|install|start|stop|kill|get|update|delete|self-install] [THING]\n"
    exit 1
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
}

# Passthrough calls
function passCMD() {
    showGreen "\n$1 $2..."
    checkRepo "$REPOS_PATH/$2"
    cd "$REPOS_PATH/$2"
    bash docker.sh "$1"
}

# Repo related
function getThing() {
    showGreen "\nGetting $1..."
    if [ ! -d "$REPOS_PATH/$1/.git" ]; then
        showRed "\n[ERROR][$1] Repository already exists!"
        exit 1
    fi
    mkdir -p "$REPOS_PATH"
    git clone "https://github.com/docker-things/$1.git" "$REPOS_PATH/$1"
    checkRepo "$REPOS_PATH/$1"
}
function updateThing() {
    showGreen "\nUpdating $1..."
    checkRepo "$REPOS_PATH/$1"
    cd "$REPOS_PATH/$1" && git checkout . && git pull
}
# function configThing() {

# }
function deleteThing() {
    showGreen "\nDeleting $1..."
    rm -rf "$REPOS_PATH/$1"
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
scriptRun $@
