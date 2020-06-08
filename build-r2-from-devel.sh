#!/usr/bin/env bash
set -e

export GIT_COMMITTER_NAME="ShaneSmiskol"
export GIT_COMMITTER_EMAIL="shane@smiskol.com"
export GIT_AUTHOR_NAME="ShaneSmiskol"
export GIT_AUTHOR_EMAIL="shane@smiskol.com"

export GIT_SSH_COMMAND="ssh -i /data/gitkey"

# Create folders
rm -rf /data/openpilot_build
mkdir -p /data/openpilot_build
cd /data/openpilot_build

# Create git repo
git init
git remote add origin git@github.com:commaai/openpilot.git
git fetch origin devel
git fetch origin release2-staging
git fetch origin dashcam-staging

# Checkout devel
#git checkout origin/devel
#git clean -xdf

# Create release2 with no history
git checkout --orphan release2-staging origin/devel

VERSION=$(cat selfdrive/common/version.h | awk -F\" '{print $2}')
git commit -m "openpilot v$VERSION"

# Build signed panda firmware
pushd panda/board/
cp -r /tmp/pandaextra /data/openpilot_build/
RELEASE=1 make obj/panda.bin
mv obj/panda.bin /tmp/panda.bin
make clean
mv /tmp/panda.bin obj/panda.bin.signed
rm -rf /data/openpilot_build/pandaextra
popd

# Build stuff
ln -sf /data/openpilot_build /data/pythonpath
export PYTHONPATH="/data/openpilot_build:/data/openpilot_build/pyextra"
SCONS_CACHE=1 scons -j3
nosetests -s selfdrive/test/test_openpilot.py

# Cleanup
find . -name '*.pyc' -delete
rm .sconsign.dblite

# Mark as prebuilt release
touch prebuilt

# Add built files to git
git add -f .
git commit --amend -m "openpilot v$VERSION"

# Push to release2-staging
git push -f origin release2-staging
