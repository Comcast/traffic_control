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

function importFunctions() {
	local script=$(readlink -f "$0")
	local scriptdir=$(dirname "$script")
	export TS_DIR=$(dirname "$scriptdir")
	export TC_DIR=$(dirname "$TS_DIR")
	functions_sh="$TC_DIR/build/functions.sh"
	if [[ ! -r $functions_sh ]]; then
		echo "error: can't find $functions_sh"
		exit 1
	fi
	. "$functions_sh"
}

#----------------------------------------
function initBuildArea() {
	echo "Initializing the build area."
	mkdir -p "$RPMBUILD"/{SPECS,SOURCES,RPMS,SRPMS,BUILD,BUILDROOT} || { echo "Could not create $RPMBUILD: $?"; exit 1; }

	# tar/gzip the source
	local ts_dest=$(createSourceDir traffic_stats)
	cd "$TS_DIR" || \
		 { echo "Could not cd to $TS_DIR: $?"; exit 1; }
	rsync -av ./ "$ts_dest"/ || \
		 { echo "Could not copy to $to_dest: $?"; exit 1; }
	cp "$TS_DIR"/build/*.spec "$RPMBUILD"/SPECS/. || \
		 { echo "Could not copy spec files: $?"; exit 1; }

	cp -r "$TS_DIR"/ "$ts_dest" || { echo "Could not copy $TS_DIR to $ts_dest: $?"; exit 1; }

	tar -czvf "$ts_dest".tgz -C "$RPMBUILD"/SOURCES $(basename $ts_dest) || { echo "Could not create tar archive $ts_dest.tgz: $?"; exit 1; }
	cp "$TS_DIR"/build/*.spec "$RPMBUILD"/SPECS/. || { echo "Could not copy spec files: $?"; exit 1; }

	echo "The build area has been initialized."
}

# ---------------------------------------

importFunctions
checkEnvironment go
initBuildArea
buildRpm traffic_stats
