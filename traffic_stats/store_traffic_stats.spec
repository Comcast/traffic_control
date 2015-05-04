%define debug_package %{nil}
Name:		store_traffic_stats
Version:	@VERSION@
Release:	@RELEASE@
Summary:	Tool to pull data from traffic monitor and store in Influxdb
Packager:	david_neuman2 at Cable dot Comcast dot com
Vendor:		Comcast Cable
Group:		Applications/Communications
License:	N/A
URL:		https://github.com/comcast/traffic_control/
Source:		$RPM_SOURCE_DIR/traffic_stats-@VERSION@.tar.gz

%description
Installs store_traffic_stats.

%prep

%setup

%build

%install
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats/bin
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats/conf
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats/backup
mkdir -p ${RPM_BUILD_ROOT}/opt/traffic_stats/var/log/traffic_stats
mkdir -p ${RPM_BUILD_ROOT}/etc/init.d
mkdir -p ${RPM_BUILD_ROOT}/etc/logrotate.d

cp $GOPATH/src/github.com/comcast/traffic_control/traffic_stats/store_straffic_stats ${RPM_BUILD_ROOT}/opt/traffic_stats/bin
cp $GOPATH/src/github.com/comcast/traffic_control/traffic_stats/store_traffic_stats.cfg ${RPM_BUILD_ROOT}/opt/traffic_stats/conf/store_traffic_stats.cfg
cp $GOPATH/src/github.com/comcast/traffic_control/traffic_stats/store_traffic_stats_seelog.xml ${RPM_BUILD_ROOT}/opt/traffic_stats/conf/store_traffic_stats_seelog.xml
cp $GOPATH/src/github.com/comcast/traffic_control/traffic_stats/store_traffic_stats.init ${RPM_BUILD_ROOT}/etc/init.d/store_traffic_stats
cp $GOPATH/src/github.com/comcast/traffic_control/traffic_stats/store_traffic_stats.logrotate ${RPM_BUILD_ROOT}/etc/logrotate.d/store_traffic_stats

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

%config(noreplace) /opt/traffic_stats/conf/store_traffic_stats.cfg
%config(noreplace) /opt/traffic_stats/conf/store_traffic_stats_seelog.xml
%config(noreplace) /etc/logrotate.d/store_traffic_stats

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

%preun
# args for hooks: http://www.ibm.com/developerworks/library/l-rpm2/
# if $1 = 0, this is an uninstallation, if $1 = 1, this is an upgrade (don't do anything)
if [ "$1" = "0" ]; then
	/sbin/chkconfig --del traffic_stats
	/etc/init.d/traffic_stats stop
fi
