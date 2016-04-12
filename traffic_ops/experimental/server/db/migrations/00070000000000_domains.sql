
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied

CREATE TABLE domains (
    name text NOT NULL,
    cdn text NOT NULL,
    dnssec boolean NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);
ALTER TABLE domains OWNER TO touser;

ALTER TABLE cdns
	ALTER dnssec_enabled DROP DEFAULT,
	ALTER dnssec_enabled TYPE boolean
		USING CASE WHEN dnssec_enabled=0 THEN FALSE ELSE TRUE END;
INSERT INTO domains (cdn, dnssec)
	SELECT name, dnssec_enabled FROM cdns;
ALTER TABLE cdns
	DROP COLUMN dnssec_enabled;

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
