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

# Go to the dir containing all the docker-things repos
cd ../../
REPOS_DIR="`pwd`"

# Go through each repo containing a .git dir
for DIR in `find ./ -maxdepth 2 -name ".git"`; do
    echo -e "\n > $DIR"

    cd "$DIR"
    cd ..
    git pull

    cd "$REPOS_DIR"
done
