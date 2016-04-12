
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE regions
	DROP CONSTRAINT region_division_fkey,
	ADD COLUMN division_name CHARACTER VARYING(45);
UPDATE regions
	SET division_name = divisions.name FROM divisions WHERE divisions.id = regions.division;
ALTER TABLE divisions
	DROP CONSTRAINT division_pkey,
	ADD CONSTRAINT division_pkey PRIMARY KEY (name),
	DROP COLUMN id;
ALTER TABLE regions
	DROP COLUMN division;
ALTER TABLE regions
	RENAME COLUMN division_name TO division;
ALTER TABLE regions
	ADD CONSTRAINT region_division_fkey FOREIGN KEY (division) REFERENCES divisions(name);


-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
