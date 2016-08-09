
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE asns
	DROP CONSTRAINT asn_pkey,
	ADD CONSTRAINT asns_asn_pkey PRIMARY KEY (asn),
	DROP COLUMN id;

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
