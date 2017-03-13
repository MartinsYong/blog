#!/bin/sh
# author: mt

./node_modules/.bin/hexo clean
./node_modules/.bin/hexo g
export GLOBIGNORE=.git
rm -rf ../blogpublic/*
unset GLOBIGNORE
cp -rf ./public/* ../blogpublic/
cd ../blogpublic
git add .
git commit -am "update"
git push
