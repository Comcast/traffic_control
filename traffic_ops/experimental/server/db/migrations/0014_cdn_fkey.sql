
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied

ALTER TABLE deliveryservices
	DROP CONSTRAINT deliveryservice_cdn_id_fkey;
ALTER TABLE deliveryservices
	RENAME COLUMN cdn TO cdn_id;

ALTER TABLE deliveryservices
	ADD COLUMN cdn character varying(45);
UPDATE deliveryservices
	SET cdn = cdns.name FROM cdns WHERE cdns.id = cdn_id;
ALTER TABLE deliveryservices
	DROP COLUMN cdn_id,
	ADD CONSTRAINT deliveryservice_cdn_fkey FOREIGN KEY (cdn) REFERENCES cdns(name);

ALTER TABLE servers
	DROP CONSTRAINT server_cdn_id_fkey;
ALTER TABLE servers
	RENAME COLUMN cdn TO cdn_id;

ALTER TABLE servers
	ADD COLUMN cdn character varying(45);
UPDATE servers
	SET cdn = cdns.name FROM cdns WHERE cdns.id = cdn_id;
ALTER TABLE servers
	DROP COLUMN cdn_id,
	ADD CONSTRAINT server_cdn_fkey FOREIGN KEY (cdn) REFERENCES cdns(name);

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
