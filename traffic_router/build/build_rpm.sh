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
function installDnsSec {
	# download and integrate dnssec library
	local dnssecversion=0.12
	local dnssectools=jdnssec-tools
	local dnssec="$dnssectools-$dnssecversion"
	local dnssecurl=http://www.verisignlabs.com/dnssec-tools/packages

	curl -o "$dnssec".tar.gz "$dnssecurl/$dnssec".tar.gz || \
		{ echo "Could not download required $dnssec library: $?"; exit 1; }
	tar xzvf "$dnssec".tar.gz ||  \
		{ echo "Could not extract required $dnssec library: $?"; exit 1; }

	(cd "$dnssec" && \
	 mvn install::install-file -Dfile=./lib/jdnssec-tools.jar -DgroupId=jdnssec -Dpackaging=jar \
		-DartifactId=jdnssec-tools -Dversion="$dnssecversion" \
	)  || { echo "Could not install required $dnssec library: $?"; exit 1; } \
}

#----------------------------------------
function buildRpm () {
	echo "Building the rpm."
	local version="-Dtraffic_control.version=$TC_VERSION"
	local targetdir="-Dproject.build.directory=$BLDPATH"
	cd "$BLDPATH" || { echo "Could not cd to $BLDPATH: $?"; exit 1; }

	installDnsSec

	# Do the rpmbuild
	export GIT_REV_COUNT=$(git rev-list HEAD | wc -l)
	mvn -Dmaven.test.skip=true -DminimumTPS=1 "$version" "$targetdir" package ||  \
		{ echo "RPM BUILD FAILED: $?"; exit 1; }
	local rpm=$(find -name \*.rpm)
	if [[ -z $rpm ]]; then
		echo "Could not find rpm file $RPM in $(pwd)"
		exit 1;
	fi
	echo "========================================================================================"
	echo "RPM BUILD SUCCEEDED, See $DIST/$RPM for the newly built rpm."
	echo "========================================================================================"
	echo
	mkdir -p "$DIST" || { echo "Could not create $DIST: $?"; exit 1; }

	cp "$rpm" "$DIST/." || { echo "Could not copy $rpm to $DIST: $?"; exit 1; }

	# TODO: build src rpm separately -- mvn rpm plugin does not do src rpms
	#cd "RPMBUILD" && \
	#	rpmbuild -bs --define "_topdir $(pwd)" \
        #                 --define "traffic_control_version $TC_VERSION" \
        #                 --define "build_number $BUILD_NUMBER" -ba SPECS/${PACKAGE}.spec
	#cp "$RPMBUILD"/SRPMS/*/*.rpm "$DIST/." || { echo "Could not copy source rpm to $DIST: $?"; exit 1; }
}


#----------------------------------------
function checkEnvironment() {
	echo "Verifying the build configuration environment."
	local script=$(readlink -f "$0")
	local scriptdir=$(dirname "$script")
	export TM_DIR=$(dirname "$scriptdir")
	export TC_DIR=$(dirname "$TM_DIR")
	functions_sh="$TC_DIR/build/functions.sh"
	if [[ ! -r $functions_sh ]]; then
		echo "Error: Can't find $functions_sh"
		exit 1
	fi
	. "$functions_sh"

	# 
	# get traffic_control src path -- relative to build_rpm.sh script
	export PACKAGE="traffic_router"
	export TC_VERSION=$(getVersion "$TC_DIR")
	export BUILD_NUMBER=${BUILD_NUMBER:-$(getBuildNumber)}
	export WORKSPACE=${WORKSPACE:-$TC_DIR}
	export RPMBUILD="$WORKSPACE/rpmbuild"
	export DIST="$WORKSPACE/dist"
	export RPM="${PACKAGE}-${TC_VERSION}-${BUILD_NUMBER}.x86_64.rpm"

	echo "=================================================="
	echo "WORKSPACE: $WORKSPACE"
	echo "BUILD_NUMBER: $BUILD_NUMBER"
	echo "TC_VERSION: $TC_VERSION"
	echo "RPM: $RPM"
	echo "--------------------------------------------------"
}

# ---------------------------------------
function initBuildArea() {
	echo "Initializing the build area."
	mkdir -p "$RPMBUILD"/{SPECS,SOURCES,RPMS,SRPMS,BUILD,BUILDROOT} || { echo "Could not create $RPMBUILD: $?"; exit 1; }

	local target="$PACKAGE-$TC_VERSION"
	# export these so build fcn has them
	export SRCPATH="$RPMBUILD/SOURCES/$target"
	export BLDPATH="$RPMBUILD/BUILD/$target"
	mkdir -p "$SRCPATH" || { echo "Could not create $SRCPATH: $?"; exit 1; }
	mkdir -p "$BLDPATH" || { echo "Could not create $BLDPATH: $?"; exit 1; }

	# TODO: what can be cut out here?
	cp -r "$TM_DIR"/{api,build,connector,core} "$SRCPATH"/. || { echo "Could not copy to $SRCPATH: $?"; exit 1; }
	cp  "$TM_DIR"/pom.xml "$SRCPATH" || { echo "Could not copy to $SRCPATH: $?"; exit 1; }
	cp -r "$SRCPATH"/* "$BLDPATH"

	# tar/gzip the source
	tar -czvf "$SRCPATH".tgz -C "$RPMBUILD/SOURCES" "$target" || { echo "Could not create tar archive $SRCPATH.tgz: $?"; exit 1; }

	echo "The build area has been initialized."
}

# ---------------------------------------

checkEnvironment
initBuildArea
buildRpm
