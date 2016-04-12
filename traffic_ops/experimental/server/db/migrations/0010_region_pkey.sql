
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE phys_locations
	DROP CONSTRAINT phys_location_region_fkey,
	ADD COLUMN region_name CHARACTER VARYING(45);
UPDATE phys_locations
	SET region_name = regions.name FROM regions WHERE regions.id = phys_locations.region;
ALTER TABLE regions
	DROP CONSTRAINT region_pkey,
	ADD CONSTRAINT region_pkey PRIMARY KEY (name),
	DROP COLUMN id;
ALTER TABLE phys_locations
	DROP COLUMN region;
ALTER TABLE phys_locations
	RENAME COLUMN region_name TO region;
ALTER TABLE phys_locations
	ADD CONSTRAINT phys_location_region_fkey FOREIGN KEY (region) REFERENCES regions(name);


-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
