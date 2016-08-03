#!/bin/bash

#
# Copyright 2015 Comcast Cable Communications Management, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#----------------------------------------
function importFunctions() {
	local script=$(readlink -f "$0")
	local scriptdir=$(dirname "$script")
	export TO_DIR=$(dirname "$scriptdir")
	export TC_DIR=$(dirname "$TO_DIR")
	functions_sh="$TC_DIR/build/functions.sh"
	if [[ ! -r $functions_sh ]]; then
		echo "error: can't find $functions_sh"
		exit 1
	fi
	. "$functions_sh"
}


# ---------------------------------------
function initBuildArea() {
	echo "Initializing the build area."
	mkdir -p "$RPMBUILD"/{SPECS,SOURCES,RPMS,SRPMS,BUILD,BUILDROOT} || { echo "Could not create $RPMBUILD: $?"; exit 1; }

	local to_dest=$(createSourceDir traffic_ops)
	cd "$TO_DIR" || \
		 { echo "Could not cd to $TO_DIR: $?"; exit 1; }
	rsync -av doc etc install "$to_dest"/ || \
		 { echo "Could not copy to $to_dest: $?"; exit 1; }
	rsync -av app/{bin,conf,cpanfile,db,lib,public,script,templates} "$to_dest"/app/ || \
		 { echo "Could not copy to $to_dest/app: $?"; exit 1; }
	tar -czvf "$to_dest".tgz -C "$RPMBUILD"/SOURCES $(basename "$to_dest") || \
		 { echo "Could not create tar archive $to_dest.tgz: $?"; exit 1; }
	cp "$TO_DIR"/build/*.spec "$RPMBUILD"/SPECS/. || \
		 { echo "Could not copy spec files: $?"; exit 1; }

	# Create traffic_ops_ort source area
	to_ort_dest=$(createSourceDir traffic_ops_ort)
	cp -p bin/traffic_ops_ort.pl "$to_ort_dest"
	cp -p bin/supermicro_udev_mapper.pl "$to_ort_dest"
	tar -czvf "$to_ort_dest".tgz -C "$RPMBUILD"/SOURCES $(basename "$to_ort_dest") || \
		 { echo "Could not create tar archive $to_ort_dest: $?"; exit 1; }
	
	echo "The build area has been initialized."
}

# ---------------------------------------
importFunctions
checkEnvironment go
initBuildArea
buildRpm traffic_ops traffic_ops_ort
