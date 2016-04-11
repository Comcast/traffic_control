
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE region
	DROP CONSTRAINT region_division_fkey,
	ADD COLUMN division_name CHARACTER VARYING(45);
UPDATE region
	SET division_name = division.name
	FROM division
	WHERE division.id = region.division;
ALTER TABLE division
	DROP CONSTRAINT division_pkey,
	ADD CONSTRAINT division_pkey PRIMARY KEY (name),
	DROP COLUMN id;
ALTER TABLE region
	ADD CONSTRAINT region_division_fkey
	FOREIGN KEY (region_division_fkey) REFERENCES division(name);


-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
