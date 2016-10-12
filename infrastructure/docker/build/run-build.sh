#!/usr/bin/env bash

target=$1
[[ -z $target ]] && echo "No target specified"
echo "Building $target"

echo "GITREPO=${GITREPO:=https://github.com/Comcast/traffic_control}"
echo "BRANCH=${BRANCH:=master}"

set -x
git clone $GITREPO -b $BRANCH traffic_control

cd traffic_control/$target
./build/build_rpm.sh
mkdir -p /artifacts
cp ../dist/* /artifacts/.

# Clean up for next build
cd -
rm -r traffic_control
