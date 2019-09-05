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

# Go through each repo containing a docker.sh script
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
