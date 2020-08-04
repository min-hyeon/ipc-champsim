#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "Usage: ./git_commit.sh \"[MESSAGE]\""
    exit 1
fi

MESSAGE=${1}

git add -A
git commit -m ${MESSAGE}
git push
