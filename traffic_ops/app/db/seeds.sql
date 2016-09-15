/*
	Copyright 2015 Comcast Cable Communications Management, LLC

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	    http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/

insert ignore into role (id, name, description, priv_level) values (1, 'disallowed','Block all access',0);
insert ignore into role (id, name, description, priv_level) values (2, 'read-only user','Block all access', 10);
insert ignore into role (id, name, description, priv_level) values (3, 'operations','Block all access', 20);
insert ignore into role (id, name, description, priv_level) values (4, 'admin','super-user', 30);
insert ignore into role (id, name, description, priv_level) values (5, 'portal','Portal User', 2);
insert ignore into role (id, name, description, priv_level) values (6, 'migrations','database migrations user - DO NOT REMOVE', 20);
insert ignore into role (id, name, description, priv_level) values (7, 'federation','Role for Secondary CZF', 15);
insert ignore into tm_user (username, role,full_name) values ('portal',(select id from role where name='portal'),'Portal User');
insert ignore into tm_user (username, role, full_name, token) values ('extension', 3, 'Extension User, DO NOT DELETE', '91504CE6-8E4A-46B2-9F9F-FE7C15228498');
insert ignore into type (name, description, use_in_table) values ('CHECK_EXTENSION_BOOL', 'Extension for checkmark in Server Check', 'to_extension');
insert ignore into type (name, description, use_in_table) values ('CHECK_EXTENSION_NUM', 'Extension for int value in Server Check', 'to_extension');
insert ignore into type (name, description, use_in_table) values ('CHECK_EXTENSION_OPEN_SLOT', 'Open slot for check in Server Status', 'to_extension');
insert ignore into type (name, description, use_in_table) values ('CONFIG_EXTENSION', 'Extension for additional configuration file', 'to_extension');
insert ignore into type (name, description, use_in_table) values ('STATISTIC_EXTENSION', 'Extension source for 12M graphs', 'to_extension');
insert ignore into type (name, description, use_in_table) values ('RESOLVE4', 'federation type resolve4', 'federation');
insert ignore into type (name, description, use_in_table) values ('RESOLVE6', 'federation type resolve6', 'federation');
insert ignore into parameter (name, config_file, value) values ('snapshot_dir', 'regex_revalidate.config','public/Trafficserver-Snapshots/');
insert ignore into parameter (name, config_file, value) values ('maxRevalDurationDays', 'regex_revalidate.config', '90');

-- some of the old ones do not get a new place, and there will be 'gaps' in the column usage.... New to_extension add will have to take care of that.
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (1, 'ILO_PING', 'ILO', 'aa', '1.0.0', '-', 'ToPingCheck.pl', 1, '{ check_name: "ILO", "base_url": "https://localhost", "select": "ilo_ip_address", "cron": "9 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_BOOL') );
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (2, '10G_PING', '10G', 'ab', '1.0.0', '-', 'ToPingCheck.pl', 1, '{ check_name: "10G", "base_url": "https://localhost", "select": "ip_address", "cron": "18 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_BOOL') );
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (3, 'FQDN_PING', 'FQDN', 'ac', '1.0.0', '-', 'ToPingCheck.pl', 1, '{ check_name: "FQDN", "base_url": "https://localhost", "select": "host_name", "cron": "27 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_BOOL') );
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (4, 'CHECK_DSCP', 'DSCP', 'ad', '1.0.0', '-', 'ToDSCPCheck.pl', 1, '{ "check_name": "DSCP", "base_url": "https://localhost", "cron": "36 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_BOOL') );
 -- open EF
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (5, 'OPEN', '', 'ae', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (6, 'OPEN', '', 'af', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
--
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (7, 'IPV6_PING', '10G6', 'ag', '1.0.0', '-', 'ToPingCheck.pl', 1, '{ "select": "ip6_address", "cron": "0 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_BOOL') );
-- upd_pending H -> open
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (8, 'OPEN', '', 'ah', '1.0.0', '', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
-- open IJ
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
   values (9, 'OPEN', '', 'ai', '1.0.0', '', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (10, 'OPEN', '', 'aj', '1.0.0', '', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
--
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (11, 'CHECK_MTU', 'MTU', 'ak', '1.0.0', '-', 'ToMtuCheck.pl', 1, '{ "check_name": "MTU", "base_url": "https://localhost", "cron": "45 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_BOOL') );
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (12, 'CHECK_TRAFFIC_ROUTER_STATUS', 'RTR', 'al', '1.0.0', '-', 'ToRTRCheck.pl', 1, '{  "check_name": "RTR", "base_url": "https://localhost", "cron": "10 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_BOOL') );
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (13, 'OPEN', '', 'am', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (14, 'CACHE_HIT_RATIO_LAST_15', 'CHR', 'an', '1.0.0', '-', 'ToCHRCheck.pl', 1, '{ check_name: "CHR", "base_url": "https://localhost", cron": "0,15,30,45 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_NUM') );
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (15, 'DISK_UTILIZATION', 'CDU', 'ao', '1.0.0', '-', 'ToCDUCheck.pl', 1, '{ check_name: "CDU", "base_url": "https://localhost", cron": "20 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_NUM') );
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (16, 'ORT_ERROR_COUNT', 'ORT', 'ap', '1.0.0', '-', 'ToORTCheck.pl', 1, '{ check_name: "ORT", "base_url": "https://localhost", "cron": "40 * * * *" }',
    (select id from type where name='CHECK_EXTENSION_NUM') );
-- rest open
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (17, 'OPEN', '', 'aq', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (18, 'OPEN', '', 'ar', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (19, 'OPEN', '', 'as', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (20, 'OPEN', '', 'at', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (21, 'OPEN', '', 'au', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (22, 'OPEN', '', 'av', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (23, 'OPEN', '', 'aw', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (24, 'OPEN', '', 'ax', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (25, 'OPEN', '', 'ay', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (26, 'OPEN', '', 'az', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (27, 'OPEN', '', 'ba', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (28, 'OPEN', '', 'bb', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (29, 'OPEN', '', 'bc', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (30, 'OPEN', '', 'bd', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));
insert ignore into to_extension (id, name, servercheck_short_name, servercheck_column_name, version, info_url, script_file, isactive, additional_config_json, type)
  values (31, 'OPEN', '', 'be', '1.0.0', '-', '', 0, '', (select id from type where name='CHECK_EXTENSION_OPEN_SLOT'));

insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_0.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_0.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_8.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_8.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_10.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_10.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_12.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_12.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_14.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_14.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_16.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_16.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_18.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_18.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_20.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_20.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_22.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_22.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_24.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_24.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_26.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_26.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_28.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_28.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_30.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_30.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_32.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_32.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_34.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_34.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_36.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_36.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_38.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_38.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_40.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_40.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_48.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_48.config') limit 1;
insert into parameter (name, value, config_file) select * from (select 'location', '/opt/trafficserver/etc/trafficserver/dscp', 'set_dscp_56.config') as temp where not exists (select name from parameter where name = 'location' and config_file = 'set_dscp_56.config') limit 1;

insert ignore into profile (name, description) values ('RIAK_ALL', 'Riak profile for all CDNs');
insert ignore into type (name, description, use_in_table) values ('RIAK', 'Riak keystore', 'server');


insert ignore into profile (name, description) values ('TRAFFIC_STATS', 'Traffic_Stats profile');
insert ignore into profile (name, description) values ('TRAFFIC_PORTAL', 'Traffic_Portal profile');
insert ignore into type (name, description, use_in_table) values ('TRAFFIC_STATS', 'traffic_stats server', 'server');
insert ignore into type (name, description, use_in_table) values ('TRAFFIC_PORTAL', 'traffic_portal server', 'server');
insert ignore into type (name, description, use_in_table) values ('INFLUXDB', 'influxDb server', 'server');
insert ignore into profile (name, description) values ('INFLUXDB', 'InfluxDb profile');


insert into parameter (name, config_file, value) select * from (select 'CacheStats', 'traffic_stats.config', 'bandwidth') as temp where not exists (select name from parameter where name = 'CacheStats' and config_file = 'traffic_stats.config' and value = 'bandwidth') limit 1;
insert into parameter (name, config_file, value) select * from (select 'CacheStats', 'traffic_stats.config', 'maxKbps') as temp where not exists (select name from parameter where name = 'CacheStats' and config_file = 'traffic_stats.config' and value = 'maxKbps') limit 1;
insert into parameter (name, config_file, value) select * from (select 'CacheStats', 'traffic_stats.config', 'ats.proxy.process.http.current_client_connections') as temp where not exists (select name from parameter where name = 'CacheStats' and config_file = 'traffic_stats.config' and value = 'ats.proxy.process.http.current_client_connections') limit 1;
insert into parameter (name, config_file, value) select * from (select 'DsStats', 'traffic_stats.config', 'kbps') as temp where not exists (select name from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'kbps') limit 1;
insert into parameter (name, config_file, value) select * from (select 'DsStats', 'traffic_stats.config', 'tps_2xx') as temp where not exists (select name from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_2xx') limit 1;
insert into parameter (name, config_file, value) select * from (select 'DsStats', 'traffic_stats.config', 'status_4xx') as temp where not exists (select name from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'status_4xx') limit 1;
insert into parameter (name, config_file, value) select * from (select 'DsStats', 'traffic_stats.config', 'status_5xx') as temp where not exists (select name from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'status_5xx') limit 1;
insert into parameter (name, config_file, value) select * from (select 'DsStats', 'traffic_stats.config', 'tps_3xx') as temp where not exists (select name from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_3xx') limit 1;
insert into parameter (name, config_file, value) select * from (select 'DsStats', 'traffic_stats.config', 'tps_4xx') as temp where not exists (select name from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_4xx') limit 1;
insert into parameter (name, config_file, value) select * from (select 'DsStats', 'traffic_stats.config', 'tps_5xx') as temp where not exists (select name from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_5xx') limit 1;
insert into parameter (name, config_file, value) select * from (select 'DsStats', 'traffic_stats.config', 'tps_total') as temp where not exists (select name from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_total') limit 1;


insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'CacheStats' and config_file = 'traffic_stats.config' and value = 'bandwidth')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'CacheStats' and config_file = 'traffic_stats.config' and value = 'maxKbps')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'CacheStats' and config_file = 'traffic_stats.config' and value = 'ats.proxy.process.http.current_client_connections')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'kbps')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'kbps')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_2xx')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'status_4xx')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'status_5xx')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_3xx')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_4xx')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_5xx')
);
insert ignore into profile_parameter (profile, parameter) value (
  (select id from profile where name = 'TRAFFIC_STATS'),
  (select id from parameter where name = 'DsStats' and config_file = 'traffic_stats.config' and value = 'tps_total')
);
update server set https_port = 443 where https_port is null;
