
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
alter table deliveryservice add column `routing_name` varchar(1024) default NULL;

insert into parameter (name, config_file, value) select * from (select 'routing.name.dns', 'CRConfig.json', 'edge') as temp where not exists (select name from parameter where name = 'routing.name.dns' and config_file = 'CRConfig.json' and value = 'edge') limit 1;
insert into parameter (name, config_file, value) select * from (select 'routing.name.http', 'CRConfig.json', 'tr') as temp where not exists (select name from parameter where name = 'routing.name.http' and config_file = 'CRConfig.json' and value = 'tr') limit 1;

SET @param_id := (select id from parameter where name = 'routing.name.dns' and value = 'edge' and config_file = 'CRConfig.json');
INSERT IGNORE INTO profile_parameter (profile, parameter )
  SELECT id, @param_id
  FROM profile
  where name like 'CCR%' ;

SET @param_id := (select id from parameter where name = 'routing.name.http' and value = 'tr' and config_file = 'CRConfig.json');
INSERT IGNORE INTO profile_parameter (profile, parameter )
  SELECT id, @param_id
  FROM profile
  where name like 'CCR%' ;
-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back

