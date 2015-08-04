Requires: redis >= 2.8.15
#Requires: spdb_gateway >= 1.18

%define debug_package %{nil}
Name:		traffic_stats
Version:	1.1.2
Release:	1
Summary:	Tools to pull data from traffic monitor and store in Redis
#Packager:	jeffrey_elsloo at Cable dot Comcast dot com
Vendor:		Comcast Cable NETO PAS VSS CDNENG
Group:		Applications/Communications
License:	N/A
URL:		https://gitlab.sys.comcast.net/cdneng/tm/
Source:		%{name}-%{version}.tar.gz

%description
Installs traffic_stats tools.

%prep
mkdir ${RPM_PACKAGE_NAME}-${RPM_PACKAGE_VERSION}

%setup

%build
go build rascal_2_redis.go
go build backup_redis_daily.go

%install
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats/bin
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats/conf
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats/backup
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats/var/log/traffic_stats
mkdir -p ${RPM_BUILD_ROOT}/etc/cron.d
mkdir -p ${RPM_BUILD_ROOT}/etc/init.d
mkdir -p ${RPM_BUILD_ROOT}/etc/logrotate.d
mkdir -p ${RPM_BUILD_ROOT}/etc/spdb_gateway.d

cp rascal_2_redis ${RPM_BUILD_ROOT}/opt/traffic_stats/bin
#cp redis_2_spdb ${RPM_BUILD_ROOT}/opt/traffic_stats/bin
cp backup_redis_daily ${RPM_BUILD_ROOT}/opt/traffic_stats/bin
cp bck.sh ${RPM_BUILD_ROOT}/opt/traffic_stats/bin
cp config.json ${RPM_BUILD_ROOT}/opt/traffic_stats/conf/r2r.cfg
cp r2s_local.config ${RPM_BUILD_ROOT}/opt/traffic_stats/conf/r2s.cfg
cp seelog.xml ${RPM_BUILD_ROOT}/opt/traffic_stats/conf
cp traffic_stats.cron ${RPM_BUILD_ROOT}/etc/cron.d
#cp ipcdn_redis.cfg ${RPM_BUILD_ROOT}/etc/spdb_gateway.d
cp traffic_stats.init ${RPM_BUILD_ROOT}/etc/init.d/traffic_stats
cp traffic_stats.logrotate ${RPM_BUILD_ROOT}/etc/logrotate.d/traffic_stats

%clean
#rm -rf ${RPM_BUILD_ROOT}
#rm -rf $PWD

%pre
/usr/bin/getent group traffic_stats >/dev/null

if [ $? -ne 0 ]; then
	/usr/sbin/groupadd -g 422 traffic_stats
fi

/usr/bin/getent passwd traffic_stats >/dev/null

if [ $? -ne 0 ]; then
	/usr/sbin/useradd -g traffic_stats -u 422 -d /opt/traffic_stats -M traffic_stats
fi

/usr/bin/passwd -l traffic_stats >/dev/null
/usr/bin/chage -E -1 -I -1 -m 0 -M 99999 -W 7 traffic_stats

if [ -e /etc/init.d/traffic_stats ]; then
	/sbin/service traffic_stats stop
fi

%post
/sbin/chkconfig --add traffic_stats
/sbin/chkconfig traffic_stats on

%files
%defattr(644, traffic_stats, traffic_stats, 755)

%config(noreplace) /opt/traffic_stats/conf/r2r.cfg
%config(noreplace) /opt/traffic_stats/conf/r2s.cfg
%config(noreplace) /opt/traffic_stats/conf/seelog.xml
%config(noreplace) /etc/cron.d/traffic_stats.cron
%config(noreplace) /etc/logrotate.d/traffic_stats
#%config(noreplace) /etc/spdb_gateway.d/ipcdn_redis.cfg

%dir /opt/traffic_stats
%dir /opt/traffic_stats/bin
%dir /opt/traffic_stats/conf
%dir /opt/traffic_stats/backup
%dir /opt/traffic_stats/var
%dir /opt/traffic_stats/var/log
%dir /opt/traffic_stats/var/log/traffic_stats

%attr(600, traffic_stats, traffic_stats) /opt/traffic_stats/conf/*
%attr(755, traffic_stats, traffic_stats) /opt/traffic_stats/bin/*
%attr(755, traffic_stats, traffic_stats) /etc/init.d/traffic_stats
%attr(644, root, root) /etc/cron.d/traffic_stats.cron

%preun
# args for hooks: http://www.ibm.com/developerworks/library/l-rpm2/
# if $1 = 0, this is an uninstallation, if $1 = 1, this is an upgrade (don't do anything)
if [ "$1" = "0" ]; then
	/sbin/chkconfig --del traffic_stats
	/etc/init.d/traffic_stats stop
fi
