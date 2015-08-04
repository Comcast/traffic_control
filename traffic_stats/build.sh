#!/bin/sh

VERSION=1.1.2
STATS_NAME=traffic_stats
STATS_PKG=$STATS_NAME-$VERSION
STATS_DIR=$STATS_PKG
STATS_TAR=buildroot/SOURCES/$STATS_PKG.tar.gz
STATS_SPEC_FILE=traffic_stats.spec
OPS_DIR=traffic_ops
OPS_CLIENT_DIR=$OPS_DIR/client
RPM_SOURCES=./buildroot/SOURCES
RPM_RPMS=./buildroot/RPMS


rm -rf buildroot
mkdir -p $RPM_SOURCES

mkdir -p $STATS_DIR
mkdir -p $OPS_CLIENT_DIR

echo "copying traffic_stats files..."
cp backup_redis_daily.go $STATS_DIR/
cp bck.sh $STATS_DIR/
cp config.json $STATS_DIR/
cp r2r.cfg $STATS_DIR/
cp r2s_local.config $STATS_DIR/
cp rascal_2_redis.go $STATS_DIR/
cp redis.spec $STATS_DIR/
cp seelog.xml $STATS_DIR/
cp stats.spec $STATS_DIR/
cp traffic_stats.cron $STATS_DIR/
cp traffic_stats.init $STATS_DIR/
cp traffic_stats.logrotate $STATS_DIR/
cp traffic_stats.spec $STATS_DIR/

echo "copying traffic_ops client files..."
#copy the client code
cp ../traffic_ops/client/*.go $OPS_CLIENT_DIR/

tar czvf $STATS_TAR $STATS_DIR $OPS_DIR
rm -rf $STATS_DIR
rm -rf $OPS_DIR

rm -rf buildroot/BUILD/$STATS_NAME-$VERSION/
rpmbuild --define "_topdir `pwd`/buildroot" -ba $STATS_SPEC_FILE

mv `find $RPM_RPMS -name "$STATS_NAME*.rpm"` .

