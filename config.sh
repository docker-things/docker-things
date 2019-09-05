#!/bin/bash

# Where to store the things
REPOS_PATH="$HOME/.docker-things/repos"

# Repos config
REPOS_CONFIG=(
    # Command used to launch docker
    DOCKER_CMD "`which docker`"

    # Where to store the backups (If empty there won't be any backups performed)
    BACKUP_PATH ""

    # Where to store the communication pipes
    FIFO_PATH="/tmp/docker-things/fifo"

    # Keepass DB & KEY dir paths
    KEEPASS_DB_PATH "$REPOS_PATH/dropbox/data/Dropbox/kp"
    KEEPASS_KEY_PATH "$REPOS_PATH/keepass/data/key"
    )
