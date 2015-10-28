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

# By default all sub-projects are built.  Supply a list of projects to build if
# only a subset is wanted.

# make sure we start out in traffic_control dir
top=${0%%/*}
[[ -n $top ]] && cd $top

if [[ $# -gt 0 ]]; then
	projects="$*"
else
	# get all subdirs containing build/build_rpm.sh
	projects=*/build/build_rpm.sh
fi

badproj=()
goodproj=()
for p in $projects; do
	# strip from first /
	p=${p%%/*}
	bldscript="$p/build/build_rpm.sh"
	if [[ ! -x $bldscript ]]; then
		echo "$bldscript not found"
		badproj+=($p)
		continue
	fi

	echo "-----  Building $p ..."
	if $bldscript; then
		goodproj+=($p)
	else
		echo "$p failed: $!"
		badproj+=($p)
	fi
done

if [[ -n $goodproj ]]; then
	echo "The following subdirectories built successfully: "
	for p in $goodproj; do
		echo "   $p"
	done
	echo "See $(pwd)/dist for newly built rpms."
fi

if [[ -n $badproj ]]; then
	echo "The following subdirectories had errors: "
	for p in $badproj; do
		echo "   $p"
	done
	exit 1
fi
