-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE TABLE crconfig_snapshots (
	cdn text NOT NULL REFERENCES cdns (name),
	snapshot text NOT NULL,
	created_at timestamp without time zone DEFAULT now() NOT NULL,
	PRIMARY KEY (cdn, created_at)
);
ALTER TABLE crconfig_snapshots OWNER TO touser;

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
