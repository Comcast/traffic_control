
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
alter table deliveryservice add column `routing_name` varchar(1024) default NULL;

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back

