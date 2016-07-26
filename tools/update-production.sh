#!/bin/bash 

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$CURR_DIR/.."

git pull 
rm -r build 
gulp --compile
echo "Copying build/public to __public__"
rm -r __public__ 2> /dev/null
cp -a build/public/ __public__
