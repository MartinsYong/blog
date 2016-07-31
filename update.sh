#!/bin/sh
# author: mt

hexo clean
hexo g
export GLOBIGNORE=.git
rm -rf ../blogpublic/*
unset GLOBIGNORE
cp -rf ./public/* ../blogpublic/
cd ../blogpublic
git commit -am "update"
git push