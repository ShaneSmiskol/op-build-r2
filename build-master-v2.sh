#!/usr/bin/env bash
set -e

mkdir -p /dev/shm
chmod 777 /dev/shm


SOURCE_DIR=/data/openpilot_source
TARGET_DIR=/data/openpilot_build

ln -sf $TARGET_DIR /data/pythonpath

export GIT_COMMITTER_NAME="ShaneSmiskol"
export GIT_COMMITTER_EMAIL="shane@smiskol.com"
export GIT_AUTHOR_NAME="ShaneSmiskol"
export GIT_AUTHOR_EMAIL="shane@smiskol.com"
export GIT_SSH_COMMAND="ssh -i /data/gitkey"

VERSION="0.7.5"

cd /data/openpilot
git checkout master
git fetch
git reset --hard origin/master
git pull
git clean -xfd
git submodule update --init
git submodule foreach --recursive git reset --hard
git submodule foreach --recursive git clean -xdf
echo "Done setting up master branch"

rm -f panda/board/obj/panda.bin.signed

SCONS_CACHE=1 scons -j8

echo "[-] committing version $VERSION T=$SECONDS"
git add -f .
git status
git commit -a -m "openpilot v$VERSION release"

git push -f origin master-ci
echo "Successfully pushed"