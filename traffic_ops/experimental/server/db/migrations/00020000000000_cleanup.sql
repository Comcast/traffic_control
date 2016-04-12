--
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE job
	DROP CONSTRAINT job_agent_fkey,
	DROP CONSTRAINT job_job_deliveryservice_fkey,
	DROP CONSTRAINT job_job_user_fkey,
	DROP CONSTRAINT job_status_fkey;
ALTER TABLE job_result
	DROP CONSTRAINT job_result_agent_fkey,
	DROP CONSTRAINT job_result_job_fkey;

DROP TABLE hwinfo;
DROP TABLE job;
DROP TABLE job_agent;
DROP TABLE job_status;
DROP TABLE job_result;

ALTER TABLE server RENAME COLUMN cdn_id TO cdn;
ALTER TABLE deliveryservice RENAME COLUMN cdn_id TO cdn;
ALTER TABLE deliveryservice_tmuser RENAME COLUMN tm_user_id TO tm_user;
ALTER TABLE cachegroup RENAME COLUMN secondary_parent_cachegroup_id TO secondary_parent_cachegroup;
ALTER TABLE cachegroup RENAME COLUMN parent_cachegroup_id TO parent_cachegroup;

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back


