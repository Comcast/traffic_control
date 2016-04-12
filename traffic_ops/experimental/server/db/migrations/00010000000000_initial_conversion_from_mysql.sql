--
-- +goose Up
-- SQL in section 'Up' is executed when this migration is applied
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

CREATE TABLE asn (
    id integer NOT NULL,
    asn integer NOT NULL,
    cachegroup integer DEFAULT 0 NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE asn OWNER TO touser;

CREATE SEQUENCE asn_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE asn_id_seq OWNER TO touser;

ALTER SEQUENCE asn_id_seq OWNED BY asn.id;

CREATE TABLE cachegroup (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    short_name character varying(255) NOT NULL,
    latitude double precision,
    longitude double precision,
    parent_cachegroup_id integer,
    secondary_parent_cachegroup_id integer,
    type integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE cachegroup OWNER TO touser;

CREATE SEQUENCE cachegroup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE cachegroup_id_seq OWNER TO touser;

ALTER SEQUENCE cachegroup_id_seq OWNED BY cachegroup.id;

CREATE TABLE cachegroup_parameter (
    cachegroup integer DEFAULT 0 NOT NULL,
    parameter integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE cachegroup_parameter OWNER TO touser;

CREATE TABLE cdn (
    id integer NOT NULL,
    name character varying(127),
    last_updated timestamp without time zone DEFAULT now() NOT NULL,
    dnssec_enabled smallint DEFAULT 0
);

ALTER TABLE cdn OWNER TO touser;

CREATE SEQUENCE cdn_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE cdn_id_seq OWNER TO touser;

ALTER SEQUENCE cdn_id_seq OWNED BY cdn.id;

CREATE TABLE deliveryservice (
    id integer NOT NULL,
    xml_id character varying(48) NOT NULL,
    active smallint NOT NULL,
    dscp integer NOT NULL,
    signed smallint,
    qstring_ignore smallint,
    geo_limit smallint DEFAULT 0,
    http_bypass_fqdn character varying(255),
    dns_bypass_ip character varying(45),
    dns_bypass_ip6 character varying(45),
    dns_bypass_ttl integer,
    org_server_fqdn character varying(255),
    type integer NOT NULL,
    profile integer NOT NULL,
    cdn_id integer NOT NULL,
    ccr_dns_ttl integer,
    global_max_mbps integer,
    global_max_tps integer,
    long_desc character varying(1024),
    long_desc_1 character varying(1024),
    long_desc_2 character varying(1024),
    max_dns_answers integer DEFAULT 0,
    info_url character varying(255),
    miss_lat double precision,
    miss_long double precision,
    check_path character varying(255),
    last_updated timestamp without time zone DEFAULT now(),
    protocol smallint DEFAULT 0,
    ssl_key_version integer DEFAULT 0,
    ipv6_routing_enabled smallint,
    range_request_handling smallint DEFAULT 0,
    edge_header_rewrite character varying(2048),
    origin_shield character varying(1024),
    mid_header_rewrite character varying(2048),
    regex_remap character varying(1024),
    cacheurl character varying(1024),
    remap_text character varying(2048),
    multi_site_origin smallint,
    display_name character varying(48) NOT NULL,
    tr_response_headers character varying(1024),
    initial_dispersion integer DEFAULT 1,
    dns_bypass_cname character varying(255),
    tr_request_headers character varying(1024)
);

ALTER TABLE deliveryservice OWNER TO touser;

CREATE SEQUENCE deliveryservice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE deliveryservice_id_seq OWNER TO touser;

ALTER SEQUENCE deliveryservice_id_seq OWNED BY deliveryservice.id;

CREATE TABLE deliveryservice_regex (
    deliveryservice integer NOT NULL,
    regex integer NOT NULL,
    set_number integer DEFAULT 0
);

ALTER TABLE deliveryservice_regex OWNER TO touser;

CREATE TABLE deliveryservice_server (
    deliveryservice integer NOT NULL,
    server integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE deliveryservice_server OWNER TO touser;

CREATE TABLE deliveryservice_tmuser (
    deliveryservice integer NOT NULL,
    tm_user_id integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE deliveryservice_tmuser OWNER TO touser;

CREATE TABLE division (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE division OWNER TO touser;

CREATE SEQUENCE division_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE division_id_seq OWNER TO touser;

ALTER SEQUENCE division_id_seq OWNED BY division.id;

CREATE TABLE federation (
    id integer NOT NULL,
    cname character varying(1024) NOT NULL,
    description character varying(1024),
    ttl integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE federation OWNER TO touser;

CREATE TABLE federation_deliveryservice (
    federation integer NOT NULL,
    deliveryservice integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE federation_deliveryservice OWNER TO touser;

CREATE TABLE federation_federation_resolver (
    federation integer NOT NULL,
    federation_resolver integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE federation_federation_resolver OWNER TO touser;

CREATE SEQUENCE federation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE federation_id_seq OWNER TO touser;

ALTER SEQUENCE federation_id_seq OWNED BY federation.id;

CREATE TABLE federation_resolver (
    id integer NOT NULL,
    ip_address character varying(50) NOT NULL,
    type integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE federation_resolver OWNER TO touser;

CREATE SEQUENCE federation_resolver_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE federation_resolver_id_seq OWNER TO touser;

ALTER SEQUENCE federation_resolver_id_seq OWNED BY federation_resolver.id;

CREATE TABLE federation_tmuser (
    federation integer NOT NULL,
    tm_user integer NOT NULL,
    role integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE federation_tmuser OWNER TO touser;

CREATE TABLE hwinfo (
    id integer NOT NULL,
    serverid integer NOT NULL,
    description character varying(256) NOT NULL,
    val character varying(256) NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE hwinfo OWNER TO touser;

CREATE SEQUENCE hwinfo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE hwinfo_id_seq OWNER TO touser;

ALTER SEQUENCE hwinfo_id_seq OWNED BY hwinfo.id;

CREATE TABLE job (
    id integer NOT NULL,
    agent integer,
    object_type character varying(48),
    object_name character varying(256),
    keyword character varying(48) NOT NULL,
    parameters character varying(256),
    asset_url character varying(512) NOT NULL,
    asset_type character varying(48) NOT NULL,
    status integer NOT NULL,
    start_time timestamp without time zone NOT NULL,
    entered_time timestamp without time zone NOT NULL,
    job_user integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now(),
    job_deliveryservice integer
);

ALTER TABLE job OWNER TO touser;

CREATE TABLE job_agent (
    id integer NOT NULL,
    name character varying(128),
    description character varying(512),
    active integer DEFAULT 0 NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE job_agent OWNER TO touser;

CREATE SEQUENCE job_agent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE job_agent_id_seq OWNER TO touser;

ALTER SEQUENCE job_agent_id_seq OWNED BY job_agent.id;

CREATE SEQUENCE job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE job_id_seq OWNER TO touser;

ALTER SEQUENCE job_id_seq OWNED BY job.id;

CREATE TABLE job_result (
    id integer NOT NULL,
    job integer NOT NULL,
    agent integer NOT NULL,
    result character varying(48) NOT NULL,
    description character varying(512),
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE job_result OWNER TO touser;

CREATE SEQUENCE job_result_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE job_result_id_seq OWNER TO touser;

ALTER SEQUENCE job_result_id_seq OWNED BY job_result.id;

CREATE TABLE job_status (
    id integer NOT NULL,
    name character varying(48),
    description character varying(256),
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE job_status OWNER TO touser;

CREATE SEQUENCE job_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE job_status_id_seq OWNER TO touser;

ALTER SEQUENCE job_status_id_seq OWNED BY job_status.id;

CREATE TABLE log (
    id integer NOT NULL,
    level character varying(45),
    message character varying(1024) NOT NULL,
    tm_user integer NOT NULL,
    ticketnum character varying(64),
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE log OWNER TO touser;

CREATE SEQUENCE log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE log_id_seq OWNER TO touser;

ALTER SEQUENCE log_id_seq OWNED BY log.id;

CREATE TABLE parameter (
    id integer NOT NULL,
    name character varying(1024) NOT NULL,
    config_file character varying(45) NOT NULL,
    value character varying(1024),
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE parameter OWNER TO touser;

CREATE SEQUENCE parameter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE parameter_id_seq OWNER TO touser;

ALTER SEQUENCE parameter_id_seq OWNED BY parameter.id;

CREATE TABLE phys_location (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    short_name character varying(12) NOT NULL,
    address character varying(128),
    city character varying(128),
    state character varying(2),
    zip character varying(5),
    poc character varying(128),
    phone character varying(45),
    email character varying(128),
    comments character varying(256),
    region integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE phys_location OWNER TO touser;

CREATE SEQUENCE phys_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE phys_location_id_seq OWNER TO touser;

ALTER SEQUENCE phys_location_id_seq OWNED BY phys_location.id;

CREATE TABLE profile (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(256),
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE profile OWNER TO touser;

CREATE SEQUENCE profile_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE profile_id_seq OWNER TO touser;

ALTER SEQUENCE profile_id_seq OWNED BY profile.id;

CREATE TABLE profile_parameter (
    profile integer NOT NULL,
    parameter integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE profile_parameter OWNER TO touser;

CREATE TABLE regex (
    id integer NOT NULL,
    pattern character varying(255),
    type integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE regex OWNER TO touser;

CREATE SEQUENCE regex_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE regex_id_seq OWNER TO touser;

ALTER SEQUENCE regex_id_seq OWNED BY regex.id;

CREATE TABLE region (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    division integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE region OWNER TO touser;

CREATE SEQUENCE region_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE region_id_seq OWNER TO touser;

ALTER SEQUENCE region_id_seq OWNED BY region.id;

CREATE TABLE role (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(128),
    priv_level integer NOT NULL
);

ALTER TABLE role OWNER TO touser;

CREATE SEQUENCE role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE role_id_seq OWNER TO touser;

ALTER SEQUENCE role_id_seq OWNED BY role.id;

CREATE TABLE server (
    id integer NOT NULL,
    host_name character varying(45) NOT NULL,
    domain_name character varying(45) NOT NULL,
    tcp_port bigint,
    xmpp_id character varying(256),
    xmpp_passwd character varying(45),
    interface_name character varying(45) NOT NULL,
    ip_address character varying(45) NOT NULL,
    ip_netmask character varying(45) NOT NULL,
    ip_gateway character varying(45) NOT NULL,
    ip6_address character varying(50),
    ip6_gateway character varying(50),
    interface_mtu integer DEFAULT 9000 NOT NULL,
    phys_location integer NOT NULL,
    rack character varying(64),
    cachegroup integer DEFAULT 0 NOT NULL,
    type integer NOT NULL,
    status integer NOT NULL,
    upd_pending smallint DEFAULT 0 NOT NULL,
    profile integer NOT NULL,
    cdn_id integer NOT NULL,
    mgmt_ip_address character varying(45),
    mgmt_ip_netmask character varying(45),
    mgmt_ip_gateway character varying(45),
    ilo_ip_address character varying(45),
    ilo_ip_netmask character varying(45),
    ilo_ip_gateway character varying(45),
    ilo_username character varying(45),
    ilo_password character varying(45),
    router_host_name character varying(256),
    router_port_name character varying(256),
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE server OWNER TO touser;

CREATE SEQUENCE server_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE server_id_seq OWNER TO touser;

ALTER SEQUENCE server_id_seq OWNED BY server.id;

CREATE TABLE servercheck (
    id integer NOT NULL,
    server integer NOT NULL,
    aa integer,
    ab integer,
    ac integer,
    ad integer,
    ae integer,
    af integer,
    ag integer,
    ah integer,
    ai integer,
    aj integer,
    ak integer,
    al integer,
    am integer,
    an integer,
    ao integer,
    ap integer,
    aq integer,
    ar integer,
    "as" integer,
    at integer,
    au integer,
    av integer,
    aw integer,
    ax integer,
    ay integer,
    az integer,
    ba integer,
    bb integer,
    bc integer,
    bd integer,
    be integer,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE servercheck OWNER TO touser;

CREATE SEQUENCE servercheck_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE servercheck_id_seq OWNER TO touser;

ALTER SEQUENCE servercheck_id_seq OWNED BY servercheck.id;

CREATE TABLE staticdnsentry (
    id integer NOT NULL,
    host character varying(45) NOT NULL,
    address character varying(45) NOT NULL,
    type integer NOT NULL,
    ttl integer DEFAULT 3600 NOT NULL,
    deliveryservice integer NOT NULL,
    cachegroup integer,
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE staticdnsentry OWNER TO touser;

CREATE SEQUENCE staticdnsentry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE staticdnsentry_id_seq OWNER TO touser;

ALTER SEQUENCE staticdnsentry_id_seq OWNED BY staticdnsentry.id;

CREATE TABLE stats_summary (
    id integer NOT NULL,
    cdn_name character varying(255) DEFAULT 'all'::character varying NOT NULL,
    deliveryservice_name character varying(255) NOT NULL,
    stat_name character varying(255) NOT NULL,
    stat_value real NOT NULL,
    summary_time timestamp without time zone DEFAULT now() NOT NULL,
    stat_date date
);

ALTER TABLE stats_summary OWNER TO touser;

CREATE SEQUENCE stats_summary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE stats_summary_id_seq OWNER TO touser;

ALTER SEQUENCE stats_summary_id_seq OWNED BY stats_summary.id;

CREATE TABLE status (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(256),
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE status OWNER TO touser;

CREATE SEQUENCE status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE status_id_seq OWNER TO touser;

ALTER SEQUENCE status_id_seq OWNED BY status.id;

CREATE TABLE tm_user (
    id integer NOT NULL,
    username character varying(128),
    role integer,
    uid integer,
    gid integer,
    local_passwd character varying(40),
    confirm_local_passwd character varying(40),
    last_updated timestamp without time zone DEFAULT now(),
    company character varying(256),
    email character varying(128),
    full_name character varying(256),
    new_user smallint DEFAULT 1 NOT NULL,
    address_line1 character varying(256),
    address_line2 character varying(256),
    city character varying(128),
    state_or_province character varying(128),
    phone_number character varying(25),
    postal_code character varying(11),
    country character varying(256),
    token character varying(50),
    registration_sent timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL
);

ALTER TABLE tm_user OWNER TO touser;

CREATE SEQUENCE tm_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE tm_user_id_seq OWNER TO touser;

ALTER SEQUENCE tm_user_id_seq OWNED BY tm_user.id;

CREATE TABLE to_extension (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    version character varying(45),
    info_url character varying(45),
    script_file character varying(45),
    isactive smallint NOT NULL,
    additional_config_json character varying(4096),
    description character varying(4096),
    servercheck_short_name character varying(8),
    servercheck_column_name character varying(10),
    type integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE to_extension OWNER TO touser;

CREATE SEQUENCE to_extension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE to_extension_id_seq OWNER TO touser;

ALTER SEQUENCE to_extension_id_seq OWNED BY to_extension.id;

CREATE TABLE type (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(256),
    use_in_table character varying(45),
    last_updated timestamp without time zone DEFAULT now()
);

ALTER TABLE type OWNER TO touser;

CREATE SEQUENCE type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE type_id_seq OWNER TO touser;

ALTER SEQUENCE type_id_seq OWNED BY type.id;

ALTER TABLE ONLY asn ALTER COLUMN id SET DEFAULT nextval('asn_id_seq'::regclass);

ALTER TABLE ONLY cachegroup ALTER COLUMN id SET DEFAULT nextval('cachegroup_id_seq'::regclass);

ALTER TABLE ONLY cdn ALTER COLUMN id SET DEFAULT nextval('cdn_id_seq'::regclass);

ALTER TABLE ONLY deliveryservice ALTER COLUMN id SET DEFAULT nextval('deliveryservice_id_seq'::regclass);

ALTER TABLE ONLY division ALTER COLUMN id SET DEFAULT nextval('division_id_seq'::regclass);

ALTER TABLE ONLY federation ALTER COLUMN id SET DEFAULT nextval('federation_id_seq'::regclass);

ALTER TABLE ONLY federation_resolver ALTER COLUMN id SET DEFAULT nextval('federation_resolver_id_seq'::regclass);

ALTER TABLE ONLY hwinfo ALTER COLUMN id SET DEFAULT nextval('hwinfo_id_seq'::regclass);

ALTER TABLE ONLY job ALTER COLUMN id SET DEFAULT nextval('job_id_seq'::regclass);

ALTER TABLE ONLY job_agent ALTER COLUMN id SET DEFAULT nextval('job_agent_id_seq'::regclass);

ALTER TABLE ONLY job_result ALTER COLUMN id SET DEFAULT nextval('job_result_id_seq'::regclass);

ALTER TABLE ONLY job_status ALTER COLUMN id SET DEFAULT nextval('job_status_id_seq'::regclass);

ALTER TABLE ONLY log ALTER COLUMN id SET DEFAULT nextval('log_id_seq'::regclass);

ALTER TABLE ONLY parameter ALTER COLUMN id SET DEFAULT nextval('parameter_id_seq'::regclass);

ALTER TABLE ONLY phys_location ALTER COLUMN id SET DEFAULT nextval('phys_location_id_seq'::regclass);

ALTER TABLE ONLY profile ALTER COLUMN id SET DEFAULT nextval('profile_id_seq'::regclass);

ALTER TABLE ONLY regex ALTER COLUMN id SET DEFAULT nextval('regex_id_seq'::regclass);

ALTER TABLE ONLY region ALTER COLUMN id SET DEFAULT nextval('region_id_seq'::regclass);

ALTER TABLE ONLY role ALTER COLUMN id SET DEFAULT nextval('role_id_seq'::regclass);

ALTER TABLE ONLY server ALTER COLUMN id SET DEFAULT nextval('server_id_seq'::regclass);

ALTER TABLE ONLY servercheck ALTER COLUMN id SET DEFAULT nextval('servercheck_id_seq'::regclass);

ALTER TABLE ONLY staticdnsentry ALTER COLUMN id SET DEFAULT nextval('staticdnsentry_id_seq'::regclass);

ALTER TABLE ONLY stats_summary ALTER COLUMN id SET DEFAULT nextval('stats_summary_id_seq'::regclass);

ALTER TABLE ONLY status ALTER COLUMN id SET DEFAULT nextval('status_id_seq'::regclass);

ALTER TABLE ONLY tm_user ALTER COLUMN id SET DEFAULT nextval('tm_user_id_seq'::regclass);

ALTER TABLE ONLY to_extension ALTER COLUMN id SET DEFAULT nextval('to_extension_id_seq'::regclass);

ALTER TABLE ONLY type ALTER COLUMN id SET DEFAULT nextval('type_id_seq'::regclass);

ALTER TABLE ONLY asn
    ADD CONSTRAINT asn_pkey PRIMARY KEY (id, cachegroup);

ALTER TABLE ONLY cachegroup_parameter
    ADD CONSTRAINT cachegroup_parameter_pkey PRIMARY KEY (cachegroup, parameter);

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT cachegroup_pkey PRIMARY KEY (id, type);

ALTER TABLE ONLY cdn
    ADD CONSTRAINT cdn_pkey PRIMARY KEY (id);

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT deliveryservice_pkey PRIMARY KEY (id, type);

ALTER TABLE ONLY deliveryservice_regex
    ADD CONSTRAINT deliveryservice_regex_pkey PRIMARY KEY (deliveryservice, regex);

ALTER TABLE ONLY deliveryservice_server
    ADD CONSTRAINT deliveryservice_server_pkey PRIMARY KEY (deliveryservice, server);

ALTER TABLE ONLY deliveryservice_tmuser
    ADD CONSTRAINT deliveryservice_tmuser_pkey PRIMARY KEY (deliveryservice, tm_user_id);

ALTER TABLE ONLY division
    ADD CONSTRAINT division_pkey PRIMARY KEY (id);

ALTER TABLE ONLY federation_deliveryservice
    ADD CONSTRAINT federation_deliveryservice_pkey PRIMARY KEY (federation, deliveryservice);

ALTER TABLE ONLY federation_federation_resolver
    ADD CONSTRAINT federation_federation_resolver_pkey PRIMARY KEY (federation, federation_resolver);

ALTER TABLE ONLY federation
    ADD CONSTRAINT federation_pkey PRIMARY KEY (id);

ALTER TABLE ONLY federation_resolver
    ADD CONSTRAINT federation_resolver_pkey PRIMARY KEY (id);

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT federation_tmuser_pkey PRIMARY KEY (federation, tm_user);

ALTER TABLE ONLY hwinfo
    ADD CONSTRAINT hwinfo_pkey PRIMARY KEY (id);

ALTER TABLE ONLY job_agent
    ADD CONSTRAINT job_agent_pkey PRIMARY KEY (id);

ALTER TABLE ONLY job
    ADD CONSTRAINT job_pkey PRIMARY KEY (id);

ALTER TABLE ONLY job_result
    ADD CONSTRAINT job_result_pkey PRIMARY KEY (id);

ALTER TABLE ONLY job_status
    ADD CONSTRAINT job_status_pkey PRIMARY KEY (id);

ALTER TABLE ONLY log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id, tm_user);

ALTER TABLE ONLY parameter
    ADD CONSTRAINT parameter_pkey PRIMARY KEY (id);

ALTER TABLE ONLY phys_location
    ADD CONSTRAINT phys_location_pkey PRIMARY KEY (id);

ALTER TABLE ONLY profile_parameter
    ADD CONSTRAINT profile_parameter_pkey PRIMARY KEY (profile, parameter);

ALTER TABLE ONLY profile
    ADD CONSTRAINT profile_pkey PRIMARY KEY (id);

ALTER TABLE ONLY regex
    ADD CONSTRAINT regex_pkey PRIMARY KEY (id, type);

ALTER TABLE ONLY region
    ADD CONSTRAINT region_pkey PRIMARY KEY (id);

ALTER TABLE ONLY role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);

ALTER TABLE ONLY server
    ADD CONSTRAINT server_pkey PRIMARY KEY (id, cachegroup, type, status, profile);

ALTER TABLE ONLY servercheck
    ADD CONSTRAINT servercheck_pkey PRIMARY KEY (id, server);

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT staticdnsentry_pkey PRIMARY KEY (id);

ALTER TABLE ONLY stats_summary
    ADD CONSTRAINT stats_summary_pkey PRIMARY KEY (id);

ALTER TABLE ONLY status
    ADD CONSTRAINT status_pkey PRIMARY KEY (id);

ALTER TABLE ONLY tm_user
    ADD CONSTRAINT tm_user_pkey PRIMARY KEY (id);

ALTER TABLE ONLY to_extension
    ADD CONSTRAINT to_extension_pkey PRIMARY KEY (id);

ALTER TABLE ONLY type
    ADD CONSTRAINT type_pkey PRIMARY KEY (id);

CREATE INDEX test_schema_asn_cachegroup1_idx ON asn USING btree (cachegroup);

CREATE UNIQUE INDEX test_schema_asn_id0_idx ON asn USING btree (id);

CREATE UNIQUE INDEX test_schema_cachegroup_id0_idx ON cachegroup USING btree (id);

CREATE UNIQUE INDEX test_schema_cachegroup_name2_idx ON cachegroup USING btree (name);

CREATE INDEX test_schema_cachegroup_parameter_parameter0_idx ON cachegroup_parameter USING btree (parameter);

CREATE INDEX test_schema_cachegroup_parent_cachegroup_id3_idx ON cachegroup USING btree (parent_cachegroup_id);

CREATE INDEX test_schema_cachegroup_secondary_parent_cachegroup_id5_idx ON cachegroup USING btree (secondary_parent_cachegroup_id);

CREATE UNIQUE INDEX test_schema_cachegroup_short_name1_idx ON cachegroup USING btree (short_name);

CREATE INDEX test_schema_cachegroup_type4_idx ON cachegroup USING btree (type);

CREATE UNIQUE INDEX test_schema_cdn_name0_idx ON cdn USING btree (name);

CREATE INDEX test_schema_deliveryservice_cdn_id4_idx ON deliveryservice USING btree (cdn_id);

CREATE UNIQUE INDEX test_schema_deliveryservice_id1_idx ON deliveryservice USING btree (id);

CREATE INDEX test_schema_deliveryservice_profile3_idx ON deliveryservice USING btree (profile);

CREATE INDEX test_schema_deliveryservice_regex_regex0_idx ON deliveryservice_regex USING btree (regex);

CREATE INDEX test_schema_deliveryservice_server_server0_idx ON deliveryservice_server USING btree (server);

CREATE INDEX test_schema_deliveryservice_tmuser_tm_user_id0_idx ON deliveryservice_tmuser USING btree (tm_user_id);

CREATE INDEX test_schema_deliveryservice_type2_idx ON deliveryservice USING btree (type);

CREATE UNIQUE INDEX test_schema_deliveryservice_xml_id0_idx ON deliveryservice USING btree (xml_id);

CREATE UNIQUE INDEX test_schema_division_name0_idx ON division USING btree (name);

CREATE INDEX test_schema_federation_deliveryservice_deliveryservice0_idx ON federation_deliveryservice USING btree (deliveryservice);

CREATE INDEX test_schema_federation_federation_resolver_federation0_idx ON federation_federation_resolver USING btree (federation);

CREATE INDEX test_schema_federation_federation_resolver_federation_resolver1 ON federation_federation_resolver USING btree (federation_resolver);

CREATE UNIQUE INDEX test_schema_federation_resolver_ip_address0_idx ON federation_resolver USING btree (ip_address);

CREATE INDEX test_schema_federation_resolver_type1_idx ON federation_resolver USING btree (type);

CREATE INDEX test_schema_federation_tmuser_federation0_idx ON federation_tmuser USING btree (federation);

CREATE INDEX test_schema_federation_tmuser_role2_idx ON federation_tmuser USING btree (role);

CREATE INDEX test_schema_federation_tmuser_tm_user1_idx ON federation_tmuser USING btree (tm_user);

CREATE UNIQUE INDEX test_schema_goose_db_version_id0_idx ON goose_db_version USING btree (id);

CREATE UNIQUE INDEX test_schema_hwinfo_serverid0_idx ON hwinfo USING btree (serverid, description);

CREATE INDEX test_schema_hwinfo_serverid1_idx ON hwinfo USING btree (serverid);

CREATE INDEX test_schema_job_agent0_idx ON job USING btree (agent);

CREATE INDEX test_schema_job_job_deliveryservice3_idx ON job USING btree (job_deliveryservice);

CREATE INDEX test_schema_job_job_user2_idx ON job USING btree (job_user);

CREATE INDEX test_schema_job_result_agent1_idx ON job_result USING btree (agent);

CREATE INDEX test_schema_job_result_job0_idx ON job_result USING btree (job);

CREATE INDEX test_schema_job_status1_idx ON job USING btree (status);

CREATE INDEX test_schema_log_tm_user0_idx ON log USING btree (tm_user);

CREATE INDEX test_schema_parameter_name0_idx ON parameter USING btree (name, value);

CREATE UNIQUE INDEX test_schema_phys_location_name0_idx ON phys_location USING btree (name);

CREATE INDEX test_schema_phys_location_region2_idx ON phys_location USING btree (region);

CREATE UNIQUE INDEX test_schema_phys_location_short_name1_idx ON phys_location USING btree (short_name);

CREATE UNIQUE INDEX test_schema_profile_name0_idx ON profile USING btree (name);

CREATE INDEX test_schema_profile_parameter_parameter1_idx ON profile_parameter USING btree (parameter);

CREATE INDEX test_schema_profile_parameter_profile0_idx ON profile_parameter USING btree (profile);

CREATE UNIQUE INDEX test_schema_regex_id0_idx ON regex USING btree (id);

CREATE INDEX test_schema_regex_type1_idx ON regex USING btree (type);

CREATE INDEX test_schema_region_division1_idx ON region USING btree (division);

CREATE UNIQUE INDEX test_schema_region_name0_idx ON region USING btree (name);

CREATE INDEX test_schema_server_cachegroup8_idx ON server USING btree (cachegroup);

CREATE INDEX test_schema_server_cdn_id9_idx ON server USING btree (cdn_id);

CREATE UNIQUE INDEX test_schema_server_host_name2_idx ON server USING btree (host_name);

CREATE UNIQUE INDEX test_schema_server_id1_idx ON server USING btree (id);

CREATE UNIQUE INDEX test_schema_server_ip6_address3_idx ON server USING btree (ip6_address);

CREATE UNIQUE INDEX test_schema_server_ip_address0_idx ON server USING btree (ip_address);

CREATE INDEX test_schema_server_phys_location7_idx ON server USING btree (phys_location);

CREATE INDEX test_schema_server_profile6_idx ON server USING btree (profile);

CREATE INDEX test_schema_server_status5_idx ON server USING btree (status);

CREATE INDEX test_schema_server_type4_idx ON server USING btree (type);

CREATE UNIQUE INDEX test_schema_servercheck_id1_idx ON servercheck USING btree (id);

CREATE UNIQUE INDEX test_schema_servercheck_server0_idx ON servercheck USING btree (server);

CREATE INDEX test_schema_servercheck_server2_idx ON servercheck USING btree (server);

CREATE INDEX test_schema_staticdnsentry_cachegroup3_idx ON staticdnsentry USING btree (cachegroup);

CREATE INDEX test_schema_staticdnsentry_deliveryservice2_idx ON staticdnsentry USING btree (deliveryservice);

CREATE UNIQUE INDEX test_schema_staticdnsentry_host0_idx ON staticdnsentry USING btree (host, address, deliveryservice, cachegroup);

CREATE INDEX test_schema_staticdnsentry_type1_idx ON staticdnsentry USING btree (type);

CREATE UNIQUE INDEX test_schema_tm_user_email1_idx ON tm_user USING btree (email);

CREATE INDEX test_schema_tm_user_role2_idx ON tm_user USING btree (role);

CREATE UNIQUE INDEX test_schema_tm_user_username0_idx ON tm_user USING btree (username);

CREATE UNIQUE INDEX test_schema_to_extension_id0_idx ON to_extension USING btree (id);

CREATE INDEX test_schema_to_extension_type1_idx ON to_extension USING btree (type);

CREATE UNIQUE INDEX test_schema_type_name0_idx ON type USING btree (name);

ALTER TABLE ONLY asn
    ADD CONSTRAINT asn_cachegroup_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroup(id);

ALTER TABLE ONLY cachegroup_parameter
    ADD CONSTRAINT cachegroup_parameter_cachegroup_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroup(id) ON DELETE CASCADE;

ALTER TABLE ONLY cachegroup_parameter
    ADD CONSTRAINT cachegroup_parameter_parameter_fkey FOREIGN KEY (parameter) REFERENCES parameter(id) ON DELETE CASCADE;

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT cachegroup_parent_cachegroup_id_fkey FOREIGN KEY (parent_cachegroup_id) REFERENCES cachegroup(id);

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT cachegroup_secondary_parent_cachegroup_id_fkey FOREIGN KEY (secondary_parent_cachegroup_id) REFERENCES cachegroup(id);

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT cachegroup_type_fkey FOREIGN KEY (type) REFERENCES type(id);

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT deliveryservice_cdn_id_fkey FOREIGN KEY (cdn_id) REFERENCES cdn(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT deliveryservice_profile_fkey FOREIGN KEY (profile) REFERENCES profile(id);

ALTER TABLE ONLY deliveryservice_regex
    ADD CONSTRAINT deliveryservice_regex_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY deliveryservice_regex
    ADD CONSTRAINT deliveryservice_regex_regex_fkey FOREIGN KEY (regex) REFERENCES regex(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY deliveryservice_server
    ADD CONSTRAINT deliveryservice_server_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY deliveryservice_server
    ADD CONSTRAINT deliveryservice_server_server_fkey FOREIGN KEY (server) REFERENCES server(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY deliveryservice_tmuser
    ADD CONSTRAINT deliveryservice_tmuser_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY deliveryservice_tmuser
    ADD CONSTRAINT deliveryservice_tmuser_tm_user_id_fkey FOREIGN KEY (tm_user_id) REFERENCES tm_user(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT deliveryservice_type_fkey FOREIGN KEY (type) REFERENCES type(id);

ALTER TABLE ONLY federation_deliveryservice
    ADD CONSTRAINT federation_deliveryservice_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY federation_deliveryservice
    ADD CONSTRAINT federation_deliveryservice_federation_fkey FOREIGN KEY (federation) REFERENCES federation(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY federation_federation_resolver
    ADD CONSTRAINT federation_federation_resolver_federation_fkey FOREIGN KEY (federation) REFERENCES federation(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY federation_federation_resolver
    ADD CONSTRAINT federation_federation_resolver_federation_resolver_fkey FOREIGN KEY (federation_resolver) REFERENCES federation_resolver(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY federation_resolver
    ADD CONSTRAINT federation_resolver_type_fkey FOREIGN KEY (type) REFERENCES type(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT federation_tmuser_federation_fkey FOREIGN KEY (federation) REFERENCES federation(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT federation_tmuser_role_fkey FOREIGN KEY (role) REFERENCES role(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT federation_tmuser_tm_user_fkey FOREIGN KEY (tm_user) REFERENCES tm_user(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY hwinfo
    ADD CONSTRAINT hwinfo_serverid_fkey FOREIGN KEY (serverid) REFERENCES server(id) ON DELETE CASCADE;

ALTER TABLE ONLY job
    ADD CONSTRAINT job_agent_fkey FOREIGN KEY (agent) REFERENCES job_agent(id) ON DELETE CASCADE;

ALTER TABLE ONLY job
    ADD CONSTRAINT job_job_deliveryservice_fkey FOREIGN KEY (job_deliveryservice) REFERENCES deliveryservice(id);

ALTER TABLE ONLY job
    ADD CONSTRAINT job_job_user_fkey FOREIGN KEY (job_user) REFERENCES tm_user(id);

ALTER TABLE ONLY job_result
    ADD CONSTRAINT job_result_agent_fkey FOREIGN KEY (agent) REFERENCES job_agent(id) ON DELETE CASCADE;

ALTER TABLE ONLY job_result
    ADD CONSTRAINT job_result_job_fkey FOREIGN KEY (job) REFERENCES job(id) ON DELETE CASCADE;

ALTER TABLE ONLY job
    ADD CONSTRAINT job_status_fkey FOREIGN KEY (status) REFERENCES job_status(id);

ALTER TABLE ONLY log
    ADD CONSTRAINT log_tm_user_fkey FOREIGN KEY (tm_user) REFERENCES tm_user(id);

ALTER TABLE ONLY phys_location
    ADD CONSTRAINT phys_location_region_fkey FOREIGN KEY (region) REFERENCES region(id);

ALTER TABLE ONLY profile_parameter
    ADD CONSTRAINT profile_parameter_parameter_fkey FOREIGN KEY (parameter) REFERENCES parameter(id) ON DELETE CASCADE;

ALTER TABLE ONLY profile_parameter
    ADD CONSTRAINT profile_parameter_profile_fkey FOREIGN KEY (profile) REFERENCES profile(id) ON DELETE CASCADE;

ALTER TABLE ONLY regex
    ADD CONSTRAINT regex_type_fkey FOREIGN KEY (type) REFERENCES type(id);

ALTER TABLE ONLY region
    ADD CONSTRAINT region_division_fkey FOREIGN KEY (division) REFERENCES division(id);

ALTER TABLE ONLY server
    ADD CONSTRAINT server_cachegroup_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroup(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE ONLY server
    ADD CONSTRAINT server_cdn_id_fkey FOREIGN KEY (cdn_id) REFERENCES cdn(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE ONLY server
    ADD CONSTRAINT server_phys_location_fkey FOREIGN KEY (phys_location) REFERENCES phys_location(id);

ALTER TABLE ONLY server
    ADD CONSTRAINT server_profile_fkey FOREIGN KEY (profile) REFERENCES profile(id);

ALTER TABLE ONLY server
    ADD CONSTRAINT server_status_fkey FOREIGN KEY (status) REFERENCES status(id);

ALTER TABLE ONLY server
    ADD CONSTRAINT server_type_fkey FOREIGN KEY (type) REFERENCES type(id);

ALTER TABLE ONLY servercheck
    ADD CONSTRAINT servercheck_server_fkey FOREIGN KEY (server) REFERENCES server(id) ON DELETE CASCADE;

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT staticdnsentry_cachegroup_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroup(id);

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT staticdnsentry_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id);

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT staticdnsentry_type_fkey FOREIGN KEY (type) REFERENCES type(id);

ALTER TABLE ONLY tm_user
    ADD CONSTRAINT tm_user_role_fkey FOREIGN KEY (role) REFERENCES role(id) ON DELETE SET NULL;

ALTER TABLE ONLY to_extension
    ADD CONSTRAINT to_extension_type_fkey FOREIGN KEY (type) REFERENCES type(id);

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM dkirkw001c;
GRANT ALL ON SCHEMA public TO dkirkw001c;
GRANT ALL ON SCHEMA public TO PUBLIC;

-- +goose Down
-- SQL section 'Down' is executed when this migration is rolled back


