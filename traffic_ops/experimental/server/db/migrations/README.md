
From `traffic_ops` 1.x to 2.x, we need these transformations:
- mysql => postgres *DONE*
- drop tables: `hwinfo`, `servercheck`, `job`, `job_agent`, `job_status`, `job_result` *DONE*
- remove `_id` sufix from column names *DONE*
- rename table `tmuser` to `user` and `to_extensions` to `extension` *DONE*
- rename all tables to plural form *DONE*
- split table `cdns` to `cdns` and `domains` *DONE*
- create table `crconfig_snapshots` *DONE*
- add type `port` as integer range *DONE*
- change uri columns to use `inet` types *DONE*
- fill in `domains.name`
- add views for each table

