#!/bin/bash

if [ "$1" == "" ]; then
    echo -e "\n[ERROR] You should provide a commit message!\n"
    exit
fi

cd ../../
REPOS_DIR="`pwd`"

for FILE in `find ./ -maxdepth 2 -name "docker.sh"`; do
    echo -e "\n > $FILE"

    rm "$FILE"
    cp "docker-things/helpers/docker.sh" "$FILE"

    cd "`dirname $FILE`"
    if [ "`git status | grep docker.sh | grep modified`" != "" ]; then
        git commit docker.sh -m "$1"
        git push
    else
        echo "   Nothing changed"
    fi

    cd "$REPOS_DIR"
done
