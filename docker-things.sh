#!/bin/bash

DTVERSION=0.1

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
        "list")         listThings             ;;
        "build")        passCMD build $2       ;;
        "install")      passCMD install $2     ;;
        "start")        passCMD start $2       ;;
        "status")       passCMD status $2      ;;
        "connect")      passCMD connect $2     ;;
        "logs")         passCMD logs $2        ;;
        "stop")         passCMD stop $2        ;;
        "restart")      passCMD restart $2     ;;
        "kill")         passCMD kill $2        ;;
        "backup")       passCMD backup $2      ;;
        "restore")      passCMD restore $2     ;;
        "set-default")  passCMD set-default $2 ;;
        "get")          getThing $2            ;;
        "update")       updateThing $2         ;;
        "upgrade")      upgradeThing $2        ;;
        "delete")       deleteThing $2         ;;
        "fifo-listen")  launchFifoListeners    ;;
        "self-install") selfInstall            ;;
        "self-upgrade") selfUpgrade            ;;
        *)              showUsage              ;;
    esac
}

# Usage
function showUsage() {
    showNormal "\nDocker Things v$DTVERSION"
    showNormal "\nUsage: $0 [OPTION] [THING]\n"
    showNormal "OPTIONS:"
    showNormal "  backup       - Backup app"
    showNormal "  build        - Build app"
    showNormal "  connect      - Connect to the docker image"
    showNormal "  delete       - Delete app"
    showNormal "  fifo-listen  - Listens to FIFO messages from apps"
    showNormal "  get          - Get repository"
    showNormal "  install      - Install app launcher (get & build app if needed)"
    showNormal "  kill         - Kill app"
    showNormal "  list         - List available things"
    showNormal "  logs         - Show app logs"
    showNormal "  restart      - Restart app"
    showNormal "  restore      - Restore backup of the app"
    showNormal "  self-install - Install this script in /usr/bin/docker-things"
    showNormal "  self-upgrade - Upgrade docker-things from the github repo"
    showNormal "  set-default  - Set app as default for the host system"
    showNormal "  start        - Start app"
    showNormal "  status       - Show app status"
    showNormal "  stop         - Stop app"
    showNormal "  update       - Update repository"
    showNormal "  upgrade      - Upgrade app"
    showNormal ""

    listThings
    exit 1
}

# List available things
function listThings() {
    THINGS=(
        android-studio
        chromium
        dbeaver
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

    showNormal ""
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

# Self upgrade
function selfUpgrade() {
    showGreen "\nUpgrading docker-things..."
    if [ -d /tmp/dtrepo ]; then
        rm -rf /tmp/dtrepo
    fi
    git clone https://github.com/docker-things/docker-things.git /tmp/dtrepo
    if [ -f /tmp/dtrepo/docker-things.sh ]; then
        chmod +x /tmp/dtrepo/docker-things.sh
        exec /tmp/dtrepo/docker-things.sh self-install
    else
        showRed "[ERROR] Couldn't get the repository!"
    fi
}

# Passthrough calls
function passCMD() {
    if [ "$1" == "build" ]; then
        getThing "$2"
    elif [ "$1" == "install" ]; then
        passCMD build "$2"
    fi
    showGreen "\n${1^} $2..."
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
    updateDependencies "$1"
}
function upgradeThing() {
    updateThing "$1"
    passCMD install "$1"
}
function deleteThing() {
    showGreen "\nDeleting $1..."
    passCMD remove "$1"
    rm -rf "$REPOS_PATH/$1"
}
function configThing() {
    showGreen "\nConfiguring $1..."
    for ((i=0; i<${#REPOS_CONFIG[@]}; i+=2)); do
        VAR_NAME="${REPOS_CONFIG[i]}"
        VAR_VALUE="${REPOS_CONFIG[i+1]}"
        if [ "`cat "$REPOS_PATH/$1/config.sh" | grep "$VAR_NAME="`" != "" ]; then
            sed -ri "s/^${VAR_NAME}=.*/${VAR_NAME}=\"${VAR_VALUE//\//\\/}\"/" "$REPOS_PATH/$1/config.sh"
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
function updateDependencies() {
    checkRepo "$1"
    if [ -f "$REPOS_PATH/$1/.dependencies" ]; then
        for DEPENDENCY in `cat "$REPOS_PATH/$1/.dependencies"`; do
            updateThing "$DEPENDENCY"
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

# FIFO generic listener
function fifoListener() {
    echo "Launching FIFO listener for $1"
    while [ 1 ]; do
        while [ -p "${FIFO_PATH}/$1" ]; do
            read line < "${FIFO_PATH}/$1"
            $1 $line &
        done
        echo "FIFO not found. Sleeping 5s..."
        sleep 5s
    done
}

# FIFO listeners
function launchFifoListeners() {
    for FIFO in ${FIFO_LISTENERS[@]}; do
        PID_FILE="${FIFO_PATH}/${FIFO}.pid"

        # Kill running listeners
        if [ -f "$PID_FILE" ]; then
            PID="`cat $PID_FILE`"
            echo "Killing FIFO listener for $FIFO (PID: $PID)"
            kill -9 $PID
        fi

        fifoListener $FIFO &
        echo $! > "$PID_FILE"
    done
}

# Actually do stuff
main $@
