--
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
ALTER TABLE asn RENAME TO asns;
ALTER TABLE cachegroup RENAME TO cachegroups;
ALTER TABLE cachegroup_parameter RENAME TO cachegroups_parameters;
ALTER TABLE cdn RENAME TO cdns;
ALTER TABLE parameter RENAME TO parameters;
ALTER TABLE profile RENAME TO profiles;
ALTER TABLE profile_parameter RENAME TO profiles_parameters;
ALTER TABLE server RENAME TO servers;
ALTER TABLE deliveryservice RENAME TO deliveryservices;
ALTER TABLE deliveryservice_regex RENAME TO deliveryservices_regexes;
ALTER TABLE deliveryservice_server RENAME TO deliveryservices_servers;
ALTER TABLE regex RENAME TO regexes;
ALTER TABLE staticdnsentry RENAME TO staticdnsentries;
ALTER TABLE type RENAME TO types;
ALTER TABLE deliveryservice_tmuser RENAME TO deliveryservices_users;
ALTER TABLE division RENAME TO divisions;
ALTER TABLE to_extension RENAME TO extensions;
ALTER TABLE federation_resolver RENAME TO federation_resolvers;
ALTER TABLE federation_tmuser RENAME TO federation_users;
ALTER TABLE federation RENAME TO federations;
ALTER TABLE federation_deliveryservice RENAME TO federations_deliveryservices;
ALTER TABLE federation_federation_resolver RENAME TO federations_federation_resolvers;
ALTER TABLE phys_location RENAME TO phys_locations;
ALTER TABLE region RENAME TO regions;
ALTER TABLE role RENAME TO roles;
ALTER TABLE status RENAME TO statuses;
ALTER TABLE tm_user RENAME TO users;

-- rename last_updated column to created_at
-- +goose StatementBegin
DO $$DECLARE row record;
	BEGIN
	FOR row IN SELECT table_name FROM information_schema.columns WHERE table_schema = 'public' AND column_name = 'last_updated'
	LOOP
		EXECUTE 'ALTER TABLE public.' || quote_ident(row.table_name) || ' RENAME COLUMN last_updated TO created_at ';
	END LOOP;
END$$;
-- +goose StatementEnd


-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back


