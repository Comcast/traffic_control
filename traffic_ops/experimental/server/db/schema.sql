--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.1
-- Dumped by pg_dump version 9.5.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: traffic_ops; Type: DATABASE; Schema: -; Owner: touser
--

CREATE DATABASE traffic_ops WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';


ALTER DATABASE traffic_ops OWNER TO touser;

\connect traffic_ops

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: asns; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE asns (
    asn integer NOT NULL,
    cachegroup text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE asns OWNER TO touser;

--
-- Name: asns_v; Type: VIEW; Schema: public; Owner: touser
--

CREATE VIEW asns_v AS
 SELECT asns.asn,
    asns.cachegroup,
    asns.created_at,
    pg_xact_commit_timestamp(asns.xmin) AS last_updated
   FROM asns;


ALTER TABLE asns_v OWNER TO touser;

--
-- Name: cachegroups; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE cachegroups (
    name text NOT NULL,
    description text NOT NULL,
    latitude numeric,
    longitude numeric,
    parent_cachegroup text,
    type text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE cachegroups OWNER TO touser;

--
-- Name: cachegroups_parameters; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE cachegroups_parameters (
    cachegroup text NOT NULL,
    parameter_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE cachegroups_parameters OWNER TO touser;

--
-- Name: cdns; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE cdns (
    name text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE cdns OWNER TO touser;

--
-- Name: parameter_id_seq; Type: SEQUENCE; Schema: public; Owner: touser
--

CREATE SEQUENCE parameter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE parameter_id_seq OWNER TO touser;

--
-- Name: parameters; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE parameters (
    id bigint DEFAULT nextval('parameter_id_seq'::regclass) NOT NULL,
    name text NOT NULL,
    config_file text NOT NULL,
    value text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE parameters OWNER TO touser;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE profiles (
    name text PRIMARY KEY,
    description text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE profiles OWNER TO touser;

--
-- Name: profiles_parameters; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE profiles_parameters (
    profile text NOT NULL,
    parameter_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE profiles_parameters OWNER TO touser;

--
-- Name: servers; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE servers (
    host_name text NOT NULL,
    domain_name text NOT NULL,
    tcp_port integer,
    xmpp_id text,
    xmpp_passwd text,
    interface_name text NOT NULL,
    ip_address inet,
    ip_gateway inet,
    ip6_address inet,
    ip6_gateway inet,
    interface_mtu integer DEFAULT 9000 NOT NULL,
    phys_location text NOT NULL,
    rack text,
    cachegroup text NOT NULL,
    type text NOT NULL,
    status text NOT NULL,
    upd_pending boolean DEFAULT false NOT NULL,
    profile text NOT NULL,
    cdn text NOT NULL,
    mgmt_ip_address inet,
    mgmt_ip_gateway inet,
    ilo_ip_address inet,
    ilo_ip_gateway inet,
    ilo_username text,
    ilo_password text,
    router_host_name text,
    router_port_name text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE servers OWNER TO touser;

--
-- Name: content_routers_v; Type: VIEW; Schema: public; Owner: touser
--

CREATE VIEW content_routers_v AS
 SELECT servers.ip_address AS ip,
    servers.ip6_address AS ip6,
    servers.profile,
    servers.cachegroup AS location,
    servers.status,
    servers.tcp_port AS port,
    servers.host_name,
    concat(servers.host_name, '.', servers.domain_name) AS fqdn,
    parameters.value AS apiport,
    servers.cdn
   FROM (((servers
     JOIN profiles ON ((profiles.name = servers.profile)))
     JOIN profiles_parameters ON ((profiles_parameters.profile = profiles.name)))
     JOIN parameters ON ((parameters.id = profiles_parameters.parameter_id)))
  WHERE ((servers.type = 'CCR'::text) AND (parameters.name = 'api.port'::text));


ALTER TABLE content_routers_v OWNER TO touser;

--
-- Name: content_servers_v; Type: VIEW; Schema: public; Owner: touser
--

CREATE VIEW content_servers_v AS
 SELECT DISTINCT servers.host_name,
    servers.profile,
    servers.type,
    servers.cachegroup AS location,
    servers.ip_address AS ip,
    servers.cdn,
    servers.status,
    servers.cachegroup AS cache_group,
    servers.ip6_address AS ip6,
    servers.tcp_port AS port,
    concat(servers.host_name, '.', servers.domain_name) AS fqdn,
    servers.interface_name,
    parameters.value AS hash_count
   FROM (((servers
     JOIN profiles ON ((profiles.name = servers.profile)))
     JOIN profiles_parameters ON ((profiles_parameters.profile = profiles.name)))
     JOIN parameters ON ((parameters.id = profiles_parameters.parameter_id)))
  WHERE ((parameters.name = 'weight'::text) AND (servers.status = ANY (ARRAY['REPORTED'::text, 'ONLINE'::text])) AND (servers.type = 'EDGE'::text));


ALTER TABLE content_servers_v OWNER TO touser;

--
-- Name: deliveryservices; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE deliveryservices (
    name text NOT NULL,
    display_name text NOT NULL,
    description text NOT NULL,
    cdn text NOT NULL,
    domain text NOT NULL,
    active boolean NOT NULL,
    dscp smallint NOT NULL,
    signed boolean NOT NULL,
    qstring_ignore boolean NOT NULL,
    geo_limit boolean NOT NULL,
    http_bypass_fqdn text,
    dns_bypass_ip inet,
    dns_bypass_ip6 inet,
    dns_bypass_ttl integer,
    org_server_fqdn text,
    type text NOT NULL,
    profile text NOT NULL,
    dns_ttl integer,
    global_max_mbps integer,
    global_max_tps integer,
    max_dns_answers integer DEFAULT 0,
    info_url text,
    miss_lat numeric,
    miss_long numeric,
    check_path text,
    protocol smallint DEFAULT 0,
    ssl_key_version bigint DEFAULT 0,
    ipv6_routing_enabled boolean NOT NULL,
    range_request_handling smallint DEFAULT 0,
    edge_header_rewrite text,
    origin_shield text,
    mid_header_rewrite text,
    regex_remap text,
    cacheurl text,
    remap_text text,
    multi_site_origin boolean,
    tr_response_headers text,
    initial_dispersion integer DEFAULT 1 NOT NULL,
    dns_bypass_cname text,
    tr_request_headers text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE deliveryservices OWNER TO touser;

--
-- Name: deliveryservices_regexes; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE deliveryservices_regexes (
    deliveryservice text NOT NULL,
    regex_id bigint NOT NULL,
    set_number integer DEFAULT 0
);


ALTER TABLE deliveryservices_regexes OWNER TO touser;

--
-- Name: deliveryservices_servers; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE deliveryservices_servers (
    deliveryservice name NOT NULL,
    server text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE deliveryservices_servers OWNER TO touser;

--
-- Name: regexes_id_seq; Type: SEQUENCE; Schema: public; Owner: touser
--

CREATE SEQUENCE regexes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE regexes_id_seq OWNER TO touser;

--
-- Name: regexes; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE regexes (
    id bigint DEFAULT nextval('regexes_id_seq'::regclass) NOT NULL,
    pattern text NOT NULL,
    type text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE regexes OWNER TO touser;

--
-- Name: cr_deliveryservice_server_v; Type: VIEW; Schema: public; Owner: touser
--

CREATE VIEW cr_deliveryservice_server_v AS
 SELECT DISTINCT regexes.pattern,
    deliveryservices.name,
    servers.cdn,
    servers.host_name AS server_name
   FROM ((((deliveryservices
     JOIN deliveryservices_regexes ON ((deliveryservices_regexes.deliveryservice = deliveryservices.name)))
     JOIN regexes ON ((regexes.id = deliveryservices_regexes.regex_id)))
     JOIN deliveryservices_servers ON ((deliveryservices.name = (deliveryservices_servers.deliveryservice)::text)))
     JOIN servers ON ((servers.host_name = deliveryservices_servers.server)))
  WHERE (deliveryservices.type <> 'ANY_MAP'::text);


ALTER TABLE cr_deliveryservice_server_v OWNER TO touser;

--
-- Name: staticdnsentries_id_seq; Type: SEQUENCE; Schema: public; Owner: touser
--

CREATE SEQUENCE staticdnsentries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE staticdnsentries_id_seq OWNER TO touser;

--
-- Name: staticdnsentries; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE staticdnsentries (
    id integer DEFAULT nextval('staticdnsentries_id_seq'::regclass) NOT NULL,
    name character varying(63) NOT NULL,
    type character varying(2) NOT NULL,
    class character varying(2) NOT NULL,
    ttl bigint DEFAULT 3600 NOT NULL,
    rdata character varying(255) NOT NULL,
    deliveryservice text NOT NULL,
    cachegroup text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE staticdnsentries OWNER TO touser;

--
-- Name: types; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE types (
    name text NOT NULL,
    description text,
    use_in_table text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE types OWNER TO touser;

--
-- Name: crconfig_ds_data_v; Type: VIEW; Schema: public; Owner: touser
--

CREATE VIEW crconfig_ds_data_v AS
 SELECT deliveryservices.name,
    deliveryservices.profile,
    deliveryservices.dns_ttl,
    deliveryservices.global_max_mbps,
    deliveryservices.global_max_tps,
    deliveryservices.max_dns_answers,
    deliveryservices.miss_lat,
    deliveryservices.miss_long,
    deliveryservices.protocol,
    deliveryservices.ipv6_routing_enabled,
    deliveryservices.tr_request_headers,
    deliveryservices.tr_response_headers,
    deliveryservices.initial_dispersion,
    deliveryservices.dns_bypass_cname,
    deliveryservices.dns_bypass_ip,
    deliveryservices.dns_bypass_ip6,
    deliveryservices.dns_bypass_ttl,
    deliveryservices.geo_limit,
    deliveryservices.cdn,
    regexes.pattern AS match_pattern,
    regextypes.name AS match_type,
    deliveryservices_regexes.set_number,
    staticdnsentries.name AS sdns_host,
    staticdnsentries.rdata AS sdns_address,
    staticdnsentries.ttl AS sdns_ttl,
    sdnstypes.name AS sdns_type
   FROM (((((deliveryservices
     LEFT JOIN staticdnsentries ON ((deliveryservices.name = staticdnsentries.deliveryservice)))
     JOIN deliveryservices_regexes ON ((deliveryservices_regexes.deliveryservice = deliveryservices.name)))
     JOIN regexes ON ((regexes.id = deliveryservices_regexes.regex_id)))
     JOIN types regextypes ON ((regextypes.name = regexes.type)))
     LEFT JOIN types sdnstypes ON ((sdnstypes.name = (staticdnsentries.type)::text)));


ALTER TABLE crconfig_ds_data_v OWNER TO touser;

--
-- Name: crconfig_params_v; Type: VIEW; Schema: public; Owner: touser
--

CREATE VIEW crconfig_params_v AS
 SELECT DISTINCT servers.cdn,
    servers.profile,
    servers.type AS stype,
    parameters.name AS pname,
    parameters.config_file AS cfile,
    parameters.value AS pvalue
   FROM (((servers
     JOIN profiles ON ((profiles.name = servers.profile)))
     JOIN profiles_parameters ON ((profiles_parameters.profile = servers.profile)))
     JOIN parameters ON ((parameters.id = profiles_parameters.parameter_id)))
  WHERE ((servers.type = ANY (ARRAY['EDGE'::text, 'MID'::text, 'CCR'::text])) AND (parameters.config_file = 'CRConfig.json'::text));


ALTER TABLE crconfig_params_v OWNER TO touser;

--
-- Name: deliveryservices_users; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE deliveryservices_users (
    deliveryservice text NOT NULL,
    username text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE deliveryservices_users OWNER TO touser;

--
-- Name: divisions; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE divisions (
    name text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE divisions OWNER TO touser;

--
-- Name: domains; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE domains (
    name text NOT NULL,
    cdn text NOT NULL,
    dnssec boolean NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE domains OWNER TO touser;

--
-- Name: extensions; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE extensions (
    name text NOT NULL,
    short_name text,
    description text,
    version text NOT NULL,
    info_url text NOT NULL,
    script_file text NOT NULL,
    active boolean NOT NULL,
    additional_config_json text,
    type text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE extensions OWNER TO touser;

--
-- Name: federation_resolvers_id_seq; Type: SEQUENCE; Schema: public; Owner: touser
--

CREATE SEQUENCE federation_resolvers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE federation_resolvers_id_seq OWNER TO touser;

--
-- Name: federation_resolvers; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE federation_resolvers (
    id bigint DEFAULT nextval('federation_resolvers_id_seq'::regclass) NOT NULL,
    ip_address inet NOT NULL,
    type text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE federation_resolvers OWNER TO touser;

--
-- Name: federation_users; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE federation_users (
    federation_id bigint NOT NULL,
    username text NOT NULL,
    role text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE federation_users OWNER TO touser;

--
-- Name: federations_id_seq; Type: SEQUENCE; Schema: public; Owner: touser
--

CREATE SEQUENCE federations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE federations_id_seq OWNER TO touser;

--
-- Name: federations; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE federations (
    id bigint DEFAULT nextval('federations_id_seq'::regclass) NOT NULL,
    cname text NOT NULL,
    description text,
    ttl integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE federations OWNER TO touser;

--
-- Name: federations_deliveryservices; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE federations_deliveryservices (
    federation_id bigint NOT NULL,
    deliveryservice text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE federations_deliveryservices OWNER TO touser;

--
-- Name: federations_federation_resolvers; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE federations_federation_resolvers (
    federation_id bigint NOT NULL,
    federation_resolver integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE federations_federation_resolvers OWNER TO touser;

--
-- Name: goose_db_version_id_seq; Type: SEQUENCE; Schema: public; Owner: touser
--

CREATE SEQUENCE goose_db_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE goose_db_version_id_seq OWNER TO touser;

--
-- Name: goose_db_version; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE goose_db_version (
    id integer DEFAULT nextval('goose_db_version_id_seq'::regclass) NOT NULL,
    version_id bigint NOT NULL,
    is_applied boolean NOT NULL,
    tstamp timestamp without time zone DEFAULT now()
);


ALTER TABLE goose_db_version OWNER TO touser;

--
-- Name: log_id_seq; Type: SEQUENCE; Schema: public; Owner: touser
--

CREATE SEQUENCE log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE log_id_seq OWNER TO touser;

--
-- Name: log; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE log (
    id integer DEFAULT nextval('log_id_seq'::regclass) NOT NULL,
    level text,
    message text NOT NULL,
    username text NOT NULL,
    ticketnum text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE log OWNER TO touser;

--
-- Name: monitors_v; Type: VIEW; Schema: public; Owner: touser
--

CREATE VIEW monitors_v AS
 SELECT servers.ip_address AS ip,
    servers.ip6_address AS ip6,
    servers.profile,
    servers.cachegroup AS location,
    servers.status,
    servers.tcp_port AS port,
    concat(servers.host_name, '.', servers.domain_name) AS fqdn,
    servers.cdn,
    servers.host_name
   FROM servers
  WHERE (servers.type = 'RASCAL'::text);


ALTER TABLE monitors_v OWNER TO touser;

--
-- Name: phys_locations; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE phys_locations (
    name text NOT NULL,
    short_name text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    state text NOT NULL,
    zip text NOT NULL,
    poc text,
    phone text,
    email text,
    comments text,
    region text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE phys_locations OWNER TO touser;

--
-- Name: profiles_v; Type: VIEW; Schema: public; Owner: touser
--

CREATE VIEW profiles_v AS
 SELECT profiles.name,
    profiles.description,
    profiles.created_at,
    pg_xact_commit_timestamp(profiles.xmin) AS last_updated
   FROM profiles;


ALTER TABLE profiles_v OWNER TO touser;

--
-- Name: regions; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE regions (
    name text NOT NULL,
    division text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE regions OWNER TO touser;

--
-- Name: regions_v; Type: VIEW; Schema: public; Owner: touser
--

CREATE VIEW regions_v AS
 SELECT regions.name,
    regions.division,
    regions.created_at,
    pg_xact_commit_timestamp(regions.xmin) AS last_updated
   FROM regions;


ALTER TABLE regions_v OWNER TO touser;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE roles (
    name text NOT NULL,
    description text,
    priv_level integer NOT NULL
);


ALTER TABLE roles OWNER TO touser;

--
-- Name: stats_summary; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE stats_summary (
    cdn_name text NOT NULL,
    deliveryservice text NOT NULL,
    stat_name text NOT NULL,
    stat_value numeric NOT NULL,
    stat_date date NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE stats_summary OWNER TO touser;

--
-- Name: statuses; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE statuses (
    name text NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE statuses OWNER TO touser;

--
-- Name: users; Type: TABLE; Schema: public; Owner: touser
--

CREATE TABLE users (
    username text NOT NULL,
    role text,
    email text,
    full_name text,
    ssh_pub_key text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE users OWNER TO touser;

--
-- Name: asns_asn_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY asns
    ADD CONSTRAINT asns_asn_pkey PRIMARY KEY (asn);


--
-- Name: cachegroup_name_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY cachegroups
    ADD CONSTRAINT cachegroup_name_pkey PRIMARY KEY (name);


--
-- Name: cachegroups_parameters_cachegroup_parameter_id_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY cachegroups_parameters
    ADD CONSTRAINT cachegroups_parameters_cachegroup_parameter_id_pkey PRIMARY KEY (cachegroup, parameter_id);


--
-- Name: cdns_name_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY cdns
    ADD CONSTRAINT cdns_name_pkey PRIMARY KEY (name);


--
-- Name: deliveryservices_name_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY deliveryservices
    ADD CONSTRAINT deliveryservices_name_pkey PRIMARY KEY (name);


--
-- Name: deliveryservices_regexes_deliveryservice_regex_id_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY deliveryservices_regexes
    ADD CONSTRAINT deliveryservices_regexes_deliveryservice_regex_id_pkey PRIMARY KEY (deliveryservice, regex_id);


--
-- Name: deliveryservices_servers_deliveryservice_server_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY deliveryservices_servers
    ADD CONSTRAINT deliveryservices_servers_deliveryservice_server_pkey PRIMARY KEY (deliveryservice, server);


--
-- Name: deliveryservices_users_deliveryservice_username_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY deliveryservices_users
    ADD CONSTRAINT deliveryservices_users_deliveryservice_username_pkey PRIMARY KEY (deliveryservice, username);


--
-- Name: divisions_name_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY divisions
    ADD CONSTRAINT divisions_name_pkey PRIMARY KEY (name);


--
-- Name: domains_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY domains
    ADD CONSTRAINT domains_pkey PRIMARY KEY (name);


--
-- Name: federation_resolvers_id_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY federation_resolvers
    ADD CONSTRAINT federation_resolvers_id_pkey PRIMARY KEY (id);


--
-- Name: federation_users_federation_username_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY federation_users
    ADD CONSTRAINT federation_users_federation_username_pkey PRIMARY KEY (federation_id, username);


--
-- Name: federations_deliveryservices_federation_id_deliveryservice_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY federations_deliveryservices
    ADD CONSTRAINT federations_deliveryservices_federation_id_deliveryservice_pkey PRIMARY KEY (federation_id, deliveryservice);


--
-- Name: federations_federation_resolvers_federation_id_federation_resol; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY federations_federation_resolvers
    ADD CONSTRAINT federations_federation_resolvers_federation_id_federation_resol PRIMARY KEY (federation_id, federation_resolver);


--
-- Name: federations_id_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY federations
    ADD CONSTRAINT federations_id_pkey PRIMARY KEY (id);


--
-- Name: goose_db_version_id_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY goose_db_version
    ADD CONSTRAINT goose_db_version_id_pkey PRIMARY KEY (id);


--
-- Name: parameters_id_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY parameters
    ADD CONSTRAINT parameters_id_pkey PRIMARY KEY (id);


--
-- Name: profiles_name_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY profiles
    ADD CONSTRAINT profiles_name_pkey PRIMARY KEY (name);


--
-- Name: types_name_pkey; Type: CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY types
    ADD CONSTRAINT types_name_pkey PRIMARY KEY (name);


--
-- Name: cachegroups_short_name; Type: INDEX; Schema: public; Owner: touser
--

CREATE UNIQUE INDEX cachegroups_short_name ON cachegroups USING btree (description);


--
-- Name: federation_resolvers_ip_address; Type: INDEX; Schema: public; Owner: touser
--

CREATE UNIQUE INDEX federation_resolvers_ip_address ON federation_resolvers USING btree (ip_address);


--
-- Name: parameters_name_config_file_value_idx; Type: INDEX; Schema: public; Owner: touser
--

CREATE UNIQUE INDEX parameters_name_config_file_value_idx ON parameters USING btree (name, config_file, value);


--
-- Name: asns_cchegroup_cachegroups_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY asns
    ADD CONSTRAINT asns_cchegroup_cachegroups_name_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroups(name);


--
-- Name: cachegroups_parameters_cachegroup_cachegroups_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY cachegroups_parameters
    ADD CONSTRAINT cachegroups_parameters_cachegroup_cachegroups_name_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroups(name);


--
-- Name: cachegroups_parameters_parameter_id_parameters_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY cachegroups_parameters
    ADD CONSTRAINT cachegroups_parameters_parameter_id_parameters_id_fkey FOREIGN KEY (parameter_id) REFERENCES parameters(id);


--
-- Name: cachegroups_parent_cachegroup_cachegroups_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY cachegroups
    ADD CONSTRAINT cachegroups_parent_cachegroup_cachegroups_name_fkey FOREIGN KEY (parent_cachegroup) REFERENCES cachegroups(name);


--
-- Name: cachegroups_type_types_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY cachegroups
    ADD CONSTRAINT cachegroups_type_types_name_fkey FOREIGN KEY (type) REFERENCES types(name);


--
-- Name: deliveryservices_cdn_cdns_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY deliveryservices
    ADD CONSTRAINT deliveryservices_cdn_cdns_name_fkey FOREIGN KEY (cdn) REFERENCES cdns(name);


--
-- Name: deliveryservices_domain_domains_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY deliveryservices
    ADD CONSTRAINT deliveryservices_domain_domains_name_fkey FOREIGN KEY (domain) REFERENCES domains(name);


--
-- Name: deliveryservices_profile_profiles_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY deliveryservices
    ADD CONSTRAINT deliveryservices_profile_profiles_name_fkey FOREIGN KEY (profile) REFERENCES profiles(name);


--
-- Name: deliveryservices_type_types_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY deliveryservices
    ADD CONSTRAINT deliveryservices_type_types_name_fkey FOREIGN KEY (type) REFERENCES types(name);


--
-- Name: domains_cdn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: touser
--

ALTER TABLE ONLY domains
    ADD CONSTRAINT domains_cdn_fkey FOREIGN KEY (cdn) REFERENCES cdns(name);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;

--
-- PostgreSQL database dump complete
--


----------------------------------------------------------------------
--
-- Caching Proxy Config Files
--
----------------------------------------------------------------------

CREATE DOMAIN port AS integer CHECK (VALUE >= 0 AND VALUE <= 65535);

-- records.config
-----------------

-- \todo rename to something more generic?
-- \todo divide prefixes (alarm_, allocator_, etc) into their own tables?
CREATE TABLE IF NOT EXISTS caching_proxy_record_data (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    accept_threads integer NOT NULL,
    admin_user text NOT NULL, -- fk into ?
    user_id text NOT NULL,
    autoconf_port port NOT NULL,
    number_config integer NOT NULL,
    alarm_abs_path text,
    alarm_bin text NOT NULL,
    alarm_email text NOT NULL, -- \todo regex constraint? citext extension?
    allocator_debug_filter integer NOT NULL,
    allocator_enable_reclaim boolean NOT NULL, -- \todo verify param is boolean
    allocator_huge_pages boolean NOT NULL,
    allocator_max_overage integer NOT NULL,
    allocator_thread_freelist_size integer NOT NULL,
    body_factory_enable_customizations text NOT NULL CHECK (body_factory_enable_customizations in ('customizable response pages', 'language-targetted response pages', 'host-targetted response pages')), -- \todo rename check strings?
    body_factory_enable_logging boolean NOT NULL,
    body_factory_response_suppression_mode text NOT NULL CHECK (body_factory_response_suppression_mode in ('never', 'always', 'only intercepted traffic')),
    body_factory_template_sets_dir text NOT NULL,
    enable_read_while_writer text NOT NULL CHECK (enable_read_while_writer in ('never', 'always', 'always_and_allow_range')), -- \todo bikeshed
    cluster_configuration text NOT NULL,
    cluster_cluster_port port NOT NULL,
    cluster_ethernet_interface text NOT NULL,
    cluster_log_bogus_mc_msgs integer NOT NULL,
    cluster_mc_group_addr text NOT NULL,
    cluster_mc_ttl integer NOT NULL,
    cluster_mcport port NOT NULL,
    cluster_rsport port NOT NULL,
    config_dir text NOT NULL,
    core_limit integer NOT NULL,
    diags_debug_enabled boolean NOT NULL,
    diags_debug_tags text NOT NULL,
    diags_show_location boolean NOT NULL,
    dns_max_dns_in_flight integer NOT NULL,
    dns_nameservers text,
    dns_resolv_conf text NOT NULL,
    dns_round_robin_nameservers boolean NOT NULL,
    dns_search_default_domains text NOT NULL CHECK (dns_search_default_domains in ('disable', 'enable', 'enable_restrain_splitting')),
    dns_splitDNS_enabled boolean NOT NULL,
    dns_url_expansions text,
    dns_validate_query_name boolean NOT NULL,
    dump_mem_info_frequency integer NOT NULL,
    env_prep text,
    exec_thread_affinity text NOT NULL CHECK (exec_thread_affinity in ('machine', 'numa', 'sockets', 'cores', 'processing units')),
    exec_thread_autoconfig boolean NOT NULL,
    exec_thread_autoconfig_scale double precision NOT NULL,
    exec_thread_limit integer NOT NULL,
    parse_no_host_url_redirect text,
    icp_enabled text NOT NULL CHECK (icp_enabled in ('disabled', 'receive', 'send and receive')),
    icp_interface text,
    icp_port port NOT NULL,
    icp_multicast_enabled integer NOT NULL,
    icp_query_timeout integer NOT NULL,
    mloc_enabled integer NOT NULL,
    net_connections_throttle integer NOT NULL,
    net_defer_accept boolean NOT NULL,
    net_sock_recv_buffer_size_in integer NOT NULL,
    net_sock_recv_buffer_size_out integer NOT NULL,
    net_sock_send_buffer_size_in integer NOT NULL,
    net_sock_send_buffer_size_out integer NOT NULL,
    output_logfile text NOT NULL,
    process_manager_management_port port NOT NULL,
    proxy_binary_opts text NOT NULL, -- \todo make table? Investigate this param
    proxy_name text NOT NULL,
    reverse_proxy_enabled boolean NOT NULL,
    snapshot_dir text NOT NULL,
    stack_dump_enabled integer NOT NULL,
    syslog_facility text NOT NULL, -- \todo enum? Investigate.
    system_mmap_max integer NOT NULL,
    task_threads integer NOT NULL,
    temp_dir text NOT NULL,
    update_concurrent_updates integer NOT NULL,
    update_enabled integer NOT NULL,
    update_force integer NOT NULL,
    update_retry_count integer NOT NULL,
    update_retry_interval interval NOT NULL,
    url_remap_default_to_server_pac integer NOT NULL,
    url_remap_default_to_server_pac_port port,
    url_remap_filename text NOT NULL,
    url_remap_pristine_host_hdr integer NOT NULL,
    url_remap_remap_required integer NOT NULL,
    cron_ort_syncds_cdn text NOT NULL, -- \todo calculate in ort script (client side)?
    domain_name text NOT NULL,
    health_connection_timeout integer NOT NULL,
    health_polling_url text NOT NULL,
    health_threshold_available_bandwidth_kbps integer NOT NULL,
    health_threshold_load_average integer NOT NULL,
    health_threshold_query_time integer NOT NULL,
    history_count integer NOT NULL,
    cache_interim_storage text,
    local_cluster_type integer NOT NULL,
    local_log_collation_mode integer NOT NULL,
    log_format_format text NOT NULL,
    log_format_name text NOT NULL,
    max_reval_duration interval NOT NULL,
    astats_path text NOT NULL,
    qstring text NOT NULL, -- \todo enum?
    astats_record_types integer NOT NULL, -- \todo make astats table
    regex_revalidate text NOT NULL, -- \todo this is '--config regex_revalidate'. Remove? Hardcode? Better way?
    astats_library text NOT NULL, -- \todo this is 'remap_stats.so'. Remove & hardcode? Better way?
    traffic_server_chkconfig text NOT NULL, -- \todo investigate-- make better
    crconfig_weight double precision NOT NULL, -- \todo rename?
    parent_config_weight double precision NOT NULL -- \todo rename?
);

-- one-to-one with record_data
CREATE TABLE IF NOT EXISTS caching_proxy_record_data_log (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    auto_delete_rolled_files boolean NOT NULL,
    collation_host text NOT NULL,
    collation_host_tagged boolean NOT NULL,
    collation_port port NOT NULL,
    collation_retry interval NOT NULL,
    collation_secret text NOT NULL,
    custom_logs_enabled integer NOT NULL,
    hostname text NOT NULL,
    logfile_dir text NOT NULL,
    logfile_perm text NOT NULL, -- \todo separate into its own table? Regex constraint?
    logging_enabled text NOT NULL CHECK (logging_enabled in ('disabled', 'errors', 'transactions', 'all')),
    max_secs_per_buffer integer NOT NULL,
    max_space_mb_for_logs integer NOT NULL,
    max_space_mb_for_orphan_logs integer NOT NULL,
    max_space_mb_headroom integer NOT NULL,
    rolling_enabled text NOT NULL CHECK (rolling_enabled in ('disabled', 'interval', 'size', 'either', 'both')),
    rolling_interval interval NOT NULL,
    rolling_offset interval NOT NULL,
    rolling_size_mb integer NOT NULL,
    sampling_frequency integer NOT NULL,
    separate_host_logs integer NOT NULL,
    separate_icp_logs integer NOT NULL,
    xml_config_file text NOT NULL
);

CREATE TABLE IF NOT EXISTS caching_proxy_record_data_log_data (
    profile text REFERENCES caching_proxy_record_data (profile),
    name text NOT NULL,
    enabled boolean NOT NULL,
    header text,
    is_ascii boolean NOT NULL,
    PRIMARY KEY (profile, name)
);

-- one-to-one with record_data, record_data_http
CREATE TABLE IF NOT EXISTS caching_proxy_record_data_http_cache (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    allow_empty_doc boolean NOT NULL,
    cache_responses_to_cookies text NOT NULL CHECK (cache_responses_to_cookies in ('no', 'any', 'only images', 'except text')),
    cache_urls_that_look_dynamic boolean NOT NULL,
    enable_default_vary_headers boolean NOT NULL,
    fuzz_probability double precision NOT NULL,
    fuzz_time interval NOT NULL,
    heuristic_lm_factor double precision NOT NULL,
    heuristic_max_lifetime integer NOT NULL,
    heuristic_min_lifetime integer NOT NULL,
    http boolean NOT NULL,
    ignore_accept_encoding_mismatch boolean NOT NULL,
    ignore_authentication boolean NOT NULL,
    ignore_client_cc_max_age integer NOT NULL,
    ignore_client_no_cache boolean NOT NULL,
    ignore_server_no_cache boolean NOT NULL,
    ims_on_client_no_cache boolean NOT NULL,
    max_stale_age integer NOT NULL,
    range_lookup boolean NOT NULL,
    required_headers text NOT NULL CHECK (required_headers in ('no', 'implicit', 'explicit')),
    vary_default_images text,
    vary_default_other text,
    vary_default_text text,
    when_to_add_no_cache_to_msie_requests integer NOT NULL,
    when_to_revalidate text NOT NULL CHECK (when_to_revalidate in ('directive or heuristic', 'stale if heuristic', 'always stale', 'never stale', 'directive or heuristic unless if-modified-since'))
);

-- one-to-one with record_data
CREATE TABLE IF NOT EXISTS caching_proxy_record_data_http (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    accept_no_activity_timeout integer NOT NULL,
    anonymize_insert_client_ip integer NOT NULL,
    anonymize_other_header_list text,
    anonymize_remove_client_ip bool NOT NULL,
    anonymize_remove_cookie boolean NOT NULL,
    anonymize_remove_from boolean NOT NULL,
    anonymize_remove_referer boolean NOT NULL,
    anonymize_remove_user_agent boolean NOT NULL,
    background_fill_active_timeout integer NOT NULL,
    background_fill_completed_threshold double precision NOT NULL,
    chunking_enabled text NOT NULL CHECK (chunking_enabled in ('never', 'always', 'if prior response HTTP/1.1', 'if request and prior response HTTP/1.1')),
    congestion_control_enabled boolean NOT NULL,
    connect_attempts_max_retries integer NOT NULL,
    connect_attempts_max_retries_dead_server integer NOT NULL,
    connect_attempts_rr_retries integer NOT NULL,
    connect_attempts_timeout integer NOT NULL,
    down_server_abort_threshold integer NOT NULL,
    down_server_cache_time integer NOT NULL,
    enable_http_stats boolean NOT NULL,
    enable_url_expandomatic boolean NOT NULL,
    forward_proxy_auth_to_parent boolean NOT NULL,
    insert_age_in_response boolean NOT NULL,
    insert_request_via_str text NOT NULL CHECK (insert_request_via_str in ('no', 'normal', 'higher', 'highest')),
    insert_response_via_str text NOT NULL CHECK (insert_response_via_str in ('no', 'normal', 'higher', 'highest')),
    insert_squid_x_forwarded_for boolean NOT NULL,
    keep_alive_enabled_in boolean NOT NULL,
    keep_alive_enabled_out boolean NOT NULL,
    keep_alive_enabled_no_activity_timeout_in integer NOT NULL,
    keep_alive_enabled_no_activity_timeout_out integer NOT NULL,
    negative_caching_enabled boolean NOT NULL,
    negative_caching_lifetime integer NOT NULL,
    no_dns_just_forward_to_parent boolean NOT NULL,
    normalize_ae_gzip boolean NOT NULL,
    origin_server_pipeline integer NOT NULL,
    parent_proxy_connect_attempts_timeout integer NOT NULL,
    parent_proxy_fail_threshold integer NOT NULL,
    parent_proxy_file text NOT NULL,
    parent_proxy_per_parent_connection_attempts integer NOT NULL,
    parent_proxy_parent_proxy_retry_time integer NOT NULL,
    parent_proxy_parent_proxy_total_connection_attempts integer NOT NULL,
    parent_proxy_parent_proxy_routing_enable boolean NOT NULL,
    post_connect_attempts_timeout integer NOT NULL,
    parent_push_method_enabled boolean NOT NULL,
    referer_default_redirect text NOT NULL,
    referer_filter integer NOT NULL,
    referer_format_redirect integer NOT NULL,
    response_server_enabled text NOT NULL CHECK (response_server_enabled in ('no', 'add header', 'add header if nonexistent')),
    send_http11_requests text NOT NULL CHECK (send_http11_requests in ('never', 'always', 'if prior response HTTP/1.1', 'if request and prior response HTTP/1.1')),
    share_server_sessions integer NOT NULL,
    slow_log_threshold integer NOT NULL,
    transaction_active_timeout_in interval NOT NULL,
    transaction_active_timeout_out interval NOT NULL,
    transaction_no_activity_timeout_in interval NOT NULL,
    transaction_no_activity_timeout_out interval NOT NULL,
    uncacheable_requests_bypass_parent boolean NOT NULL,
    user_agent_pipeline integer NOT NULL
);

-- one-to-one with record_data
CREATE TABLE IF NOT EXISTS caching_proxy_record_data_ssl (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    ca_cert_filename text NOT NULL,
    ca_cert_path text NOT NULL,
    client_ca_cert_filename text,
    client_ca_cert_path text NOT NULL,
    client_cert_filename text,
    client_cert_path text NOT NULL,
    client_certification_level integer NOT NULL,
    client_private_key_filename text,
    client_private_key_path text NOT NULL,
    client_verify_server integer NOT NULL,
    compression integer NOT NULL,
    number_threads integer NOT NULL,
    server_cert_path text NOT NULL,
    server_cert_chain_filename text,
    server_cipher_suite text NOT NULL, -- \todo generate? default? one-to-many table?
    server_honor_cipher_order integer NOT NULL,
    server_multicert_filename text NOT NULL,
    server_private_key_path text NOT NULL,
    SSLv2 boolean NOT NULL,
    SSLv3 boolean NOT NULL,
    TLSv1 boolean NOT NULL
);

-- one-to-one with record_data
CREATE TABLE IF NOT EXISTS caching_proxy_record_data_hostdb (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    server_stale_for interval NOT NULL,
    size integer NOT NULL,
    storage_size integer NOT NULL,
    strict_round_robin boolean NOT NULL,
    timeout integer NOT NULL,
    ttl_mode text NOT NULL CHECK (ttl_mode in ('dns', 'internal', 'smaller', 'larger'))
);

-- one-to-one with record_data
CREATE TABLE IF NOT EXISTS caching_proxy_cache (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    filename text NOT NULL,
    hosting_filename text NOT NULL,
    http_compatability_420_fixup integer NOT NULL,
    limits_http_max_alts integer NOT NULL,
    max_doc_size integer NOT NULL,
    min_average_object_size integer NOT NULL,
    mutex_retry_delay integer NOT NULL,
    permit_pinning integer NOT NULL,
    ram_cache_algorithm integer NOT NULL,
    ram_cache_compress integer NOT NULL,
    ram_cache_size bigint NOT NULL,
    ram_cache_use_seen_filter boolean NOT NULL,
    ram_cache_cutoff integer NOT NULL,
    target_fragment_size integer NOT NULL,
    threads_per_disk integer NOT NULL
);

-- one-to-many. one profile, many config files
CREATE TABLE IF NOT EXISTS caching_proxy_config_file_locations (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    filename text NOT NULL,
    location text NOT NULL
);

-- one-to-many. one profile, many ports
CREATE TABLE IF NOT EXISTS caching_proxy_records_data_http_connect_ports (
    profile text NOT NULL REFERENCES caching_proxy_record_data (profile),
    port port NOT NULL,
    PRIMARY KEY (profile, port)
);

-- one-to-many. one profile, many ports
CREATE TABLE IF NOT EXISTS caching_proxy_records_data_http_server_ports (
    profile text NOT NULL REFERENCES caching_proxy_record_data (profile),
    port port NOT NULL,
    ipv6 boolean NOT NULL,
    ssl boolean NOT NULL,
    PRIMARY KEY (profile, port, ipv6)
);

---- logs_xml.config
--------------------

CREATE TABLE IF NOT EXISTS caching_proxy_logs (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    rolling_enabled integer NOT NULL,
    rolling_interval interval NOT NULL, -- \todo make interval type and remove unit from name?
    rolling_offset_hr integer NOT NULL,
    rolling_size_mb integer NOT NULL
);

---- parent.config
------------------

CREATE TABLE IF NOT EXISTS caching_proxy_parent_data (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    algorithm text NOT NULL -- \todo make enum? lookup table?
);

---- astats.config
------------------

-- one-to-many. one profile, many IPs
CREATE TABLE IF NOT EXISTS caching_proxy_allowed_ips (
    profile text NOT NULL REFERENCES caching_proxy_record_data (profile),
    ip text NOT NULL, -- \todo make ip type? regex constraint?
    PRIMARY KEY (profile, ip)
);

---- storage.config
-------------------

CREATE TABLE IF NOT EXISTS caching_proxy_drive_types (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    drive_type text NOT NULL
);

-- one-to-one
-- \todo add foreign key constraint
CREATE TABLE IF NOT EXISTS caching_proxy_drive_prefixes (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    prefix text NOT NULL
);

-- one-to-many (one profile, many prefixes)
-- \todo add foreign key constraint
CREATE TABLE IF NOT EXISTS caching_proxy_drive_letters (
    profile text NOT NULL REFERENCES caching_proxy_record_data (profile),
    letter char(1) NOT NULL,
    PRIMARY KEY (profile, letter)
);

CREATE TABLE IF NOT EXISTS caching_proxy_drive_volumes (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    drive_type text NOT NULL, -- \todo enum?
    volume text UNIQUE NOT NULL
);

-- package
----------

CREATE TABLE IF NOT EXISTS caching_proxy_packages (
    profile text NOT NULL REFERENCES caching_proxy_record_data (profile),
    product text NOT NULL, -- \todo better name?
    version text NOT NULL,
    PRIMARY KEY (profile, product)
);

-- \todo is this generic across caching proxy apps? Is there any way to make it generic?
-- one-to-many (ne profile, many plugins)
CREATE TABLE IF NOT EXISTS caching_proxy_plugins (
    profile text PRIMARY KEY REFERENCES caching_proxy_record_data (profile),
    plugin text NOT NULL
);
