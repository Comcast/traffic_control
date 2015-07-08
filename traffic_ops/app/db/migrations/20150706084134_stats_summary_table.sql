-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE stats_summary
(
id int NOT NULL AUTO_INCREMENT,
cdn_name varchar(255) NOT NULL DEFAULT 'all',
deliveryservice_name varchar(255) NOT NULL,
stat_name varchar(255) NOT NULL,
stat_value float NOT NULL,
summary_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (id)
);
-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
