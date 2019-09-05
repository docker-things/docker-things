#!/bin/bash

if [ "$1" == "" ]; then
    echo -e "\n[ERROR] You should provide a commit message!\n"
    exit
fi

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

# Go to the dir containing all the docker-things repos
cd ../../
REPOS_DIR="`pwd`"

# Go through each repo containing a config.sh script
for FILE in `find ./ -maxdepth 2 -name "config.sh"`; do
    echo -e "\n > $FILE"

    cd "`dirname $FILE`"
    if [ "`git status | grep config.sh | grep modified`" != "" ]; then
        git commit config.sh -m "$1"
        git push
    else
        echo "   Nothing changed"
    fi

    cd "$REPOS_DIR"
done
