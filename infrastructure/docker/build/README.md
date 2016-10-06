
# Building *traffic_control* using *docker-compose*

- install `docker-engine` and `docker-compose`
- `cd traffic_control/infrastructure/docker/build`
- `export GITREPO=https://github.com/<username>/traffic_control`
- `export BRANCH=mynewbranch`
- `docker-compose up traffic_monitor_build traffic_ops_build ...`
- new rpm files will be in `./artifacts`
