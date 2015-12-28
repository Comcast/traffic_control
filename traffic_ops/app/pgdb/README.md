PostgreSQL support for Traffic Ops.

Note: this is still very new - for now, MySQL is the safer choice!

##### Converting your existing database from MySQL
1. Set up pg environment

  ```
  to_integration=# \q
  jvd@pixel:~/work/gh/AnatolyUss/FromMySqlToPostgreSql$ psql --user postgres postgres
  psql (9.4.5)
  Type "help" for help.

  postgres=# create database to_development;
  CREATE DATABASE
  postgres=# \c to_development;
  You are now connected to database "to_development" as user "postgres".
  to_development=# ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON tables TO tm_user;
  ALTER DEFAULT PRIVILEGES
  to_development=# ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, USAGE ON sequences TO tm_user;
  ALTER DEFAULT PRIVILEGES
  to_development=# 
  ```
2. Run FromMySqlToPostgreSql. See https://github.com/AnatolyUss/FromMySqlToPostgreSql for prereqs. The config file that worked for me:

  ```
  {
      "source_description" : [
          "Connection string to your MySql database",
          "Please ensure, that you have defined your connection string properly.",
          "Ensure, that details like 'charset=UTF8' are included in your connection string (if necessary)."
      ],
      "source" : "mysql:host=localhost;port=3306;charset=UTF8;dbname=to_development,root,your_mysql_passwd",
      
      "target_description" : [
          "Connection string to your PostgreSql database",
          "Please ensure, that you have defined your connection string properly.",
          "Ensure, that details like options='[double dash]client_encoding=UTF8' are included in your connection string (if necessary)."
      ],
      "target" : "pgsql:host=localhost;port=5432;dbname=to_development;options=--client_encoding=UTF8,postgres,your_postgres_passwd",
      
      "encoding_description" : [
          "PHP encoding type.",
          "If not supplied, then UTF-8 will be used as a default."
      ],
      "encoding" : "UTF-8",
      
      "schema_description" : [
          "schema - a name of the schema, that will contain all migrated tables.",
          "If not supplied, then a new schema will be created automatically."
      ],
      "schema" : "public",
      
      "data_chunk_size_description" : [
          "During migration each table's data will be split into chunks of data_chunk_size (in MB).",
          "If not supplied, then 10 MB will be used as a default."
      ],
      "data_chunk_size" : 10
  }
  ```
3. Fix goose table
  ``` 
  to_development=# alter table goose_db_version add column is_applied_bool bool;
  ALTER TABLE
  to_development=# \d goose_db_version;
                                          Table "public.goose_db_version"
       Column      |            Type             |                           Modifiers                           
  -----------------+-----------------------------+---------------------------------------------------------------
   id              | numeric                     | not null default nextval('goose_db_version_id_seq'::regclass)
   version_id      | bigint                      | not null
   is_applied      | smallint                    | not null
   tstamp          | timestamp without time zone | default now()
   is_applied_bool | boolean                     | 
  Indexes:
      "goose_db_version_pkey" PRIMARY KEY, btree (id)
      "public_goose_db_version_id1_idx" UNIQUE, btree (id)

  to_development=# update goose_db_version set is_applied_bool=true where is_applied=1;
  UPDATE 46
  to_development=# alter table goose_db_version drop column is_applied;
  ALTER TABLE
  to_development=# alter table goose_db_version rename column is_applied_bool to is_applied;
  ALTER TABLE
  to_development=# \d goose_db_version;
                                       Table "public.goose_db_version"
     Column   |            Type             |                           Modifiers                           
  ------------+-----------------------------+---------------------------------------------------------------
   id         | numeric                     | not null default nextval('goose_db_version_id_seq'::regclass)
   version_id | bigint                      | not null
   tstamp     | timestamp without time zone | default now()
   is_applied | boolean                     | 
  Indexes:
      "goose_db_version_pkey" PRIMARY KEY, btree (id)
      "public_goose_db_version_id1_idx" UNIQUE, btree (id)

  to_development=#
  ```


Note that migrating views DOES NOT work with this tool, there's a small syntax error (too many levels of ()) in the conversion.

##### Migrating to the latest version with goose
Use  the path option, like ```goose -path pgdb -env pgintegration up```, below, the first one uses PostgreSQL, the second MySQL:

```
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ goose  -path pgdb -env=integration status
goose: status for environment 'integration'
    Applied At                  Migration
    =======================================
    Mon Dec 28 06:48:33 2015 -- 20151202193037_secondary_cg.sql
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ goose  -env=integration status
goose: status for environment 'integration'
    Applied At                  Migration
    =======================================
    Mon Dec 28 11:05:05 2015 -- 20141222103718_extension.sql
    Mon Dec 28 11:05:05 2015 -- 20150108100000_add_job_deliveryservice.sql
    Mon Dec 28 11:05:06 2015 -- 20150205100000_cg_location.sql
    Mon Dec 28 11:05:06 2015 -- 20150209100000_cran_to_asn.sql
    Mon Dec 28 11:05:06 2015 -- 20150210100000_ds_keyinfo.sql
    Mon Dec 28 11:05:06 2015 -- 20150304100000_add_ip6_ds_routing.sql
    Mon Dec 28 11:05:06 2015 -- 20150310100000_add_bg_fetch.sql
    Mon Dec 28 11:05:07 2015 -- 20150316100000_move_hdr_rw.sql
    Mon Dec 28 11:05:07 2015 -- 20150331105256_add_origin_shield.sql
    Mon Dec 28 11:05:07 2015 -- 20150501100000_add_mid_hdr_rw.sql
    Mon Dec 28 11:05:07 2015 -- 20150503100001_add_regex_remap.sql
    Mon Dec 28 11:05:07 2015 -- 20150504100000_rr_handling.sql
    Mon Dec 28 11:05:07 2015 -- 20150504100001_add_param_index.sql
    Mon Dec 28 11:05:07 2015 -- 20150521100000_add_cacheurl_to_ds.sql
    Mon Dec 28 11:05:07 2015 -- 20150530100000_add_any_remap.sql
    Mon Dec 28 11:05:07 2015 -- 20150618100000_add_multisite.sql
    Mon Dec 28 11:05:07 2015 -- 20150626100000_add_cg_uniq.sql
    Mon Dec 28 11:05:07 2015 -- 20150706084134_stats_summary_table.sql
    Mon Dec 28 11:05:07 2015 -- 20150721000000_add_stat_date.sql
    Mon Dec 28 11:05:07 2015 -- 20150722100000_add_disname_tr_headers.sql
    Mon Dec 28 11:05:07 2015 -- 20150728000000_add_initial_dispersion.sql
    Mon Dec 28 11:05:07 2015 -- 20150804000000_add_preprod_status.sql
    Mon Dec 28 11:05:07 2015 -- 20150807000000_add_dns_bypass_cname.sql
    Mon Dec 28 11:05:08 2015 -- 20150825175644_shorten_display_name.sql
    Mon Dec 28 11:05:08 2015 -- 20150922092122_cdn.sql
    Mon Dec 28 11:05:08 2015 -- 20150925020500_drop_cdn_param.sql
    Mon Dec 28 11:05:08 2015 -- 20151020143912_unique_cdn_name.sql
    Mon Dec 28 11:05:08 2015 -- 20151021000000_federation_tables.sql
    Mon Dec 28 11:05:08 2015 -- 20151027152323_tr_request_headers.sql
    Mon Dec 28 11:05:08 2015 -- 20151107000000_cdn_dnssec_enabled.sql
    Mon Dec 28 11:05:09 2015 -- 20151202193037_secondary_cg.sql
    Mon Dec 28 11:05:09 2015 -- 20151207000000_unique_email.sql
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ 
```

##### Running the tests and setting up you dev environment
Switching for testing is a bit messy still (see TODO). To run the MySQL tests, just checkout the tree and run `prove -pqr` in `traffic_control/traffic_ops/app`. Example of running the tests from a clean tree, first MySQL, then PostgreSQL:

```
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ ls conf
cdn.conf  development  integration  misc  pgdevelopment  pgintegration  pgtest  production  test
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ prove -pqr 2> /tmp/my.out
./t/aadata.t ................................ ok    
./t/api/1.0/availableds.t ................... ok   
./t/api/1.0/data.t .......................... ok    
./t/api/1.0/health.t ........................ ok   
./t/api/1.0/ort.t ........................... ok    
./t/api/1.1/asn.t ........................... ok    
./t/api/1.1/cachegroup.t .................... ok    
./t/api/1.1/cachegroupparameter.t ........... ok    
./t/api/1.1/deliveryservice/keys_url_sig.t .. ok    
./t/api/1.1/deliveryservice/ssl_keys.t ...... ok    
./t/api/1.1/deliveryserviceserver.t ......... ok    
./t/api/1.1/hwinfo.t ........................ ok    
./t/api/1.1/job.t ........................... ok    
./t/api/1.1/keys.t .......................... ok    
./t/api/1.1/log.t ........................... ok    
./t/api/1.1/metrics.t ....................... ok   
./t/api/1.1/parameter.t ..................... ok    
./t/api/1.1/phys_location.t ................. ok    
./t/api/1.1/profile.t ....................... ok    
./t/api/1.1/region.t ........................ ok    
./t/api/1.1/riak_adapter.t .................. ok    
./t/api/1.1/roles.t ......................... ok    
./t/api/1.1/server.t ........................ ok    
./t/api/1.1/staticdns.t ..................... ok    
./t/api/1.1/status.t ........................ ok    
./t/api/1.1/traffic_monitor.t ............... ok   
./t/api/1.1/types.t ......................... ok    
./t/api/1.1/user.t .......................... ok    
./t/api/1.2/asn.t ........................... ok    
./t/api/1.2/cache_stats.t ................... ok   
./t/api/1.2/deliveryservice_stats.t ......... ok    
./t/api/1.2/federation_external.t ........... ok    
./t/api/1.2/federation_internal.t ........... ok    
./t/api/1.2/server.t ........................ ok    
./t/api/1.2/stats_summary.t ................. ok    
./t/api/1.2/user.t .......................... ok    
./t/asn.t ................................... ok   
./t/deliveryservice.t ....................... ok    
./t/deliveryserviceserver.t ................. ok    
./t/federation.t ............................ ok    
./t/health.t ................................ ok    
./t/hwinfo.t ................................ ok    
./t/influxdb_adapter.t ...................... ok   
./t/log.t ................................... ok    
./t/modules.t ............................... ok     
./t/parameter.t ............................. ok    
./t/phys_location.t ......................... ok    
./t/profile.t ............................... ok    
./t/purge.t ................................. ok   
./t/rascal_status.t ......................... ok   
./t/server.t ................................ ok     
./t/staticdnsentry.t ........................ ok    
./t/status.t ................................ ok    
./t/types.t ................................. ok    
./t/uploadhandlercsv.t ...................... ok    
./t/user.t .................................. ok    
./t_integration/000init_database.t .......... ok   
./t_integration/configfiles.t ............... ok      
./t_integration/configfiles_view.t .......... ok      
./t_integration/extensions.t ................ ok     
./t_integration/server.t .................... ok     
./t_integration/servercheck.t ............... ok     
All tests successful.
Files=62, Tests=7088, 396 wallclock secs ( 1.32 usr  0.03 sys + 293.23 cusr 23.09 csys = 317.67 CPU)
Result: PASS
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ mv conf/test conf/mytest
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ mv conf/pgtest/ conf/test
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ mv conf/integration/ conf/myintegration
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ mv conf/pgintegration/ conf/integration
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ prove -pqr 2> /tmp/pg.out
./t/aadata.t ................................ ok    
./t/api/1.0/availableds.t ................... ok   
./t/api/1.0/data.t .......................... ok    
./t/api/1.0/health.t ........................ ok   
./t/api/1.0/ort.t ........................... ok    
./t/api/1.1/asn.t ........................... ok    
./t/api/1.1/cachegroup.t .................... ok    
./t/api/1.1/cachegroupparameter.t ........... ok    
./t/api/1.1/deliveryservice/keys_url_sig.t .. ok    
./t/api/1.1/deliveryservice/ssl_keys.t ...... ok    
./t/api/1.1/deliveryserviceserver.t ......... ok    
./t/api/1.1/hwinfo.t ........................ ok    
./t/api/1.1/job.t ........................... ok    
./t/api/1.1/keys.t .......................... ok    
./t/api/1.1/log.t ........................... ok    
./t/api/1.1/metrics.t ....................... ok   
./t/api/1.1/parameter.t ..................... ok    
./t/api/1.1/phys_location.t ................. ok    
./t/api/1.1/profile.t ....................... ok    
./t/api/1.1/region.t ........................ ok    
./t/api/1.1/riak_adapter.t .................. ok    
./t/api/1.1/roles.t ......................... ok    
./t/api/1.1/server.t ........................ ok    
./t/api/1.1/staticdns.t ..................... ok    
./t/api/1.1/status.t ........................ ok    
./t/api/1.1/traffic_monitor.t ............... ok   
./t/api/1.1/types.t ......................... ok    
./t/api/1.1/user.t .......................... ok    
./t/api/1.2/asn.t ........................... ok    
./t/api/1.2/cache_stats.t ................... ok   
./t/api/1.2/deliveryservice_stats.t ......... ok    
./t/api/1.2/federation_external.t ........... ok    
./t/api/1.2/federation_internal.t ........... ok    
./t/api/1.2/server.t ........................ ok    
./t/api/1.2/stats_summary.t ................. ok    
./t/api/1.2/user.t .......................... ok    
./t/asn.t ................................... ok   
./t/deliveryservice.t ....................... ok    
./t/deliveryserviceserver.t ................. ok    
./t/federation.t ............................ ok    
./t/health.t ................................ ok    
./t/hwinfo.t ................................ ok    
./t/influxdb_adapter.t ...................... ok   
./t/log.t ................................... ok    
./t/modules.t ............................... ok     
./t/parameter.t ............................. ok    
./t/phys_location.t ......................... ok    
./t/profile.t ............................... ok    
./t/purge.t ................................. ok   
./t/rascal_status.t ......................... ok   
./t/server.t ................................ ok     
./t/staticdnsentry.t ........................ ok    
./t/status.t ................................ ok    
./t/types.t ................................. ok    
./t/uploadhandlercsv.t ...................... ok    
./t/user.t .................................. ok    
./t_integration/000init_database.t .......... ok   
./t_integration/configfiles.t ............... ok      
./t_integration/configfiles_view.t .......... ok      
./t_integration/extensions.t ................ ok     
./t_integration/server.t .................... ok     
./t_integration/servercheck.t ............... ok     
All tests successful.
Files=62, Tests=7088, 369 wallclock secs ( 1.33 usr  0.04 sys + 290.04 cusr 27.05 csys = 318.46 CPU)
Result: PASS
jvd@pixel:~/work/gh/knutsel/traffic_control-1/traffic_ops/app$ 
```

To use pg in dev, `mv conf/development conf/mydevelopment` and `mv conf/pgdevelopment conf/development`


##### TODO

1. create a pg version of dbadmin.pl
2. review database schema, and what can be made better (using migrations post MySQL conversion?)
  1. review varchar usage
  2. review smallint / integer usage (some are bools)
  3. use triggers for last_updated in stead of serials
  4. optimize indexes 
3. make it easier to switch environments ($ENV{} something?)
4. installer changes / seeds
5. fix dbdump functionality for pg
