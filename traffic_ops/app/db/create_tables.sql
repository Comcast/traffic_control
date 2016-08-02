--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.3
-- Dumped by pg_dump version 9.5.3

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

--
-- Name: on_update_current_timestamp_last_updated(); Type: FUNCTION; Schema: public; Owner: to_user
--

CREATE FUNCTION on_update_current_timestamp_last_updated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.last_updated = now();
   RETURN NEW;
END;
$$;


ALTER FUNCTION public.on_update_current_timestamp_last_updated() OWNER TO to_user;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: asn; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE asn (
    id bigint NOT NULL,
    asn bigint NOT NULL,
    cachegroup bigint DEFAULT '0'::bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE asn OWNER TO to_user;

--
-- Name: asn_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE asn_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE asn_id_seq OWNER TO to_user;

--
-- Name: asn_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE asn_id_seq OWNED BY asn.id;


--
-- Name: cachegroup; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE cachegroup (
    id bigint NOT NULL,
    name character varying(45) NOT NULL,
    short_name character varying(255) NOT NULL,
    latitude numeric,
    longitude numeric,
    parent_cachegroup_id bigint,
    secondary_parent_cachegroup_id bigint,
    type bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE cachegroup OWNER TO to_user;

--
-- Name: cachegroup_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE cachegroup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cachegroup_id_seq OWNER TO to_user;

--
-- Name: cachegroup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE cachegroup_id_seq OWNED BY cachegroup.id;


--
-- Name: cachegroup_parameter; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE cachegroup_parameter (
    cachegroup bigint DEFAULT '0'::bigint NOT NULL,
    parameter bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE cachegroup_parameter OWNER TO to_user;

--
-- Name: cdn; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE cdn (
    id bigint NOT NULL,
    name character varying(127),
    last_updated timestamp with time zone DEFAULT now() NOT NULL,
    dnssec_enabled smallint DEFAULT '0'::smallint NOT NULL
);


ALTER TABLE cdn OWNER TO to_user;

--
-- Name: cdn_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE cdn_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cdn_id_seq OWNER TO to_user;

--
-- Name: cdn_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE cdn_id_seq OWNED BY cdn.id;


--
-- Name: deliveryservice; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE deliveryservice (
    id bigint NOT NULL,
    xml_id character varying(48) NOT NULL,
    active smallint NOT NULL,
    dscp bigint NOT NULL,
    signed smallint,
    qstring_ignore smallint,
    geo_limit boolean DEFAULT false,
    http_bypass_fqdn character varying(255),
    dns_bypass_ip character varying(45),
    dns_bypass_ip6 character varying(45),
    dns_bypass_ttl bigint,
    org_server_fqdn character varying(255),
    type bigint NOT NULL,
    profile bigint NOT NULL,
    cdn_id bigint,
    ccr_dns_ttl bigint,
    global_max_mbps bigint,
    global_max_tps bigint,
    long_desc character varying(1024),
    long_desc_1 character varying(1024),
    long_desc_2 character varying(1024),
    max_dns_answers bigint DEFAULT '0'::bigint,
    info_url character varying(255),
    miss_lat numeric,
    miss_long numeric,
    check_path character varying(255),
    last_updated timestamp with time zone DEFAULT now(),
    protocol smallint DEFAULT '0'::smallint NOT NULL,
    ssl_key_version bigint DEFAULT '0'::bigint,
    ipv6_routing_enabled smallint,
    range_request_handling smallint DEFAULT '0'::smallint,
    edge_header_rewrite character varying(2048),
    origin_shield character varying(1024),
    mid_header_rewrite character varying(2048),
    regex_remap character varying(1024),
    cacheurl character varying(1024),
    remap_text character varying(2048),
    multi_site_origin boolean,
    display_name character varying(48) NOT NULL,
    tr_response_headers character varying(1024),
    initial_dispersion bigint DEFAULT '1'::bigint,
    dns_bypass_cname character varying(255),
    tr_request_headers character varying(1024),
    regional_geo_blocking boolean NOT NULL,
    geo_provider smallint DEFAULT '0'::smallint,
    geo_limit_countries character varying(750),
    logs_enabled boolean,
    multi_site_origin_algorithm boolean
);


ALTER TABLE deliveryservice OWNER TO to_user;

--
-- Name: deliveryservice_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE deliveryservice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE deliveryservice_id_seq OWNER TO to_user;

--
-- Name: deliveryservice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE deliveryservice_id_seq OWNED BY deliveryservice.id;


--
-- Name: deliveryservice_regex; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE deliveryservice_regex (
    deliveryservice bigint NOT NULL,
    regex bigint NOT NULL,
    set_number bigint DEFAULT '0'::bigint
);


ALTER TABLE deliveryservice_regex OWNER TO to_user;

--
-- Name: deliveryservice_server; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE deliveryservice_server (
    deliveryservice bigint NOT NULL,
    server bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE deliveryservice_server OWNER TO to_user;

--
-- Name: deliveryservice_tmuser; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE deliveryservice_tmuser (
    deliveryservice bigint NOT NULL,
    tm_user_id bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE deliveryservice_tmuser OWNER TO to_user;

--
-- Name: division; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE division (
    id bigint NOT NULL,
    name character varying(45) NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE division OWNER TO to_user;

--
-- Name: division_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE division_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE division_id_seq OWNER TO to_user;

--
-- Name: division_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE division_id_seq OWNED BY division.id;


--
-- Name: federation; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE federation (
    id bigint NOT NULL,
    cname character varying(1024) NOT NULL,
    description character varying(1024),
    ttl integer NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE federation OWNER TO to_user;

--
-- Name: federation_deliveryservice; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE federation_deliveryservice (
    federation bigint NOT NULL,
    deliveryservice bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE federation_deliveryservice OWNER TO to_user;

--
-- Name: federation_federation_resolver; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE federation_federation_resolver (
    federation bigint NOT NULL,
    federation_resolver bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE federation_federation_resolver OWNER TO to_user;

--
-- Name: federation_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE federation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE federation_id_seq OWNER TO to_user;

--
-- Name: federation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE federation_id_seq OWNED BY federation.id;


--
-- Name: federation_resolver; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE federation_resolver (
    id bigint NOT NULL,
    ip_address character varying(50) NOT NULL,
    type bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE federation_resolver OWNER TO to_user;

--
-- Name: federation_resolver_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE federation_resolver_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE federation_resolver_id_seq OWNER TO to_user;

--
-- Name: federation_resolver_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE federation_resolver_id_seq OWNED BY federation_resolver.id;


--
-- Name: federation_tmuser; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE federation_tmuser (
    federation bigint NOT NULL,
    tm_user bigint NOT NULL,
    role bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE federation_tmuser OWNER TO to_user;

--
-- Name: goose_db_version; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE goose_db_version (
    id integer NOT NULL,
    version_id bigint NOT NULL,
    is_applied boolean NOT NULL,
    tstamp timestamp without time zone DEFAULT now()
);


ALTER TABLE goose_db_version OWNER TO to_user;

--
-- Name: goose_db_version_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE goose_db_version_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE goose_db_version_id_seq OWNER TO to_user;

--
-- Name: goose_db_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE goose_db_version_id_seq OWNED BY goose_db_version.id;


--
-- Name: hwinfo; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE hwinfo (
    id bigint NOT NULL,
    serverid bigint NOT NULL,
    description character varying(256) NOT NULL,
    val character varying(256) NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE hwinfo OWNER TO to_user;

--
-- Name: hwinfo_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE hwinfo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hwinfo_id_seq OWNER TO to_user;

--
-- Name: hwinfo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE hwinfo_id_seq OWNED BY hwinfo.id;


--
-- Name: job; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE job (
    id bigint NOT NULL,
    agent bigint,
    object_type character varying(48),
    object_name character varying(256),
    keyword character varying(48) NOT NULL,
    parameters character varying(256),
    asset_url character varying(512) NOT NULL,
    asset_type character varying(48) NOT NULL,
    status bigint NOT NULL,
    start_time timestamp with time zone NOT NULL,
    entered_time timestamp with time zone NOT NULL,
    job_user bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now(),
    job_deliveryservice bigint
);


ALTER TABLE job OWNER TO to_user;

--
-- Name: job_agent; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE job_agent (
    id bigint NOT NULL,
    name character varying(128),
    description character varying(512),
    active integer DEFAULT 0 NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE job_agent OWNER TO to_user;

--
-- Name: job_agent_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE job_agent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE job_agent_id_seq OWNER TO to_user;

--
-- Name: job_agent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE job_agent_id_seq OWNED BY job_agent.id;


--
-- Name: job_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE job_id_seq OWNER TO to_user;

--
-- Name: job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE job_id_seq OWNED BY job.id;


--
-- Name: job_result; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE job_result (
    id bigint NOT NULL,
    job bigint NOT NULL,
    agent bigint NOT NULL,
    result character varying(48) NOT NULL,
    description character varying(512),
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE job_result OWNER TO to_user;

--
-- Name: job_result_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE job_result_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE job_result_id_seq OWNER TO to_user;

--
-- Name: job_result_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE job_result_id_seq OWNED BY job_result.id;


--
-- Name: job_status; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE job_status (
    id bigint NOT NULL,
    name character varying(48),
    description character varying(256),
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE job_status OWNER TO to_user;

--
-- Name: job_status_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE job_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE job_status_id_seq OWNER TO to_user;

--
-- Name: job_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE job_status_id_seq OWNED BY job_status.id;


--
-- Name: log; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE log (
    id bigint NOT NULL,
    level character varying(45),
    message character varying(1024) NOT NULL,
    tm_user bigint NOT NULL,
    ticketnum character varying(64),
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE log OWNER TO to_user;

--
-- Name: log_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE log_id_seq OWNER TO to_user;

--
-- Name: log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE log_id_seq OWNED BY log.id;


--
-- Name: parameter; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE parameter (
    id bigint NOT NULL,
    name character varying(1024) NOT NULL,
    config_file character varying(256),
    value character varying(1024) NOT NULL,
    last_updated timestamp with time zone DEFAULT now(),
    secure boolean DEFAULT false NOT NULL
);


ALTER TABLE parameter OWNER TO to_user;

--
-- Name: parameter_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE parameter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE parameter_id_seq OWNER TO to_user;

--
-- Name: parameter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE parameter_id_seq OWNED BY parameter.id;


--
-- Name: phys_location; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE phys_location (
    id bigint NOT NULL,
    name character varying(45) NOT NULL,
    short_name character varying(12) NOT NULL,
    address character varying(128) NOT NULL,
    city character varying(128) NOT NULL,
    state character varying(2) NOT NULL,
    zip character varying(5) NOT NULL,
    poc character varying(128),
    phone character varying(45),
    email character varying(128),
    comments character varying(256),
    region bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE phys_location OWNER TO to_user;

--
-- Name: phys_location_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE phys_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE phys_location_id_seq OWNER TO to_user;

--
-- Name: phys_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE phys_location_id_seq OWNED BY phys_location.id;


--
-- Name: profile; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE profile (
    id bigint NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(256),
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE profile OWNER TO to_user;

--
-- Name: profile_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE profile_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE profile_id_seq OWNER TO to_user;

--
-- Name: profile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE profile_id_seq OWNED BY profile.id;


--
-- Name: profile_parameter; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE profile_parameter (
    profile bigint NOT NULL,
    parameter bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE profile_parameter OWNER TO to_user;

--
-- Name: regex; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE regex (
    id bigint NOT NULL,
    pattern character varying(255) DEFAULT ''::character varying NOT NULL,
    type bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE regex OWNER TO to_user;

--
-- Name: regex_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE regex_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE regex_id_seq OWNER TO to_user;

--
-- Name: regex_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE regex_id_seq OWNED BY regex.id;


--
-- Name: region; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE region (
    id bigint NOT NULL,
    name character varying(45) NOT NULL,
    division bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE region OWNER TO to_user;

--
-- Name: region_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE region_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE region_id_seq OWNER TO to_user;

--
-- Name: region_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE region_id_seq OWNED BY region.id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE role (
    id bigint NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(128),
    priv_level bigint NOT NULL
);


ALTER TABLE role OWNER TO to_user;

--
-- Name: role_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE role_id_seq OWNER TO to_user;

--
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE role_id_seq OWNED BY role.id;


--
-- Name: server; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE server (
    id bigint NOT NULL,
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
    interface_mtu bigint DEFAULT '9000'::bigint NOT NULL,
    phys_location bigint NOT NULL,
    rack character varying(64),
    cachegroup bigint DEFAULT '0'::bigint NOT NULL,
    type bigint NOT NULL,
    status bigint NOT NULL,
    upd_pending boolean DEFAULT false NOT NULL,
    profile bigint NOT NULL,
    cdn_id bigint,
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
    guid character varying(45),
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE server OWNER TO to_user;

--
-- Name: server_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE server_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE server_id_seq OWNER TO to_user;

--
-- Name: server_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE server_id_seq OWNED BY server.id;


--
-- Name: servercheck; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE servercheck (
    id bigint NOT NULL,
    server bigint NOT NULL,
    aa bigint,
    ab bigint,
    ac bigint,
    ad bigint,
    ae bigint,
    af bigint,
    ag bigint,
    ah bigint,
    ai bigint,
    aj bigint,
    ak bigint,
    al bigint,
    am bigint,
    an bigint,
    ao bigint,
    ap bigint,
    aq bigint,
    ar bigint,
    at bigint,
    au bigint,
    av bigint,
    aw bigint,
    ax bigint,
    ay bigint,
    az bigint,
    ba bigint,
    bb bigint,
    bc bigint,
    bd bigint,
    be bigint,
    bf bigint,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE servercheck OWNER TO to_user;

--
-- Name: servercheck_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE servercheck_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE servercheck_id_seq OWNER TO to_user;

--
-- Name: servercheck_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE servercheck_id_seq OWNED BY servercheck.id;


--
-- Name: staticdnsentry; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE staticdnsentry (
    id bigint NOT NULL,
    host character varying(45) NOT NULL,
    address character varying(45) NOT NULL,
    type bigint NOT NULL,
    ttl bigint DEFAULT '3600'::bigint NOT NULL,
    deliveryservice bigint NOT NULL,
    cachegroup bigint,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE staticdnsentry OWNER TO to_user;

--
-- Name: staticdnsentry_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE staticdnsentry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE staticdnsentry_id_seq OWNER TO to_user;

--
-- Name: staticdnsentry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE staticdnsentry_id_seq OWNED BY staticdnsentry.id;


--
-- Name: stats_summary; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE stats_summary (
    id bigint NOT NULL,
    cdn_name character varying(255) DEFAULT 'all'::character varying NOT NULL,
    deliveryservice_name character varying(255) NOT NULL,
    stat_name character varying(255) NOT NULL,
    stat_value double precision NOT NULL,
    summary_time timestamp with time zone DEFAULT now() NOT NULL,
    stat_date date
);


ALTER TABLE stats_summary OWNER TO to_user;

--
-- Name: stats_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE stats_summary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stats_summary_id_seq OWNER TO to_user;

--
-- Name: stats_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE stats_summary_id_seq OWNED BY stats_summary.id;


--
-- Name: status; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE status (
    id bigint NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(256),
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE status OWNER TO to_user;

--
-- Name: status_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE status_id_seq OWNER TO to_user;

--
-- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE status_id_seq OWNED BY status.id;


--
-- Name: steering_target; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE steering_target (
    deliveryservice bigint NOT NULL,
    target bigint NOT NULL,
    weight bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE steering_target OWNER TO to_user;

--
-- Name: tm_user; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE tm_user (
    id bigint NOT NULL,
    username character varying(128),
    public_ssh_key character varying(2048),
    role bigint,
    uid bigint,
    gid bigint,
    local_passwd character varying(40),
    confirm_local_passwd character varying(40),
    last_updated timestamp with time zone DEFAULT now(),
    company character varying(256),
    email character varying(128),
    full_name character varying(256),
    new_user boolean DEFAULT true NOT NULL,
    address_line1 character varying(256),
    address_line2 character varying(256),
    city character varying(128),
    state_or_province character varying(128),
    phone_number character varying(25),
    postal_code character varying(11),
    country character varying(256),
    token character varying(50),
    registration_sent timestamp with time zone DEFAULT '1998-12-31 17:00:00-07'::timestamp with time zone NOT NULL
);


ALTER TABLE tm_user OWNER TO to_user;

--
-- Name: tm_user_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE tm_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tm_user_id_seq OWNER TO to_user;

--
-- Name: tm_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE tm_user_id_seq OWNED BY tm_user.id;


--
-- Name: to_extension; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE to_extension (
    id bigint NOT NULL,
    name character varying(45) NOT NULL,
    version character varying(45) NOT NULL,
    info_url character varying(45) NOT NULL,
    script_file character varying(45) NOT NULL,
    isactive boolean NOT NULL,
    additional_config_json character varying(4096),
    description character varying(4096),
    servercheck_short_name character varying(8),
    servercheck_column_name character varying(10),
    type bigint NOT NULL,
    last_updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE to_extension OWNER TO to_user;

--
-- Name: to_extension_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE to_extension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE to_extension_id_seq OWNER TO to_user;

--
-- Name: to_extension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE to_extension_id_seq OWNED BY to_extension.id;


--
-- Name: type; Type: TABLE; Schema: public; Owner: to_user
--

CREATE TABLE type (
    id bigint NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(256),
    use_in_table character varying(45),
    last_updated timestamp with time zone DEFAULT now()
);


ALTER TABLE type OWNER TO to_user;

--
-- Name: type_id_seq; Type: SEQUENCE; Schema: public; Owner: to_user
--

CREATE SEQUENCE type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE type_id_seq OWNER TO to_user;

--
-- Name: type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: to_user
--

ALTER SEQUENCE type_id_seq OWNED BY type.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY asn ALTER COLUMN id SET DEFAULT nextval('asn_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cachegroup ALTER COLUMN id SET DEFAULT nextval('cachegroup_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cdn ALTER COLUMN id SET DEFAULT nextval('cdn_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice ALTER COLUMN id SET DEFAULT nextval('deliveryservice_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY division ALTER COLUMN id SET DEFAULT nextval('division_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation ALTER COLUMN id SET DEFAULT nextval('federation_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_resolver ALTER COLUMN id SET DEFAULT nextval('federation_resolver_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY goose_db_version ALTER COLUMN id SET DEFAULT nextval('goose_db_version_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY hwinfo ALTER COLUMN id SET DEFAULT nextval('hwinfo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job ALTER COLUMN id SET DEFAULT nextval('job_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job_agent ALTER COLUMN id SET DEFAULT nextval('job_agent_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job_result ALTER COLUMN id SET DEFAULT nextval('job_result_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job_status ALTER COLUMN id SET DEFAULT nextval('job_status_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY log ALTER COLUMN id SET DEFAULT nextval('log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY parameter ALTER COLUMN id SET DEFAULT nextval('parameter_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY phys_location ALTER COLUMN id SET DEFAULT nextval('phys_location_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY profile ALTER COLUMN id SET DEFAULT nextval('profile_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY regex ALTER COLUMN id SET DEFAULT nextval('regex_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY region ALTER COLUMN id SET DEFAULT nextval('region_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY role ALTER COLUMN id SET DEFAULT nextval('role_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY server ALTER COLUMN id SET DEFAULT nextval('server_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY servercheck ALTER COLUMN id SET DEFAULT nextval('servercheck_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY staticdnsentry ALTER COLUMN id SET DEFAULT nextval('staticdnsentry_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY stats_summary ALTER COLUMN id SET DEFAULT nextval('stats_summary_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY status ALTER COLUMN id SET DEFAULT nextval('status_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY tm_user ALTER COLUMN id SET DEFAULT nextval('tm_user_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY to_extension ALTER COLUMN id SET DEFAULT nextval('to_extension_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY type ALTER COLUMN id SET DEFAULT nextval('type_id_seq'::regclass);


--
-- Data for Name: asn; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY asn (id, asn, cachegroup, last_updated) FROM stdin;
\.


--
-- Name: asn_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('asn_id_seq', 1, true);


--
-- Data for Name: cachegroup; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY cachegroup (id, name, short_name, latitude, longitude, parent_cachegroup_id, secondary_parent_cachegroup_id, type, last_updated) FROM stdin;
\.


--
-- Name: cachegroup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('cachegroup_id_seq', 1, true);


--
-- Data for Name: cachegroup_parameter; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY cachegroup_parameter (cachegroup, parameter, last_updated) FROM stdin;
\.


--
-- Data for Name: cdn; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY cdn (id, name, last_updated, dnssec_enabled) FROM stdin;
\.


--
-- Name: cdn_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('cdn_id_seq', 1, true);


--
-- Data for Name: deliveryservice; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY deliveryservice (id, xml_id, active, dscp, signed, qstring_ignore, geo_limit, http_bypass_fqdn, dns_bypass_ip, dns_bypass_ip6, dns_bypass_ttl, org_server_fqdn, type, profile, cdn_id, ccr_dns_ttl, global_max_mbps, global_max_tps, long_desc, long_desc_1, long_desc_2, max_dns_answers, info_url, miss_lat, miss_long, check_path, last_updated, protocol, ssl_key_version, ipv6_routing_enabled, range_request_handling, edge_header_rewrite, origin_shield, mid_header_rewrite, regex_remap, cacheurl, remap_text, multi_site_origin, display_name, tr_response_headers, initial_dispersion, dns_bypass_cname, tr_request_headers, regional_geo_blocking, geo_provider, geo_limit_countries, logs_enabled, multi_site_origin_algorithm) FROM stdin;
\.


--
-- Name: deliveryservice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('deliveryservice_id_seq', 1, true);


--
-- Data for Name: deliveryservice_regex; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY deliveryservice_regex (deliveryservice, regex, set_number) FROM stdin;
\.


--
-- Data for Name: deliveryservice_server; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY deliveryservice_server (deliveryservice, server, last_updated) FROM stdin;
\.


--
-- Data for Name: deliveryservice_tmuser; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY deliveryservice_tmuser (deliveryservice, tm_user_id, last_updated) FROM stdin;
\.


--
-- Data for Name: division; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY division (id, name, last_updated) FROM stdin;
\.


--
-- Name: division_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('division_id_seq', 1, true);


--
-- Data for Name: federation; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY federation (id, cname, description, ttl, last_updated) FROM stdin;
\.


--
-- Data for Name: federation_deliveryservice; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY federation_deliveryservice (federation, deliveryservice, last_updated) FROM stdin;
\.


--
-- Data for Name: federation_federation_resolver; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY federation_federation_resolver (federation, federation_resolver, last_updated) FROM stdin;
\.


--
-- Name: federation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('federation_id_seq', 1, true);


--
-- Data for Name: federation_resolver; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY federation_resolver (id, ip_address, type, last_updated) FROM stdin;
\.


--
-- Name: federation_resolver_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('federation_resolver_id_seq', 1, true);


--
-- Data for Name: federation_tmuser; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY federation_tmuser (federation, tm_user, role, last_updated) FROM stdin;
\.


--
-- Data for Name: goose_db_version; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY goose_db_version (id, version_id, is_applied, tstamp) FROM stdin;
\.


--
-- Name: goose_db_version_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('goose_db_version_id_seq', 2, true);


--
-- Data for Name: hwinfo; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY hwinfo (id, serverid, description, val, last_updated) FROM stdin;
\.


--
-- Name: hwinfo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('hwinfo_id_seq', 1, true);


--
-- Data for Name: job; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY job (id, agent, object_type, object_name, keyword, parameters, asset_url, asset_type, status, start_time, entered_time, job_user, last_updated, job_deliveryservice) FROM stdin;
\.


--
-- Data for Name: job_agent; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY job_agent (id, name, description, active, last_updated) FROM stdin;
\.


--
-- Name: job_agent_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('job_agent_id_seq', 1, true);


--
-- Name: job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('job_id_seq', 1, true);


--
-- Data for Name: job_result; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY job_result (id, job, agent, result, description, last_updated) FROM stdin;
\.


--
-- Name: job_result_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('job_result_id_seq', 1, true);


--
-- Data for Name: job_status; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY job_status (id, name, description, last_updated) FROM stdin;
\.


--
-- Name: job_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('job_status_id_seq', 1, true);


--
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY log (id, level, message, tm_user, ticketnum, last_updated) FROM stdin;
\.


--
-- Name: log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('log_id_seq', 1, true);


--
-- Data for Name: parameter; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY parameter (id, name, config_file, value, last_updated, secure) FROM stdin;
\.


--
-- Name: parameter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('parameter_id_seq', 1, true);


--
-- Data for Name: phys_location; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY phys_location (id, name, short_name, address, city, state, zip, poc, phone, email, comments, region, last_updated) FROM stdin;
\.


--
-- Name: phys_location_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('phys_location_id_seq', 1, true);


--
-- Data for Name: profile; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY profile (id, name, description, last_updated) FROM stdin;
\.


--
-- Name: profile_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('profile_id_seq', 1, true);


--
-- Data for Name: profile_parameter; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY profile_parameter (profile, parameter, last_updated) FROM stdin;
\.


--
-- Data for Name: regex; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY regex (id, pattern, type, last_updated) FROM stdin;
\.


--
-- Name: regex_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('regex_id_seq', 1, true);


--
-- Data for Name: region; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY region (id, name, division, last_updated) FROM stdin;
\.


--
-- Name: region_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('region_id_seq', 1, true);


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY role (id, name, description, priv_level) FROM stdin;
\.


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('role_id_seq', 1, true);


--
-- Data for Name: server; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY server (id, host_name, domain_name, tcp_port, xmpp_id, xmpp_passwd, interface_name, ip_address, ip_netmask, ip_gateway, ip6_address, ip6_gateway, interface_mtu, phys_location, rack, cachegroup, type, status, upd_pending, profile, cdn_id, mgmt_ip_address, mgmt_ip_netmask, mgmt_ip_gateway, ilo_ip_address, ilo_ip_netmask, ilo_ip_gateway, ilo_username, ilo_password, router_host_name, router_port_name, guid, last_updated) FROM stdin;
\.


--
-- Name: server_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('server_id_seq', 1, true);


--
-- Data for Name: servercheck; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY servercheck (id, server, aa, ab, ac, ad, ae, af, ag, ah, ai, aj, ak, al, am, an, ao, ap, aq, ar, at, au, av, aw, ax, ay, az, ba, bb, bc, bd, be, bf last_updated) FROM stdin;
\.


--
-- Name: servercheck_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('servercheck_id_seq', 1, true);


--
-- Data for Name: staticdnsentry; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY staticdnsentry (id, host, address, type, ttl, deliveryservice, cachegroup, last_updated) FROM stdin;
\.


--
-- Name: staticdnsentry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('staticdnsentry_id_seq', 1, true);


--
-- Data for Name: stats_summary; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY stats_summary (id, cdn_name, deliveryservice_name, stat_name, stat_value, summary_time, stat_date) FROM stdin;
\.


--
-- Name: stats_summary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('stats_summary_id_seq', 1, true);


--
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY status (id, name, description, last_updated) FROM stdin;
\.


--
-- Name: status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('status_id_seq', 1, true);


--
-- Data for Name: steering_target; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY steering_target (deliveryservice, target, weight, last_updated) FROM stdin;
\.


--
-- Data for Name: tm_user; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY tm_user (id, username, public_ssh_key, role, uid, gid, local_passwd, confirm_local_passwd, last_updated, company, email, full_name, new_user, address_line1, address_line2, city, state_or_province, phone_number, postal_code, country, token, registration_sent) FROM stdin;
\.


--
-- Name: tm_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('tm_user_id_seq', 1, true);


--
-- Data for Name: to_extension; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY to_extension (id, name, version, info_url, script_file, isactive, additional_config_json, description, servercheck_short_name, servercheck_column_name, type, last_updated) FROM stdin;
\.


--
-- Name: to_extension_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('to_extension_id_seq', 1, true);


--
-- Data for Name: type; Type: TABLE DATA; Schema: public; Owner: to_user
--

COPY type (id, name, description, use_in_table, last_updated) FROM stdin;
\.


--
-- Name: type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: to_user
--

SELECT pg_catalog.setval('type_id_seq', 1, true);


--
-- Name: goose_db_version_pkey; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY goose_db_version
    ADD CONSTRAINT goose_db_version_pkey PRIMARY KEY (id);


--
-- Name: idx_61982_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY asn
    ADD CONSTRAINT idx_61982_primary PRIMARY KEY (id, cachegroup);


--
-- Name: idx_61992_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT idx_61992_primary PRIMARY KEY (id, type);


--
-- Name: idx_61998_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cachegroup_parameter
    ADD CONSTRAINT idx_61998_primary PRIMARY KEY (cachegroup, parameter);


--
-- Name: idx_62006_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cdn
    ADD CONSTRAINT idx_62006_primary PRIMARY KEY (id);


--
-- Name: idx_62015_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT idx_62015_primary PRIMARY KEY (id, type);


--
-- Name: idx_62031_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice_regex
    ADD CONSTRAINT idx_62031_primary PRIMARY KEY (deliveryservice, regex);


--
-- Name: idx_62035_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice_server
    ADD CONSTRAINT idx_62035_primary PRIMARY KEY (deliveryservice, server);


--
-- Name: idx_62040_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice_tmuser
    ADD CONSTRAINT idx_62040_primary PRIMARY KEY (deliveryservice, tm_user_id);


--
-- Name: idx_62047_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY division
    ADD CONSTRAINT idx_62047_primary PRIMARY KEY (id);


--
-- Name: idx_62055_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation
    ADD CONSTRAINT idx_62055_primary PRIMARY KEY (id);


--
-- Name: idx_62064_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_deliveryservice
    ADD CONSTRAINT idx_62064_primary PRIMARY KEY (federation, deliveryservice);


--
-- Name: idx_62069_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_federation_resolver
    ADD CONSTRAINT idx_62069_primary PRIMARY KEY (federation, federation_resolver);


--
-- Name: idx_62076_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_resolver
    ADD CONSTRAINT idx_62076_primary PRIMARY KEY (id);


--
-- Name: idx_62082_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT idx_62082_primary PRIMARY KEY (federation, tm_user);


--
-- Name: idx_62089_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY hwinfo
    ADD CONSTRAINT idx_62089_primary PRIMARY KEY (id);


--
-- Name: idx_62100_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job
    ADD CONSTRAINT idx_62100_primary PRIMARY KEY (id);


--
-- Name: idx_62111_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job_agent
    ADD CONSTRAINT idx_62111_primary PRIMARY KEY (id);


--
-- Name: idx_62123_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job_result
    ADD CONSTRAINT idx_62123_primary PRIMARY KEY (id);


--
-- Name: idx_62134_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job_status
    ADD CONSTRAINT idx_62134_primary PRIMARY KEY (id);


--
-- Name: idx_62142_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY log
    ADD CONSTRAINT idx_62142_primary PRIMARY KEY (id, tm_user);


--
-- Name: idx_62153_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY parameter
    ADD CONSTRAINT idx_62153_primary PRIMARY KEY (id);


--
-- Name: idx_62165_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY phys_location
    ADD CONSTRAINT idx_62165_primary PRIMARY KEY (id);


--
-- Name: idx_62176_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY profile
    ADD CONSTRAINT idx_62176_primary PRIMARY KEY (id);


--
-- Name: idx_62182_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY profile_parameter
    ADD CONSTRAINT idx_62182_primary PRIMARY KEY (profile, parameter);


--
-- Name: idx_62189_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY regex
    ADD CONSTRAINT idx_62189_primary PRIMARY KEY (id, type);


--
-- Name: idx_62198_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY region
    ADD CONSTRAINT idx_62198_primary PRIMARY KEY (id);


--
-- Name: idx_62206_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY role
    ADD CONSTRAINT idx_62206_primary PRIMARY KEY (id);


--
-- Name: idx_62212_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY server
    ADD CONSTRAINT idx_62212_primary PRIMARY KEY (id, cachegroup, type, status, profile);


--
-- Name: idx_62226_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY servercheck
    ADD CONSTRAINT idx_62226_primary PRIMARY KEY (id, server);


--
-- Name: idx_62234_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT idx_62234_primary PRIMARY KEY (id);


--
-- Name: idx_62243_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY stats_summary
    ADD CONSTRAINT idx_62243_primary PRIMARY KEY (id);


--
-- Name: idx_62254_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY status
    ADD CONSTRAINT idx_62254_primary PRIMARY KEY (id);


--
-- Name: idx_62260_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY steering_target
    ADD CONSTRAINT idx_62260_primary PRIMARY KEY (deliveryservice, target);


--
-- Name: idx_62267_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY tm_user
    ADD CONSTRAINT idx_62267_primary PRIMARY KEY (id);


--
-- Name: idx_62280_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY to_extension
    ADD CONSTRAINT idx_62280_primary PRIMARY KEY (id);


--
-- Name: idx_62290_primary; Type: CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY type
    ADD CONSTRAINT idx_62290_primary PRIMARY KEY (id);


--
-- Name: idx_61982_cr_id_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_61982_cr_id_unique ON asn USING btree (id);


--
-- Name: idx_61982_fk_cran_cachegroup1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_61982_fk_cran_cachegroup1 ON asn USING btree (cachegroup);


--
-- Name: idx_61992_cg_name_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_61992_cg_name_unique ON cachegroup USING btree (name);


--
-- Name: idx_61992_cg_short_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_61992_cg_short_unique ON cachegroup USING btree (short_name);


--
-- Name: idx_61992_fk_cg_1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_61992_fk_cg_1 ON cachegroup USING btree (parent_cachegroup_id);


--
-- Name: idx_61992_fk_cg_secondary; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_61992_fk_cg_secondary ON cachegroup USING btree (secondary_parent_cachegroup_id);


--
-- Name: idx_61992_fk_cg_type1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_61992_fk_cg_type1 ON cachegroup USING btree (type);


--
-- Name: idx_61992_lo_id_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_61992_lo_id_unique ON cachegroup USING btree (id);


--
-- Name: idx_61998_fk_parameter; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_61998_fk_parameter ON cachegroup_parameter USING btree (parameter);


--
-- Name: idx_62006_cdn_cdn_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62006_cdn_cdn_unique ON cdn USING btree (name);


--
-- Name: idx_62015_ds_id_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62015_ds_id_unique ON deliveryservice USING btree (id);


--
-- Name: idx_62015_ds_name_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62015_ds_name_unique ON deliveryservice USING btree (xml_id);


--
-- Name: idx_62015_fk_cdn1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62015_fk_cdn1 ON deliveryservice USING btree (cdn_id);


--
-- Name: idx_62015_fk_deliveryservice_profile1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62015_fk_deliveryservice_profile1 ON deliveryservice USING btree (profile);


--
-- Name: idx_62015_fk_deliveryservice_type1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62015_fk_deliveryservice_type1 ON deliveryservice USING btree (type);


--
-- Name: idx_62031_fk_ds_to_regex_regex1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62031_fk_ds_to_regex_regex1 ON deliveryservice_regex USING btree (regex);


--
-- Name: idx_62035_fk_ds_to_cs_contentserver1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62035_fk_ds_to_cs_contentserver1 ON deliveryservice_server USING btree (server);


--
-- Name: idx_62040_fk_tm_userid; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62040_fk_tm_userid ON deliveryservice_tmuser USING btree (tm_user_id);


--
-- Name: idx_62047_name_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62047_name_unique ON division USING btree (name);


--
-- Name: idx_62064_fk_fed_to_ds1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62064_fk_fed_to_ds1 ON federation_deliveryservice USING btree (deliveryservice);


--
-- Name: idx_62069_fk_federation_federation_resolver; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62069_fk_federation_federation_resolver ON federation_federation_resolver USING btree (federation);


--
-- Name: idx_62069_fk_federation_resolver_to_fed1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62069_fk_federation_resolver_to_fed1 ON federation_federation_resolver USING btree (federation_resolver);


--
-- Name: idx_62076_federation_resolver_ip_address; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62076_federation_resolver_ip_address ON federation_resolver USING btree (ip_address);


--
-- Name: idx_62076_fk_federation_mapping_type; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62076_fk_federation_mapping_type ON federation_resolver USING btree (type);


--
-- Name: idx_62082_fk_federation_federation_resolver; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62082_fk_federation_federation_resolver ON federation_tmuser USING btree (federation);


--
-- Name: idx_62082_fk_federation_tmuser_role; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62082_fk_federation_tmuser_role ON federation_tmuser USING btree (role);


--
-- Name: idx_62082_fk_federation_tmuser_tmuser; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62082_fk_federation_tmuser_tmuser ON federation_tmuser USING btree (tm_user);


--
-- Name: idx_62089_fk_hwinfo1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62089_fk_hwinfo1 ON hwinfo USING btree (serverid);


--
-- Name: idx_62089_serverid; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62089_serverid ON hwinfo USING btree (serverid, description);


--
-- Name: idx_62100_fk_job_agent_id1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62100_fk_job_agent_id1 ON job USING btree (agent);


--
-- Name: idx_62100_fk_job_deliveryservice1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62100_fk_job_deliveryservice1 ON job USING btree (job_deliveryservice);


--
-- Name: idx_62100_fk_job_status_id1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62100_fk_job_status_id1 ON job USING btree (status);


--
-- Name: idx_62100_fk_job_user_id1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62100_fk_job_user_id1 ON job USING btree (job_user);


--
-- Name: idx_62123_fk_agent_id1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62123_fk_agent_id1 ON job_result USING btree (agent);


--
-- Name: idx_62123_fk_job_id1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62123_fk_job_id1 ON job_result USING btree (job);


--
-- Name: idx_62142_fk_log_1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62142_fk_log_1 ON log USING btree (tm_user);


--
-- Name: idx_62153_parameter_name_value_idx; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62153_parameter_name_value_idx ON parameter USING btree (name, value);


--
-- Name: idx_62165_fk_phys_location_region_idx; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62165_fk_phys_location_region_idx ON phys_location USING btree (region);


--
-- Name: idx_62165_name_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62165_name_unique ON phys_location USING btree (name);


--
-- Name: idx_62165_short_name_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62165_short_name_unique ON phys_location USING btree (short_name);


--
-- Name: idx_62176_name_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62176_name_unique ON profile USING btree (name);


--
-- Name: idx_62182_fk_atsprofile_atsparameters_atsparameters1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62182_fk_atsprofile_atsparameters_atsparameters1 ON profile_parameter USING btree (parameter);


--
-- Name: idx_62182_fk_atsprofile_atsparameters_atsprofile1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62182_fk_atsprofile_atsparameters_atsprofile1 ON profile_parameter USING btree (profile);


--
-- Name: idx_62189_fk_regex_type1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62189_fk_regex_type1 ON regex USING btree (type);


--
-- Name: idx_62189_re_id_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62189_re_id_unique ON regex USING btree (id);


--
-- Name: idx_62198_fk_region_division1_idx; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62198_fk_region_division1_idx ON region USING btree (division);


--
-- Name: idx_62198_name_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62198_name_unique ON region USING btree (name);


--
-- Name: idx_62212_cs_ip_address_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62212_cs_ip_address_unique ON server USING btree (ip_address);


--
-- Name: idx_62212_fk_cdn2; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62212_fk_cdn2 ON server USING btree (cdn_id);


--
-- Name: idx_62212_fk_contentserver_atsprofile1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62212_fk_contentserver_atsprofile1 ON server USING btree (profile);


--
-- Name: idx_62212_fk_contentserver_contentserverstatus1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62212_fk_contentserver_contentserverstatus1 ON server USING btree (status);


--
-- Name: idx_62212_fk_contentserver_contentservertype1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62212_fk_contentserver_contentservertype1 ON server USING btree (type);


--
-- Name: idx_62212_fk_contentserver_phys_location1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62212_fk_contentserver_phys_location1 ON server USING btree (phys_location);


--
-- Name: idx_62212_fk_server_cachegroup1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62212_fk_server_cachegroup1 ON server USING btree (cachegroup);


--
-- Name: idx_62212_host_name; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62212_host_name ON server USING btree (host_name);


--
-- Name: idx_62212_ip6_address; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62212_ip6_address ON server USING btree (ip6_address);


--
-- Name: idx_62212_se_id_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62212_se_id_unique ON server USING btree (id);


--
-- Name: idx_62226_fk_serverstatus_server1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62226_fk_serverstatus_server1 ON servercheck USING btree (server);


--
-- Name: idx_62226_server; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62226_server ON servercheck USING btree (server);


--
-- Name: idx_62226_ses_id_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62226_ses_id_unique ON servercheck USING btree (id);


--
-- Name: idx_62234_combi_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62234_combi_unique ON staticdnsentry USING btree (host, address, deliveryservice, cachegroup);


--
-- Name: idx_62234_fk_staticdnsentry_cachegroup1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62234_fk_staticdnsentry_cachegroup1 ON staticdnsentry USING btree (cachegroup);


--
-- Name: idx_62234_fk_staticdnsentry_ds; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62234_fk_staticdnsentry_ds ON staticdnsentry USING btree (deliveryservice);


--
-- Name: idx_62234_fk_staticdnsentry_type; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62234_fk_staticdnsentry_type ON staticdnsentry USING btree (type);


--
-- Name: idx_62267_fk_user_1; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62267_fk_user_1 ON tm_user USING btree (role);


--
-- Name: idx_62267_tmuser_email_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62267_tmuser_email_unique ON tm_user USING btree (email);


--
-- Name: idx_62267_username_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62267_username_unique ON tm_user USING btree (username);


--
-- Name: idx_62280_fk_ext_type_idx; Type: INDEX; Schema: public; Owner: to_user
--

CREATE INDEX idx_62280_fk_ext_type_idx ON to_extension USING btree (type);


--
-- Name: idx_62280_id_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62280_id_unique ON to_extension USING btree (id);


--
-- Name: idx_62290_name_unique; Type: INDEX; Schema: public; Owner: to_user
--

CREATE UNIQUE INDEX idx_62290_name_unique ON type USING btree (name);


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON asn FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON cachegroup FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON cachegroup_parameter FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON cdn FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON deliveryservice FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON deliveryservice_server FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON deliveryservice_tmuser FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON division FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON federation FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON federation_deliveryservice FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON federation_federation_resolver FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON federation_resolver FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON federation_tmuser FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON hwinfo FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON job FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON job_agent FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON job_result FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON job_status FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON log FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON parameter FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON phys_location FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON profile FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON profile_parameter FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON regex FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON region FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON server FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON servercheck FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON staticdnsentry FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON status FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON steering_target FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON tm_user FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: on_update_current_timestamp; Type: TRIGGER; Schema: public; Owner: to_user
--

CREATE TRIGGER on_update_current_timestamp BEFORE UPDATE ON type FOR EACH ROW EXECUTE PROCEDURE on_update_current_timestamp_last_updated();


--
-- Name: fk_agent_id1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job_result
    ADD CONSTRAINT fk_agent_id1 FOREIGN KEY (agent) REFERENCES job_agent(id) ON DELETE CASCADE;


--
-- Name: fk_atsprofile_atsparameters_atsparameters1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY profile_parameter
    ADD CONSTRAINT fk_atsprofile_atsparameters_atsparameters1 FOREIGN KEY (parameter) REFERENCES parameter(id) ON DELETE CASCADE;


--
-- Name: fk_atsprofile_atsparameters_atsprofile1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY profile_parameter
    ADD CONSTRAINT fk_atsprofile_atsparameters_atsprofile1 FOREIGN KEY (profile) REFERENCES profile(id) ON DELETE CASCADE;


--
-- Name: fk_cdn1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT fk_cdn1 FOREIGN KEY (cdn_id) REFERENCES cdn(id) ON UPDATE RESTRICT ON DELETE SET NULL;


--
-- Name: fk_cdn2; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY server
    ADD CONSTRAINT fk_cdn2 FOREIGN KEY (cdn_id) REFERENCES cdn(id) ON UPDATE RESTRICT ON DELETE SET NULL;


--
-- Name: fk_cg_1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT fk_cg_1 FOREIGN KEY (parent_cachegroup_id) REFERENCES cachegroup(id);


--
-- Name: fk_cg_param_cachegroup1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cachegroup_parameter
    ADD CONSTRAINT fk_cg_param_cachegroup1 FOREIGN KEY (cachegroup) REFERENCES cachegroup(id) ON DELETE CASCADE;


--
-- Name: fk_cg_secondary; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT fk_cg_secondary FOREIGN KEY (secondary_parent_cachegroup_id) REFERENCES cachegroup(id);


--
-- Name: fk_cg_type1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT fk_cg_type1 FOREIGN KEY (type) REFERENCES type(id);


--
-- Name: fk_contentserver_atsprofile1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY server
    ADD CONSTRAINT fk_contentserver_atsprofile1 FOREIGN KEY (profile) REFERENCES profile(id);


--
-- Name: fk_contentserver_contentserverstatus1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY server
    ADD CONSTRAINT fk_contentserver_contentserverstatus1 FOREIGN KEY (status) REFERENCES status(id);


--
-- Name: fk_contentserver_contentservertype1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY server
    ADD CONSTRAINT fk_contentserver_contentservertype1 FOREIGN KEY (type) REFERENCES type(id);


--
-- Name: fk_contentserver_phys_location1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY server
    ADD CONSTRAINT fk_contentserver_phys_location1 FOREIGN KEY (phys_location) REFERENCES phys_location(id);


--
-- Name: fk_cran_cachegroup1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY asn
    ADD CONSTRAINT fk_cran_cachegroup1 FOREIGN KEY (cachegroup) REFERENCES cachegroup(id);


--
-- Name: fk_deliveryservice_profile1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT fk_deliveryservice_profile1 FOREIGN KEY (profile) REFERENCES profile(id);


--
-- Name: fk_deliveryservice_type1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT fk_deliveryservice_type1 FOREIGN KEY (type) REFERENCES type(id);


--
-- Name: fk_ds_to_cs_contentserver1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice_server
    ADD CONSTRAINT fk_ds_to_cs_contentserver1 FOREIGN KEY (server) REFERENCES server(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_ds_to_cs_deliveryservice1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice_server
    ADD CONSTRAINT fk_ds_to_cs_deliveryservice1 FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_ds_to_regex_deliveryservice1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice_regex
    ADD CONSTRAINT fk_ds_to_regex_deliveryservice1 FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_ds_to_regex_regex1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice_regex
    ADD CONSTRAINT fk_ds_to_regex_regex1 FOREIGN KEY (regex) REFERENCES regex(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_ext_type; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY to_extension
    ADD CONSTRAINT fk_ext_type FOREIGN KEY (type) REFERENCES type(id);


--
-- Name: fk_federation_federation_resolver1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_federation_resolver
    ADD CONSTRAINT fk_federation_federation_resolver1 FOREIGN KEY (federation) REFERENCES federation(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_federation_mapping_type; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_resolver
    ADD CONSTRAINT fk_federation_mapping_type FOREIGN KEY (type) REFERENCES type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_federation_resolver_to_fed1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_federation_resolver
    ADD CONSTRAINT fk_federation_resolver_to_fed1 FOREIGN KEY (federation_resolver) REFERENCES federation_resolver(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_federation_tmuser_federation; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT fk_federation_tmuser_federation FOREIGN KEY (federation) REFERENCES federation(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_federation_tmuser_role; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT fk_federation_tmuser_role FOREIGN KEY (role) REFERENCES role(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_federation_tmuser_tmuser; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT fk_federation_tmuser_tmuser FOREIGN KEY (tm_user) REFERENCES tm_user(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_federation_to_ds1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_deliveryservice
    ADD CONSTRAINT fk_federation_to_ds1 FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_federation_to_fed1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY federation_deliveryservice
    ADD CONSTRAINT fk_federation_to_fed1 FOREIGN KEY (federation) REFERENCES federation(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_hwinfo1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY hwinfo
    ADD CONSTRAINT fk_hwinfo1 FOREIGN KEY (serverid) REFERENCES server(id) ON DELETE CASCADE;


--
-- Name: fk_job_agent_id1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job
    ADD CONSTRAINT fk_job_agent_id1 FOREIGN KEY (agent) REFERENCES job_agent(id) ON DELETE CASCADE;


--
-- Name: fk_job_deliveryservice1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job
    ADD CONSTRAINT fk_job_deliveryservice1 FOREIGN KEY (job_deliveryservice) REFERENCES deliveryservice(id);


--
-- Name: fk_job_id1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job_result
    ADD CONSTRAINT fk_job_id1 FOREIGN KEY (job) REFERENCES job(id) ON DELETE CASCADE;


--
-- Name: fk_job_status_id1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job
    ADD CONSTRAINT fk_job_status_id1 FOREIGN KEY (status) REFERENCES job_status(id);


--
-- Name: fk_job_user_id1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY job
    ADD CONSTRAINT fk_job_user_id1 FOREIGN KEY (job_user) REFERENCES tm_user(id);


--
-- Name: fk_log_1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY log
    ADD CONSTRAINT fk_log_1 FOREIGN KEY (tm_user) REFERENCES tm_user(id);


--
-- Name: fk_parameter; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY cachegroup_parameter
    ADD CONSTRAINT fk_parameter FOREIGN KEY (parameter) REFERENCES parameter(id) ON DELETE CASCADE;


--
-- Name: fk_phys_location_region; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY phys_location
    ADD CONSTRAINT fk_phys_location_region FOREIGN KEY (region) REFERENCES region(id);


--
-- Name: fk_regex_type1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY regex
    ADD CONSTRAINT fk_regex_type1 FOREIGN KEY (type) REFERENCES type(id);


--
-- Name: fk_region_division1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY region
    ADD CONSTRAINT fk_region_division1 FOREIGN KEY (division) REFERENCES division(id);


--
-- Name: fk_server_cachegroup1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY server
    ADD CONSTRAINT fk_server_cachegroup1 FOREIGN KEY (cachegroup) REFERENCES cachegroup(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: fk_serverstatus_server1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY servercheck
    ADD CONSTRAINT fk_serverstatus_server1 FOREIGN KEY (server) REFERENCES server(id) ON DELETE CASCADE;


--
-- Name: fk_staticdnsentry_cachegroup1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT fk_staticdnsentry_cachegroup1 FOREIGN KEY (cachegroup) REFERENCES cachegroup(id);


--
-- Name: fk_staticdnsentry_ds; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT fk_staticdnsentry_ds FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id);


--
-- Name: fk_staticdnsentry_type; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT fk_staticdnsentry_type FOREIGN KEY (type) REFERENCES type(id);


--
-- Name: fk_steering_target_delivery_service; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY steering_target
    ADD CONSTRAINT fk_steering_target_delivery_service FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_steering_target_target; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY steering_target
    ADD CONSTRAINT fk_steering_target_target FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_tm_user_ds; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice_tmuser
    ADD CONSTRAINT fk_tm_user_ds FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_tm_user_id; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY deliveryservice_tmuser
    ADD CONSTRAINT fk_tm_user_id FOREIGN KEY (tm_user_id) REFERENCES tm_user(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_user_1; Type: FK CONSTRAINT; Schema: public; Owner: to_user
--

ALTER TABLE ONLY tm_user
    ADD CONSTRAINT fk_user_1 FOREIGN KEY (role) REFERENCES role(id) ON DELETE SET NULL;


--
-- Name: public; Type: ACL; Schema: -; Owner: to_user
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM to_user;
GRANT ALL ON SCHEMA public TO to_user;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--
