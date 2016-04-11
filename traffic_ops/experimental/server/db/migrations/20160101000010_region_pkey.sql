
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE phys_location
	DROP CONSTRAINT phys_location_region_fkey,
	ADD COLUMN region_name CHARACTER VARYING(45);
UPDATE phys_location
	SET region_name = region.name FROM region WHERE region.id = phys_location.region;
ALTER TABLE region
	DROP CONSTRAINT region_pkey,
	ADD CONSTRAINT region_pkey PRIMARY KEY (name),
	DROP COLUMN id;
ALTER TABLE phys_location
	DROP COLUMN region;
ALTER TABLE phys_location
	RENAME COLUMN region_name TO region;
ALTER TABLE phys_location
	ADD CONSTRAINT phys_location_region_fkey FOREIGN KEY (region) REFERENCES region(name);


-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
