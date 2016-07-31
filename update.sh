#!/bin/sh
# author: mt

shopt -s extglob
hexo clean
hexo g
rm -rf ../blogpublic/!(.git)
cp -rf ./public/* ../blogpublic/
cd ../blogpublic
git commit -am "update"
git push