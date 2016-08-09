
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
CREATE DOMAIN port AS integer
        CONSTRAINT port_check CHECK (((VALUE >= 0) AND (VALUE <= 65535)));

ALTER DOMAIN port OWNER TO touser;

ALTER TABLE servers
	ALTER COLUMN ip_address type inet using ip_address::inet,
	ALTER COLUMN ip_gateway type inet using ip_gateway::inet,
	ALTER COLUMN ip6_address type inet using ip6_address::inet,
	ALTER COLUMN ip6_gateway type inet using ip6_gateway::inet,

	ALTER COLUMN mgmt_ip_address type inet using mgmt_ip_address::inet,
	ALTER COLUMN mgmt_ip_gateway type inet using mgmt_ip_gateway::inet,
	ALTER COLUMN ilo_ip_address type inet using ilo_ip_address::inet,
	ALTER COLUMN ilo_ip_gateway type inet using ilo_ip_gateway::inet;

ALTER TABLE deliveryservices
	ALTER COLUMN dns_bypass_ip type inet using dns_bypass_ip::inet,
	ALTER COLUMN dns_bypass_ip6 type inet using dns_bypass_ip6::inet;

ALTER TABLE federation_resolvers
	ALTER COLUMN ip_address type inet using ip_address::inet;

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back
