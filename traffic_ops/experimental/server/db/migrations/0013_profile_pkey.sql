
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE deliveryservices
	DROP CONSTRAINT deliveryservice_profile_fkey;
ALTER TABLE deliveryservices
	RENAME COLUMN profile TO profile_id;

ALTER TABLE deliveryservices
	ADD COLUMN profile character varying(45);
UPDATE deliveryservices
	SET profile = profiles.name FROM profiles WHERE profiles.id = profile_id;
ALTER TABLE deliveryservices
	DROP COLUMN profile_id,
	ADD CONSTRAINT deliveryservice_profile_fkey FOREIGN KEY (profile) REFERENCES profiles(name);

ALTER TABLE profiles_parameters
	DROP CONSTRAINT profile_parameter_profile_fkey;
ALTER TABLE profiles_parameters
	RENAME COLUMN profile TO profile_id;
ALTER TABLE profiles_parameters
	ADD COLUMN profile character varying(45);
UPDATE profiles_parameters
	SET profile = profiles.name FROM profiles WHERE profiles.id = profiles_parameters.profile_id;
ALTER TABLE profiles_parameters
	DROP COLUMN profile_id,
	ADD CONSTRAINT profiles_parameters_profile_fkey FOREIGN KEY (profile) REFERENCES profiles(name);

ALTER TABLE servers
	DROP CONSTRAINT server_profile_fkey;
ALTER TABLE servers
	RENAME COLUMN profile TO profile_id;
ALTER TABLE servers
	ADD COLUMN profile character varying(45);
UPDATE servers
	SET profile = profiles.name FROM profiles WHERE profiles.id = servers.profile_id;
ALTER TABLE servers
	DROP COLUMN profile_id,
	ADD CONSTRAINT server_profile_fkey FOREIGN KEY (profile) REFERENCES profiles(name);


ALTER TABLE profiles
	DROP COLUMN id,
	ADD CONSTRAINT profiles_pkey PRIMARY KEY (name);

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
