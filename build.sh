#!/bin/bash

date +%H:%M:%S
echo Clean...
rm -rf ./dist

echo Static...
mkdir -p dist
cp -Rf static/* dist/

echo Caml...
./compile.sh src/pwdgen.ml dist/assets/js/pwdgen.js

echo OK!
