
# Rpm Build Instructions

rpm files for all sub-projects can be built using the file `build/build.sh`.  If this script is given parameters, it will build only
those projects specified on the command line, e.g.  `$ ./build/build.sh traffic_ops`.  The prerequisites for each sub-project are
listed below.

These build scripts depend on the text in the __VERSION__ file along with the __BUILD_NUMBER__ described below to name each rpm.

The build scripts use environment variables to control how the build is done.  These have sensible defaults listed below, and it is
recommended to not override them:
* __WORKSPACE__
   - defaults to the top level of the traffic_control directory.  The _dist_ and _rpmbuild_ directories are created in this
     directory during the rpm build process.
* __BUILD_NUMBER__
   - generates build number from the number of commits on the current git branch followed by the 8 character short commit hash of
     the last commit on the branch.This number is used to create the rpm version, e.g. _traffic_ops.1.2.0.1723.a18e2bb7_.  

At the conclusion of the build,  all rpms are copied into the __$WORKSPACE/dist__ directory.

## Prerequisites for building:

### all sub-projects

* CentOS 6.x
* rpmbuild (yum install rpm-build)
* git 1.7.12 or higher

#### traffic_ops:
* perl 5.10 or higher
* go 1.4 or higher

#### traffic_stats:
* go 1.4 or higher
  
#### traffic_monitor and traffic_router:
* jdk 6.0 or higher
* apache-maven 3.3.1 or higher
 
# Docker build instructions

__Building using `docker` is experimental at this time and has not been fully vetted.__

Dockerfiles for each sub-project are located in the build directory (e.g. `traffic_ops/build/Dockerfile`)

## Optionally set these environment variables to control the source to start with:
* `GITREPO` (default is `https://github.com/Comcast/traffic_control`) and `BRANCH` (default is master).

> export GITHUB_REPO=https://github.com/myuser/traffic_control
> export BRANCH=feature/my-new-feature
> ./build/docker-build.sh

