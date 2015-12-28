--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.5
-- Dumped by pg_dump version 9.4.5
-- Started on 2015-12-26 15:32:00 MST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 236 (class 3079 OID 11975)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2579 (class 0 OID 0)
-- Dependencies: 236
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 172 (class 1259 OID 27574)
-- Name: asn; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE asn (
    id integer NOT NULL,
    asn integer NOT NULL,
    cachegroup integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE asn OWNER TO tm_user;

--
-- TOC entry 208 (class 1259 OID 27725)
-- Name: asn_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE asn_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE asn_id_seq OWNER TO tm_user;

--
-- TOC entry 2580 (class 0 OID 0)
-- Dependencies: 208
-- Name: asn_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE asn_id_seq OWNED BY asn.id;


--
-- TOC entry 173 (class 1259 OID 27577)
-- Name: cachegroup; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE cachegroup (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    short_name character varying(255) NOT NULL,
    latitude double precision,
    longitude double precision,
    parent_cachegroup_id integer,
    type integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE cachegroup OWNER TO tm_user;

--
-- TOC entry 209 (class 1259 OID 27735)
-- Name: cachegroup_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cachegroup_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cachegroup_id_seq OWNER TO tm_user;

--
-- TOC entry 2581 (class 0 OID 0)
-- Dependencies: 209
-- Name: cachegroup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE cachegroup_id_seq OWNED BY cachegroup.id;


--
-- TOC entry 174 (class 1259 OID 27580)
-- Name: cachegroup_parameter; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE cachegroup_parameter (
    cachegroup integer NOT NULL,
    parameter integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE cachegroup_parameter OWNER TO tm_user;

--
-- TOC entry 175 (class 1259 OID 27583)
-- Name: cdn; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE cdn (
    id integer NOT NULL,
    name character varying(127),
    last_updated timestamp without time zone DEFAULT now() NOT NULL,
    dnssec_enabled smallint
);


ALTER TABLE cdn OWNER TO tm_user;

--
-- TOC entry 210 (class 1259 OID 27750)
-- Name: cdn_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cdn_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cdn_id_seq OWNER TO tm_user;

--
-- TOC entry 2582 (class 0 OID 0)
-- Dependencies: 210
-- Name: cdn_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE cdn_id_seq OWNED BY cdn.id;


--
-- TOC entry 176 (class 1259 OID 27586)
-- Name: deliveryservice; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE deliveryservice (
    id integer NOT NULL,
    xml_id character varying(48) NOT NULL,
    active smallint NOT NULL,
    dscp integer NOT NULL,
    signed smallint,
    qstring_ignore smallint,
    geo_limit smallint,
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
    max_dns_answers integer,
    info_url character varying(255),
    miss_lat double precision,
    miss_long double precision,
    check_path character varying(255),
    last_updated timestamp without time zone DEFAULT now(),
    protocol smallint,
    ssl_key_version integer,
    ipv6_routing_enabled smallint,
    range_request_handling smallint,
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


ALTER TABLE deliveryservice OWNER TO tm_user;

--
-- TOC entry 211 (class 1259 OID 27759)
-- Name: deliveryservice_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE deliveryservice_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE deliveryservice_id_seq OWNER TO tm_user;

--
-- TOC entry 2583 (class 0 OID 0)
-- Dependencies: 211
-- Name: deliveryservice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE deliveryservice_id_seq OWNED BY deliveryservice.id;


--
-- TOC entry 177 (class 1259 OID 27592)
-- Name: deliveryservice_regex; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE deliveryservice_regex (
    deliveryservice integer NOT NULL,
    regex integer NOT NULL,
    set_number integer
);


ALTER TABLE deliveryservice_regex OWNER TO tm_user;

--
-- TOC entry 178 (class 1259 OID 27595)
-- Name: deliveryservice_server; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE deliveryservice_server (
    deliveryservice integer NOT NULL,
    server integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE deliveryservice_server OWNER TO tm_user;

--
-- TOC entry 179 (class 1259 OID 27598)
-- Name: deliveryservice_tmuser; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE deliveryservice_tmuser (
    deliveryservice integer NOT NULL,
    tm_user_id integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE deliveryservice_tmuser OWNER TO tm_user;

--
-- TOC entry 180 (class 1259 OID 27601)
-- Name: division; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE division (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE division OWNER TO tm_user;

--
-- TOC entry 212 (class 1259 OID 27782)
-- Name: division_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE division_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE division_id_seq OWNER TO tm_user;

--
-- TOC entry 2584 (class 0 OID 0)
-- Dependencies: 212
-- Name: division_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE division_id_seq OWNED BY division.id;


--
-- TOC entry 181 (class 1259 OID 27604)
-- Name: federation; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE federation (
    id integer NOT NULL,
    cname character varying(1024) NOT NULL,
    description character varying(1024),
    ttl integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE federation OWNER TO tm_user;

--
-- TOC entry 182 (class 1259 OID 27610)
-- Name: federation_deliveryservice; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE federation_deliveryservice (
    federation integer NOT NULL,
    deliveryservice integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE federation_deliveryservice OWNER TO tm_user;

--
-- TOC entry 183 (class 1259 OID 27613)
-- Name: federation_federation_resolver; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE federation_federation_resolver (
    federation integer NOT NULL,
    federation_resolver integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE federation_federation_resolver OWNER TO tm_user;

--
-- TOC entry 213 (class 1259 OID 27789)
-- Name: federation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE federation_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE federation_id_seq OWNER TO tm_user;

--
-- TOC entry 2585 (class 0 OID 0)
-- Dependencies: 213
-- Name: federation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE federation_id_seq OWNED BY federation.id;


--
-- TOC entry 184 (class 1259 OID 27616)
-- Name: federation_resolver; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE federation_resolver (
    id integer NOT NULL,
    ip_address character varying(50) NOT NULL,
    type integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE federation_resolver OWNER TO tm_user;

--
-- TOC entry 214 (class 1259 OID 27804)
-- Name: federation_resolver_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE federation_resolver_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE federation_resolver_id_seq OWNER TO tm_user;

--
-- TOC entry 2586 (class 0 OID 0)
-- Dependencies: 214
-- Name: federation_resolver_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE federation_resolver_id_seq OWNED BY federation_resolver.id;


--
-- TOC entry 185 (class 1259 OID 27619)
-- Name: federation_tmuser; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE federation_tmuser (
    federation integer NOT NULL,
    tm_user integer NOT NULL,
    role integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE federation_tmuser OWNER TO tm_user;

--
-- TOC entry 186 (class 1259 OID 27622)
-- Name: goose_db_version; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE goose_db_version (
    id numeric NOT NULL,
    version_id bigint NOT NULL,
    is_applied smallint NOT NULL,
    tstamp timestamp without time zone DEFAULT now()
);


ALTER TABLE goose_db_version OWNER TO tm_user;

--
-- TOC entry 215 (class 1259 OID 27818)
-- Name: goose_db_version_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE goose_db_version_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE goose_db_version_id_seq OWNER TO tm_user;

--
-- TOC entry 2587 (class 0 OID 0)
-- Dependencies: 215
-- Name: goose_db_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE goose_db_version_id_seq OWNED BY goose_db_version.id;

-- The Traffic Ops starting point for goose is 20151107000000 - that was the last applied migration in the MySQL DB
-- we migrated from 
INSERT INTO goose_db_version (id, version_id, is_applied) VALUES (0, 0, 1);
INSERT INTO goose_db_version (id, version_id, is_applied) VALUES (1, 20151107000000, 1);

--
-- TOC entry 187 (class 1259 OID 27628)
-- Name: hwinfo; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE hwinfo (
    id integer NOT NULL,
    serverid integer NOT NULL,
    description character varying(256) NOT NULL,
    val character varying(256) NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE hwinfo OWNER TO tm_user;

--
-- TOC entry 216 (class 1259 OID 27826)
-- Name: hwinfo_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE hwinfo_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE hwinfo_id_seq OWNER TO tm_user;

--
-- TOC entry 2588 (class 0 OID 0)
-- Dependencies: 216
-- Name: hwinfo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE hwinfo_id_seq OWNED BY hwinfo.id;


--
-- TOC entry 188 (class 1259 OID 27634)
-- Name: job; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

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


ALTER TABLE job OWNER TO tm_user;

--
-- TOC entry 189 (class 1259 OID 27640)
-- Name: job_agent; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE job_agent (
    id integer NOT NULL,
    name character varying(128),
    description character varying(512),
    active integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE job_agent OWNER TO tm_user;

--
-- TOC entry 218 (class 1259 OID 27844)
-- Name: job_agent_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE job_agent_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE job_agent_id_seq OWNER TO tm_user;

--
-- TOC entry 2589 (class 0 OID 0)
-- Dependencies: 218
-- Name: job_agent_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE job_agent_id_seq OWNED BY job_agent.id;


--
-- TOC entry 217 (class 1259 OID 27834)
-- Name: job_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE job_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE job_id_seq OWNER TO tm_user;

--
-- TOC entry 2590 (class 0 OID 0)
-- Dependencies: 217
-- Name: job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE job_id_seq OWNED BY job.id;


--
-- TOC entry 190 (class 1259 OID 27646)
-- Name: job_result; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE job_result (
    id integer NOT NULL,
    job integer NOT NULL,
    agent integer NOT NULL,
    result character varying(48) NOT NULL,
    description character varying(512),
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE job_result OWNER TO tm_user;

--
-- TOC entry 219 (class 1259 OID 27850)
-- Name: job_result_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE job_result_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE job_result_id_seq OWNER TO tm_user;

--
-- TOC entry 2591 (class 0 OID 0)
-- Dependencies: 219
-- Name: job_result_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE job_result_id_seq OWNED BY job_result.id;


--
-- TOC entry 191 (class 1259 OID 27652)
-- Name: job_status; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE job_status (
    id integer NOT NULL,
    name character varying(48),
    description character varying(256),
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE job_status OWNER TO tm_user;

--
-- TOC entry 220 (class 1259 OID 27858)
-- Name: job_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE job_status_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE job_status_id_seq OWNER TO tm_user;

--
-- TOC entry 2592 (class 0 OID 0)
-- Dependencies: 220
-- Name: job_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE job_status_id_seq OWNED BY job_status.id;


--
-- TOC entry 192 (class 1259 OID 27655)
-- Name: log; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE log (
    id integer NOT NULL,
    level character varying(45),
    message character varying(1024) NOT NULL,
    tm_user integer NOT NULL,
    ticketnum character varying(64),
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE log OWNER TO tm_user;

--
-- TOC entry 221 (class 1259 OID 27865)
-- Name: log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE log_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE log_id_seq OWNER TO tm_user;

--
-- TOC entry 2593 (class 0 OID 0)
-- Dependencies: 221
-- Name: log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE log_id_seq OWNED BY log.id;


--
-- TOC entry 193 (class 1259 OID 27661)
-- Name: parameter; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE parameter (
    id integer NOT NULL,
    name character varying(1024) NOT NULL,
    config_file character varying(45) NOT NULL,
    value character varying(1024),
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE parameter OWNER TO tm_user;

--
-- TOC entry 222 (class 1259 OID 27877)
-- Name: parameter_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE parameter_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE parameter_id_seq OWNER TO tm_user;

--
-- TOC entry 2594 (class 0 OID 0)
-- Dependencies: 222
-- Name: parameter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE parameter_id_seq OWNED BY parameter.id;


--
-- TOC entry 194 (class 1259 OID 27667)
-- Name: phys_location; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

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
    region integer,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE phys_location OWNER TO tm_user;

--
-- TOC entry 223 (class 1259 OID 27884)
-- Name: phys_location_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE phys_location_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE phys_location_id_seq OWNER TO tm_user;

--
-- TOC entry 2595 (class 0 OID 0)
-- Dependencies: 223
-- Name: phys_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE phys_location_id_seq OWNED BY phys_location.id;


--
-- TOC entry 195 (class 1259 OID 27673)
-- Name: profile; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE profile (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(256),
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE profile OWNER TO tm_user;

--
-- TOC entry 224 (class 1259 OID 27893)
-- Name: profile_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE profile_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE profile_id_seq OWNER TO tm_user;

--
-- TOC entry 2596 (class 0 OID 0)
-- Dependencies: 224
-- Name: profile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE profile_id_seq OWNED BY profile.id;


--
-- TOC entry 196 (class 1259 OID 27676)
-- Name: profile_parameter; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE profile_parameter (
    profile integer NOT NULL,
    parameter integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE profile_parameter OWNER TO tm_user;

--
-- TOC entry 197 (class 1259 OID 27679)
-- Name: regex; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE regex (
    id integer NOT NULL,
    pattern character varying(255),
    type integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE regex OWNER TO tm_user;

--
-- TOC entry 225 (class 1259 OID 27905)
-- Name: regex_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE regex_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE regex_id_seq OWNER TO tm_user;

--
-- TOC entry 2597 (class 0 OID 0)
-- Dependencies: 225
-- Name: regex_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE regex_id_seq OWNED BY regex.id;


--
-- TOC entry 198 (class 1259 OID 27682)
-- Name: region; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE region (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    division integer NOT NULL,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE region OWNER TO tm_user;

--
-- TOC entry 226 (class 1259 OID 27913)
-- Name: region_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE region_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE region_id_seq OWNER TO tm_user;

--
-- TOC entry 2598 (class 0 OID 0)
-- Dependencies: 226
-- Name: region_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE region_id_seq OWNED BY region.id;


--
-- TOC entry 199 (class 1259 OID 27685)
-- Name: role; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE role (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(128),
    priv_level integer NOT NULL
);


ALTER TABLE role OWNER TO tm_user;

--
-- TOC entry 227 (class 1259 OID 27920)
-- Name: role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE role_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE role_id_seq OWNER TO tm_user;

--
-- TOC entry 2599 (class 0 OID 0)
-- Dependencies: 227
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE role_id_seq OWNED BY role.id;


--
-- TOC entry 200 (class 1259 OID 27688)
-- Name: server; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

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
    cachegroup integer NOT NULL,
    type integer NOT NULL,
    status integer NOT NULL,
    upd_pending smallint NOT NULL,
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


ALTER TABLE server OWNER TO tm_user;

--
-- TOC entry 228 (class 1259 OID 27927)
-- Name: server_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE server_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE server_id_seq OWNER TO tm_user;

--
-- TOC entry 2600 (class 0 OID 0)
-- Dependencies: 228
-- Name: server_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE server_id_seq OWNED BY server.id;


--
-- TOC entry 201 (class 1259 OID 27694)
-- Name: servercheck; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

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


ALTER TABLE servercheck OWNER TO tm_user;

--
-- TOC entry 229 (class 1259 OID 27943)
-- Name: servercheck_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE servercheck_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE servercheck_id_seq OWNER TO tm_user;

--
-- TOC entry 2601 (class 0 OID 0)
-- Dependencies: 229
-- Name: servercheck_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE servercheck_id_seq OWNED BY servercheck.id;


--
-- TOC entry 202 (class 1259 OID 27697)
-- Name: staticdnsentry; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

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


ALTER TABLE staticdnsentry OWNER TO tm_user;

--
-- TOC entry 230 (class 1259 OID 27953)
-- Name: staticdnsentry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE staticdnsentry_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE staticdnsentry_id_seq OWNER TO tm_user;

--
-- TOC entry 2602 (class 0 OID 0)
-- Dependencies: 230
-- Name: staticdnsentry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE staticdnsentry_id_seq OWNED BY staticdnsentry.id;


--
-- TOC entry 203 (class 1259 OID 27700)
-- Name: stats_summary; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE stats_summary (
    id integer NOT NULL,
    cdn_name character varying(255) DEFAULT 'all'::character varying NOT NULL,
    deliveryservice_name character varying(255) NOT NULL,
    stat_name character varying(255) NOT NULL,
    stat_value real NOT NULL,
    summary_time timestamp without time zone DEFAULT now() NOT NULL,
    stat_date date
);


ALTER TABLE stats_summary OWNER TO tm_user;

--
-- TOC entry 231 (class 1259 OID 27964)
-- Name: stats_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE stats_summary_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE stats_summary_id_seq OWNER TO tm_user;

--
-- TOC entry 2603 (class 0 OID 0)
-- Dependencies: 231
-- Name: stats_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE stats_summary_id_seq OWNED BY stats_summary.id;


--
-- TOC entry 204 (class 1259 OID 27706)
-- Name: status; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE status (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(256),
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE status OWNER TO tm_user;

--
-- TOC entry 232 (class 1259 OID 27970)
-- Name: status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE status_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE status_id_seq OWNER TO tm_user;

--
-- TOC entry 2604 (class 0 OID 0)
-- Dependencies: 232
-- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE status_id_seq OWNED BY status.id;


--
-- TOC entry 205 (class 1259 OID 27709)
-- Name: tm_user; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

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
    local_user smallint NOT NULL,
    token character varying(50),
    registration_sent timestamp without time zone DEFAULT '-infinity'::timestamp without time zone NOT NULL
);


ALTER TABLE tm_user OWNER TO tm_user;

--
-- TOC entry 233 (class 1259 OID 27978)
-- Name: tm_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tm_user_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tm_user_id_seq OWNER TO tm_user;

--
-- TOC entry 2605 (class 0 OID 0)
-- Dependencies: 233
-- Name: tm_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tm_user_id_seq OWNED BY tm_user.id;


--
-- TOC entry 206 (class 1259 OID 27715)
-- Name: to_extension; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE to_extension (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    version character varying(45),
    info_url character varying(45),
    script_file character varying(45),
    isactive smallint,
    additional_config_json character varying(4096),
    description character varying(4096),
    servercheck_short_name character varying(8),
    servercheck_column_name character varying(10),
    type integer,
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE to_extension OWNER TO tm_user;

--
-- TOC entry 234 (class 1259 OID 27986)
-- Name: to_extension_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE to_extension_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE to_extension_id_seq OWNER TO tm_user;

--
-- TOC entry 2606 (class 0 OID 0)
-- Dependencies: 234
-- Name: to_extension_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE to_extension_id_seq OWNED BY to_extension.id;


--
-- TOC entry 207 (class 1259 OID 27721)
-- Name: type; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE type (
    id integer NOT NULL,
    name character varying(45) NOT NULL,
    description character varying(256),
    use_in_table character varying(45),
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE type OWNER TO tm_user;

--
-- TOC entry 235 (class 1259 OID 27994)
-- Name: type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE type_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE type_id_seq OWNER TO tm_user;

--
-- TOC entry 2607 (class 0 OID 0)
-- Dependencies: 235
-- Name: type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE type_id_seq OWNED BY type.id;


--
-- TOC entry 2208 (class 2604 OID 27727)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asn ALTER COLUMN id SET DEFAULT nextval('asn_id_seq'::regclass);


--
-- TOC entry 2210 (class 2604 OID 27737)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cachegroup ALTER COLUMN id SET DEFAULT nextval('cachegroup_id_seq'::regclass);


--
-- TOC entry 2213 (class 2604 OID 27752)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cdn ALTER COLUMN id SET DEFAULT nextval('cdn_id_seq'::regclass);


--
-- TOC entry 2216 (class 2604 OID 27761)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice ALTER COLUMN id SET DEFAULT nextval('deliveryservice_id_seq'::regclass);


--
-- TOC entry 2220 (class 2604 OID 27784)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY division ALTER COLUMN id SET DEFAULT nextval('division_id_seq'::regclass);


--
-- TOC entry 2222 (class 2604 OID 27791)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation ALTER COLUMN id SET DEFAULT nextval('federation_id_seq'::regclass);


--
-- TOC entry 2226 (class 2604 OID 27806)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation_resolver ALTER COLUMN id SET DEFAULT nextval('federation_resolver_id_seq'::regclass);


--
-- TOC entry 2229 (class 2604 OID 27820)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY goose_db_version ALTER COLUMN id SET DEFAULT nextval('goose_db_version_id_seq'::regclass);


--
-- TOC entry 2231 (class 2604 OID 27828)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hwinfo ALTER COLUMN id SET DEFAULT nextval('hwinfo_id_seq'::regclass);


--
-- TOC entry 2233 (class 2604 OID 27836)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job ALTER COLUMN id SET DEFAULT nextval('job_id_seq'::regclass);


--
-- TOC entry 2235 (class 2604 OID 27846)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_agent ALTER COLUMN id SET DEFAULT nextval('job_agent_id_seq'::regclass);


--
-- TOC entry 2237 (class 2604 OID 27852)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_result ALTER COLUMN id SET DEFAULT nextval('job_result_id_seq'::regclass);


--
-- TOC entry 2239 (class 2604 OID 27860)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_status ALTER COLUMN id SET DEFAULT nextval('job_status_id_seq'::regclass);


--
-- TOC entry 2241 (class 2604 OID 27867)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY log ALTER COLUMN id SET DEFAULT nextval('log_id_seq'::regclass);


--
-- TOC entry 2243 (class 2604 OID 27879)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY parameter ALTER COLUMN id SET DEFAULT nextval('parameter_id_seq'::regclass);


--
-- TOC entry 2245 (class 2604 OID 27886)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY phys_location ALTER COLUMN id SET DEFAULT nextval('phys_location_id_seq'::regclass);


--
-- TOC entry 2247 (class 2604 OID 27895)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY profile ALTER COLUMN id SET DEFAULT nextval('profile_id_seq'::regclass);


--
-- TOC entry 2250 (class 2604 OID 27907)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY regex ALTER COLUMN id SET DEFAULT nextval('regex_id_seq'::regclass);


--
-- TOC entry 2252 (class 2604 OID 27915)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY region ALTER COLUMN id SET DEFAULT nextval('region_id_seq'::regclass);


--
-- TOC entry 2253 (class 2604 OID 27922)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY role ALTER COLUMN id SET DEFAULT nextval('role_id_seq'::regclass);


--
-- TOC entry 2256 (class 2604 OID 27929)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY server ALTER COLUMN id SET DEFAULT nextval('server_id_seq'::regclass);


--
-- TOC entry 2258 (class 2604 OID 27945)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY servercheck ALTER COLUMN id SET DEFAULT nextval('servercheck_id_seq'::regclass);


--
-- TOC entry 2261 (class 2604 OID 27955)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY staticdnsentry ALTER COLUMN id SET DEFAULT nextval('staticdnsentry_id_seq'::regclass);


--
-- TOC entry 2264 (class 2604 OID 27966)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stats_summary ALTER COLUMN id SET DEFAULT nextval('stats_summary_id_seq'::regclass);


--
-- TOC entry 2266 (class 2604 OID 27972)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY status ALTER COLUMN id SET DEFAULT nextval('status_id_seq'::regclass);


--
-- TOC entry 2270 (class 2604 OID 27980)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tm_user ALTER COLUMN id SET DEFAULT nextval('tm_user_id_seq'::regclass);


--
-- TOC entry 2272 (class 2604 OID 27988)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY to_extension ALTER COLUMN id SET DEFAULT nextval('to_extension_id_seq'::regclass);


--
-- TOC entry 2274 (class 2604 OID 27996)
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY type ALTER COLUMN id SET DEFAULT nextval('type_id_seq'::regclass);


--
-- TOC entry 2276 (class 2606 OID 27729)
-- Name: asn_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY asn
    ADD CONSTRAINT asn_pkey PRIMARY KEY (id, cachegroup);


--
-- TOC entry 2287 (class 2606 OID 27747)
-- Name: cachegroup_parameter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY cachegroup_parameter
    ADD CONSTRAINT cachegroup_parameter_pkey PRIMARY KEY (cachegroup, parameter);


--
-- TOC entry 2280 (class 2606 OID 27739)
-- Name: cachegroup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT cachegroup_pkey PRIMARY KEY (id, type);


--
-- TOC entry 2290 (class 2606 OID 27754)
-- Name: cdn_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY cdn
    ADD CONSTRAINT cdn_pkey PRIMARY KEY (id);


--
-- TOC entry 2293 (class 2606 OID 27763)
-- Name: deliveryservice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT deliveryservice_pkey PRIMARY KEY (id, type);


--
-- TOC entry 2300 (class 2606 OID 27771)
-- Name: deliveryservice_regex_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY deliveryservice_regex
    ADD CONSTRAINT deliveryservice_regex_pkey PRIMARY KEY (deliveryservice, regex);


--
-- TOC entry 2303 (class 2606 OID 27775)
-- Name: deliveryservice_server_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY deliveryservice_server
    ADD CONSTRAINT deliveryservice_server_pkey PRIMARY KEY (deliveryservice, server);


--
-- TOC entry 2306 (class 2606 OID 27779)
-- Name: deliveryservice_tmuser_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY deliveryservice_tmuser
    ADD CONSTRAINT deliveryservice_tmuser_pkey PRIMARY KEY (deliveryservice, tm_user_id);


--
-- TOC entry 2309 (class 2606 OID 27786)
-- Name: division_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY division
    ADD CONSTRAINT division_pkey PRIMARY KEY (id);


--
-- TOC entry 2314 (class 2606 OID 27796)
-- Name: federation_deliveryservice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY federation_deliveryservice
    ADD CONSTRAINT federation_deliveryservice_pkey PRIMARY KEY (federation, deliveryservice);


--
-- TOC entry 2317 (class 2606 OID 27800)
-- Name: federation_federation_resolver_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY federation_federation_resolver
    ADD CONSTRAINT federation_federation_resolver_pkey PRIMARY KEY (federation, federation_resolver);


--
-- TOC entry 2312 (class 2606 OID 27793)
-- Name: federation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY federation
    ADD CONSTRAINT federation_pkey PRIMARY KEY (id);


--
-- TOC entry 2321 (class 2606 OID 27808)
-- Name: federation_resolver_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY federation_resolver
    ADD CONSTRAINT federation_resolver_pkey PRIMARY KEY (id);


--
-- TOC entry 2325 (class 2606 OID 27813)
-- Name: federation_tmuser_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT federation_tmuser_pkey PRIMARY KEY (federation, tm_user);


--
-- TOC entry 2330 (class 2606 OID 27822)
-- Name: goose_db_version_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY goose_db_version
    ADD CONSTRAINT goose_db_version_pkey PRIMARY KEY (id);


--
-- TOC entry 2333 (class 2606 OID 27830)
-- Name: hwinfo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY hwinfo
    ADD CONSTRAINT hwinfo_pkey PRIMARY KEY (id);


--
-- TOC entry 2343 (class 2606 OID 27848)
-- Name: job_agent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY job_agent
    ADD CONSTRAINT job_agent_pkey PRIMARY KEY (id);


--
-- TOC entry 2337 (class 2606 OID 27838)
-- Name: job_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY job
    ADD CONSTRAINT job_pkey PRIMARY KEY (id);


--
-- TOC entry 2345 (class 2606 OID 27854)
-- Name: job_result_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY job_result
    ADD CONSTRAINT job_result_pkey PRIMARY KEY (id);


--
-- TOC entry 2349 (class 2606 OID 27862)
-- Name: job_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY job_status
    ADD CONSTRAINT job_status_pkey PRIMARY KEY (id);


--
-- TOC entry 2351 (class 2606 OID 27874)
-- Name: log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id, tm_user);


--
-- TOC entry 2354 (class 2606 OID 27881)
-- Name: parameter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY parameter
    ADD CONSTRAINT parameter_pkey PRIMARY KEY (id);


--
-- TOC entry 2357 (class 2606 OID 27888)
-- Name: phys_location_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY phys_location
    ADD CONSTRAINT phys_location_pkey PRIMARY KEY (id);


--
-- TOC entry 2365 (class 2606 OID 27901)
-- Name: profile_parameter_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY profile_parameter
    ADD CONSTRAINT profile_parameter_pkey PRIMARY KEY (profile, parameter);


--
-- TOC entry 2362 (class 2606 OID 27897)
-- Name: profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY profile
    ADD CONSTRAINT profile_pkey PRIMARY KEY (id);


--
-- TOC entry 2371 (class 2606 OID 27909)
-- Name: regex_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY regex
    ADD CONSTRAINT regex_pkey PRIMARY KEY (id, type);


--
-- TOC entry 2375 (class 2606 OID 27917)
-- Name: region_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY region
    ADD CONSTRAINT region_pkey PRIMARY KEY (id);


--
-- TOC entry 2377 (class 2606 OID 27924)
-- Name: role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- TOC entry 2389 (class 2606 OID 27931)
-- Name: server_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY server
    ADD CONSTRAINT server_pkey PRIMARY KEY (id, cachegroup, type, status, profile);


--
-- TOC entry 2394 (class 2606 OID 27947)
-- Name: servercheck_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY servercheck
    ADD CONSTRAINT servercheck_pkey PRIMARY KEY (id, server);


--
-- TOC entry 2400 (class 2606 OID 27957)
-- Name: staticdnsentry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT staticdnsentry_pkey PRIMARY KEY (id);


--
-- TOC entry 2402 (class 2606 OID 27968)
-- Name: stats_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY stats_summary
    ADD CONSTRAINT stats_summary_pkey PRIMARY KEY (id);


--
-- TOC entry 2404 (class 2606 OID 27974)
-- Name: status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY status
    ADD CONSTRAINT status_pkey PRIMARY KEY (id);


--
-- TOC entry 2408 (class 2606 OID 27982)
-- Name: tm_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY tm_user
    ADD CONSTRAINT tm_user_pkey PRIMARY KEY (id);


--
-- TOC entry 2412 (class 2606 OID 27990)
-- Name: to_extension_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY to_extension
    ADD CONSTRAINT to_extension_pkey PRIMARY KEY (id);


--
-- TOC entry 2415 (class 2606 OID 27998)
-- Name: type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY type
    ADD CONSTRAINT type_pkey PRIMARY KEY (id);


--
-- TOC entry 2277 (class 1259 OID 27731)
-- Name: public_asn_cachegroup2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_asn_cachegroup2_idx ON asn USING btree (cachegroup);


--
-- TOC entry 2278 (class 1259 OID 27730)
-- Name: public_asn_id1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_asn_id1_idx ON asn USING btree (id);


--
-- TOC entry 2281 (class 1259 OID 27740)
-- Name: public_cachegroup_id1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_cachegroup_id1_idx ON cachegroup USING btree (id);


--
-- TOC entry 2282 (class 1259 OID 27742)
-- Name: public_cachegroup_name3_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_cachegroup_name3_idx ON cachegroup USING btree (name);


--
-- TOC entry 2288 (class 1259 OID 27748)
-- Name: public_cachegroup_parameter_parameter1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_cachegroup_parameter_parameter1_idx ON cachegroup_parameter USING btree (parameter);


--
-- TOC entry 2283 (class 1259 OID 27743)
-- Name: public_cachegroup_parent_cachegroup_id4_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_cachegroup_parent_cachegroup_id4_idx ON cachegroup USING btree (parent_cachegroup_id);


--
-- TOC entry 2284 (class 1259 OID 27741)
-- Name: public_cachegroup_short_name2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_cachegroup_short_name2_idx ON cachegroup USING btree (short_name);


--
-- TOC entry 2285 (class 1259 OID 27744)
-- Name: public_cachegroup_type5_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_cachegroup_type5_idx ON cachegroup USING btree (type);


--
-- TOC entry 2291 (class 1259 OID 27755)
-- Name: public_cdn_name1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_cdn_name1_idx ON cdn USING btree (name);


--
-- TOC entry 2294 (class 1259 OID 27768)
-- Name: public_deliveryservice_cdn_id5_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_deliveryservice_cdn_id5_idx ON deliveryservice USING btree (cdn_id);


--
-- TOC entry 2295 (class 1259 OID 27765)
-- Name: public_deliveryservice_id2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_deliveryservice_id2_idx ON deliveryservice USING btree (id);


--
-- TOC entry 2296 (class 1259 OID 27767)
-- Name: public_deliveryservice_profile4_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_deliveryservice_profile4_idx ON deliveryservice USING btree (profile);


--
-- TOC entry 2301 (class 1259 OID 27772)
-- Name: public_deliveryservice_regex_regex1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_deliveryservice_regex_regex1_idx ON deliveryservice_regex USING btree (regex);


--
-- TOC entry 2304 (class 1259 OID 27776)
-- Name: public_deliveryservice_server_server1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_deliveryservice_server_server1_idx ON deliveryservice_server USING btree (server);


--
-- TOC entry 2307 (class 1259 OID 27780)
-- Name: public_deliveryservice_tmuser_tm_user_id1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_deliveryservice_tmuser_tm_user_id1_idx ON deliveryservice_tmuser USING btree (tm_user_id);


--
-- TOC entry 2297 (class 1259 OID 27766)
-- Name: public_deliveryservice_type3_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_deliveryservice_type3_idx ON deliveryservice USING btree (type);


--
-- TOC entry 2298 (class 1259 OID 27764)
-- Name: public_deliveryservice_xml_id1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_deliveryservice_xml_id1_idx ON deliveryservice USING btree (xml_id);


--
-- TOC entry 2310 (class 1259 OID 27787)
-- Name: public_division_name1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_division_name1_idx ON division USING btree (name);


--
-- TOC entry 2315 (class 1259 OID 27797)
-- Name: public_federation_deliveryservice_deliveryservice1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_federation_deliveryservice_deliveryservice1_idx ON federation_deliveryservice USING btree (deliveryservice);


--
-- TOC entry 2318 (class 1259 OID 27801)
-- Name: public_federation_federation_resolver_federation1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_federation_federation_resolver_federation1_idx ON federation_federation_resolver USING btree (federation);


--
-- TOC entry 2319 (class 1259 OID 27802)
-- Name: public_federation_federation_resolver_federation_resolver2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_federation_federation_resolver_federation_resolver2_idx ON federation_federation_resolver USING btree (federation_resolver);


--
-- TOC entry 2322 (class 1259 OID 27809)
-- Name: public_federation_resolver_ip_address1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_federation_resolver_ip_address1_idx ON federation_resolver USING btree (ip_address);


--
-- TOC entry 2323 (class 1259 OID 27810)
-- Name: public_federation_resolver_type2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_federation_resolver_type2_idx ON federation_resolver USING btree (type);


--
-- TOC entry 2326 (class 1259 OID 27814)
-- Name: public_federation_tmuser_federation1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_federation_tmuser_federation1_idx ON federation_tmuser USING btree (federation);


--
-- TOC entry 2327 (class 1259 OID 27816)
-- Name: public_federation_tmuser_role3_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_federation_tmuser_role3_idx ON federation_tmuser USING btree (role);


--
-- TOC entry 2328 (class 1259 OID 27815)
-- Name: public_federation_tmuser_tm_user2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_federation_tmuser_tm_user2_idx ON federation_tmuser USING btree (tm_user);


--
-- TOC entry 2331 (class 1259 OID 27823)
-- Name: public_goose_db_version_id1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_goose_db_version_id1_idx ON goose_db_version USING btree (id);


--
-- TOC entry 2334 (class 1259 OID 27831)
-- Name: public_hwinfo_serverid1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_hwinfo_serverid1_idx ON hwinfo USING btree (serverid, description);


--
-- TOC entry 2335 (class 1259 OID 27832)
-- Name: public_hwinfo_serverid2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_hwinfo_serverid2_idx ON hwinfo USING btree (serverid);


--
-- TOC entry 2338 (class 1259 OID 27839)
-- Name: public_job_agent1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_job_agent1_idx ON job USING btree (agent);


--
-- TOC entry 2339 (class 1259 OID 27842)
-- Name: public_job_job_deliveryservice4_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_job_job_deliveryservice4_idx ON job USING btree (job_deliveryservice);


--
-- TOC entry 2340 (class 1259 OID 27841)
-- Name: public_job_job_user3_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_job_job_user3_idx ON job USING btree (job_user);


--
-- TOC entry 2346 (class 1259 OID 27856)
-- Name: public_job_result_agent2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_job_result_agent2_idx ON job_result USING btree (agent);


--
-- TOC entry 2347 (class 1259 OID 27855)
-- Name: public_job_result_job1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_job_result_job1_idx ON job_result USING btree (job);


--
-- TOC entry 2341 (class 1259 OID 27840)
-- Name: public_job_status2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_job_status2_idx ON job USING btree (status);


--
-- TOC entry 2352 (class 1259 OID 27875)
-- Name: public_log_tm_user1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_log_tm_user1_idx ON log USING btree (tm_user);


--
-- TOC entry 2355 (class 1259 OID 27882)
-- Name: public_parameter_name1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_parameter_name1_idx ON parameter USING btree (name, value);


--
-- TOC entry 2358 (class 1259 OID 27889)
-- Name: public_phys_location_name1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_phys_location_name1_idx ON phys_location USING btree (name);


--
-- TOC entry 2359 (class 1259 OID 27891)
-- Name: public_phys_location_region3_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_phys_location_region3_idx ON phys_location USING btree (region);


--
-- TOC entry 2360 (class 1259 OID 27890)
-- Name: public_phys_location_short_name2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_phys_location_short_name2_idx ON phys_location USING btree (short_name);


--
-- TOC entry 2363 (class 1259 OID 27898)
-- Name: public_profile_name1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_profile_name1_idx ON profile USING btree (name);


--
-- TOC entry 2366 (class 1259 OID 27903)
-- Name: public_profile_parameter_parameter2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_profile_parameter_parameter2_idx ON profile_parameter USING btree (parameter);


--
-- TOC entry 2367 (class 1259 OID 27902)
-- Name: public_profile_parameter_profile1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_profile_parameter_profile1_idx ON profile_parameter USING btree (profile);


--
-- TOC entry 2368 (class 1259 OID 27910)
-- Name: public_regex_id1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_regex_id1_idx ON regex USING btree (id);


--
-- TOC entry 2369 (class 1259 OID 27911)
-- Name: public_regex_type2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_regex_type2_idx ON regex USING btree (type);


--
-- TOC entry 2372 (class 1259 OID 27919)
-- Name: public_region_division2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_region_division2_idx ON region USING btree (division);


--
-- TOC entry 2373 (class 1259 OID 27918)
-- Name: public_region_name1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_region_name1_idx ON region USING btree (name);


--
-- TOC entry 2378 (class 1259 OID 27940)
-- Name: public_server_cachegroup9_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_server_cachegroup9_idx ON server USING btree (cachegroup);


--
-- TOC entry 2379 (class 1259 OID 27941)
-- Name: public_server_cdn_id10_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_server_cdn_id10_idx ON server USING btree (cdn_id);


--
-- TOC entry 2380 (class 1259 OID 27934)
-- Name: public_server_host_name3_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_server_host_name3_idx ON server USING btree (host_name);


--
-- TOC entry 2381 (class 1259 OID 27933)
-- Name: public_server_id2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_server_id2_idx ON server USING btree (id);


--
-- TOC entry 2382 (class 1259 OID 27935)
-- Name: public_server_ip6_address4_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_server_ip6_address4_idx ON server USING btree (ip6_address);


--
-- TOC entry 2383 (class 1259 OID 27932)
-- Name: public_server_ip_address1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_server_ip_address1_idx ON server USING btree (ip_address);


--
-- TOC entry 2384 (class 1259 OID 27939)
-- Name: public_server_phys_location8_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_server_phys_location8_idx ON server USING btree (phys_location);


--
-- TOC entry 2385 (class 1259 OID 27938)
-- Name: public_server_profile7_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_server_profile7_idx ON server USING btree (profile);


--
-- TOC entry 2386 (class 1259 OID 27937)
-- Name: public_server_status6_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_server_status6_idx ON server USING btree (status);


--
-- TOC entry 2387 (class 1259 OID 27936)
-- Name: public_server_type5_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_server_type5_idx ON server USING btree (type);


--
-- TOC entry 2390 (class 1259 OID 27949)
-- Name: public_servercheck_id2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_servercheck_id2_idx ON servercheck USING btree (id);


--
-- TOC entry 2391 (class 1259 OID 27948)
-- Name: public_servercheck_server1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_servercheck_server1_idx ON servercheck USING btree (server);


--
-- TOC entry 2392 (class 1259 OID 27950)
-- Name: public_servercheck_server3_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_servercheck_server3_idx ON servercheck USING btree (server);


--
-- TOC entry 2395 (class 1259 OID 27961)
-- Name: public_staticdnsentry_cachegroup4_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_staticdnsentry_cachegroup4_idx ON staticdnsentry USING btree (cachegroup);


--
-- TOC entry 2396 (class 1259 OID 27960)
-- Name: public_staticdnsentry_deliveryservice3_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_staticdnsentry_deliveryservice3_idx ON staticdnsentry USING btree (deliveryservice);


--
-- TOC entry 2397 (class 1259 OID 27958)
-- Name: public_staticdnsentry_host1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_staticdnsentry_host1_idx ON staticdnsentry USING btree (host, address, deliveryservice, cachegroup);


--
-- TOC entry 2398 (class 1259 OID 27959)
-- Name: public_staticdnsentry_type2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_staticdnsentry_type2_idx ON staticdnsentry USING btree (type);


--
-- TOC entry 2405 (class 1259 OID 27984)
-- Name: public_tm_user_role2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_tm_user_role2_idx ON tm_user USING btree (role);


--
-- TOC entry 2406 (class 1259 OID 27983)
-- Name: public_tm_user_username1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_tm_user_username1_idx ON tm_user USING btree (username);


--
-- TOC entry 2409 (class 1259 OID 27991)
-- Name: public_to_extension_id1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_to_extension_id1_idx ON to_extension USING btree (id);


--
-- TOC entry 2410 (class 1259 OID 27992)
-- Name: public_to_extension_type2_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX public_to_extension_type2_idx ON to_extension USING btree (type);


--
-- TOC entry 2413 (class 1259 OID 27999)
-- Name: public_type_name1_idx; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX public_type_name1_idx ON type USING btree (name);


--
-- TOC entry 2416 (class 2606 OID 28000)
-- Name: asn_cachegroup_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY asn
    ADD CONSTRAINT asn_cachegroup_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroup(id);


--
-- TOC entry 2419 (class 2606 OID 28030)
-- Name: cachegroup_parameter_cachegroup_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cachegroup_parameter
    ADD CONSTRAINT cachegroup_parameter_cachegroup_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroup(id) ON DELETE CASCADE;


--
-- TOC entry 2420 (class 2606 OID 28035)
-- Name: cachegroup_parameter_parameter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cachegroup_parameter
    ADD CONSTRAINT cachegroup_parameter_parameter_fkey FOREIGN KEY (parameter) REFERENCES parameter(id) ON DELETE CASCADE;


--
-- TOC entry 2417 (class 2606 OID 28011)
-- Name: cachegroup_parent_cachegroup_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT cachegroup_parent_cachegroup_id_fkey FOREIGN KEY (parent_cachegroup_id) REFERENCES cachegroup(id);


--
-- TOC entry 2418 (class 2606 OID 28016)
-- Name: cachegroup_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cachegroup
    ADD CONSTRAINT cachegroup_type_fkey FOREIGN KEY (type) REFERENCES type(id);


--
-- TOC entry 2421 (class 2606 OID 28050)
-- Name: deliveryservice_cdn_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT deliveryservice_cdn_id_fkey FOREIGN KEY (cdn_id) REFERENCES cdn(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2422 (class 2606 OID 28055)
-- Name: deliveryservice_profile_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT deliveryservice_profile_fkey FOREIGN KEY (profile) REFERENCES profile(id);


--
-- TOC entry 2424 (class 2606 OID 28079)
-- Name: deliveryservice_regex_deliveryservice_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice_regex
    ADD CONSTRAINT deliveryservice_regex_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2425 (class 2606 OID 28084)
-- Name: deliveryservice_regex_regex_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice_regex
    ADD CONSTRAINT deliveryservice_regex_regex_fkey FOREIGN KEY (regex) REFERENCES regex(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2427 (class 2606 OID 28099)
-- Name: deliveryservice_server_deliveryservice_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice_server
    ADD CONSTRAINT deliveryservice_server_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2426 (class 2606 OID 28094)
-- Name: deliveryservice_server_server_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice_server
    ADD CONSTRAINT deliveryservice_server_server_fkey FOREIGN KEY (server) REFERENCES server(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2428 (class 2606 OID 28110)
-- Name: deliveryservice_tmuser_deliveryservice_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice_tmuser
    ADD CONSTRAINT deliveryservice_tmuser_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2429 (class 2606 OID 28115)
-- Name: deliveryservice_tmuser_tm_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice_tmuser
    ADD CONSTRAINT deliveryservice_tmuser_tm_user_id_fkey FOREIGN KEY (tm_user_id) REFERENCES tm_user(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2423 (class 2606 OID 28060)
-- Name: deliveryservice_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY deliveryservice
    ADD CONSTRAINT deliveryservice_type_fkey FOREIGN KEY (type) REFERENCES type(id);


--
-- TOC entry 2430 (class 2606 OID 28137)
-- Name: federation_deliveryservice_deliveryservice_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation_deliveryservice
    ADD CONSTRAINT federation_deliveryservice_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2431 (class 2606 OID 28142)
-- Name: federation_deliveryservice_federation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation_deliveryservice
    ADD CONSTRAINT federation_deliveryservice_federation_fkey FOREIGN KEY (federation) REFERENCES federation(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2432 (class 2606 OID 28152)
-- Name: federation_federation_resolver_federation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation_federation_resolver
    ADD CONSTRAINT federation_federation_resolver_federation_fkey FOREIGN KEY (federation) REFERENCES federation(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2433 (class 2606 OID 28157)
-- Name: federation_federation_resolver_federation_resolver_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation_federation_resolver
    ADD CONSTRAINT federation_federation_resolver_federation_resolver_fkey FOREIGN KEY (federation_resolver) REFERENCES federation_resolver(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2434 (class 2606 OID 28168)
-- Name: federation_resolver_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation_resolver
    ADD CONSTRAINT federation_resolver_type_fkey FOREIGN KEY (type) REFERENCES type(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2435 (class 2606 OID 28179)
-- Name: federation_tmuser_federation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT federation_tmuser_federation_fkey FOREIGN KEY (federation) REFERENCES federation(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2436 (class 2606 OID 28184)
-- Name: federation_tmuser_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT federation_tmuser_role_fkey FOREIGN KEY (role) REFERENCES role(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2437 (class 2606 OID 28189)
-- Name: federation_tmuser_tm_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY federation_tmuser
    ADD CONSTRAINT federation_tmuser_tm_user_fkey FOREIGN KEY (tm_user) REFERENCES tm_user(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2438 (class 2606 OID 28209)
-- Name: hwinfo_serverid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY hwinfo
    ADD CONSTRAINT hwinfo_serverid_fkey FOREIGN KEY (serverid) REFERENCES server(id) ON DELETE CASCADE;


--
-- TOC entry 2439 (class 2606 OID 28224)
-- Name: job_agent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job
    ADD CONSTRAINT job_agent_fkey FOREIGN KEY (agent) REFERENCES job_agent(id) ON DELETE CASCADE;


--
-- TOC entry 2440 (class 2606 OID 28229)
-- Name: job_job_deliveryservice_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job
    ADD CONSTRAINT job_job_deliveryservice_fkey FOREIGN KEY (job_deliveryservice) REFERENCES deliveryservice(id);


--
-- TOC entry 2442 (class 2606 OID 28239)
-- Name: job_job_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job
    ADD CONSTRAINT job_job_user_fkey FOREIGN KEY (job_user) REFERENCES tm_user(id);


--
-- TOC entry 2443 (class 2606 OID 28262)
-- Name: job_result_agent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_result
    ADD CONSTRAINT job_result_agent_fkey FOREIGN KEY (agent) REFERENCES job_agent(id) ON DELETE CASCADE;


--
-- TOC entry 2444 (class 2606 OID 28267)
-- Name: job_result_job_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job_result
    ADD CONSTRAINT job_result_job_fkey FOREIGN KEY (job) REFERENCES job(id) ON DELETE CASCADE;


--
-- TOC entry 2441 (class 2606 OID 28234)
-- Name: job_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY job
    ADD CONSTRAINT job_status_fkey FOREIGN KEY (status) REFERENCES job_status(id);


--
-- TOC entry 2445 (class 2606 OID 28285)
-- Name: log_tm_user_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY log
    ADD CONSTRAINT log_tm_user_fkey FOREIGN KEY (tm_user) REFERENCES tm_user(id);


--
-- TOC entry 2446 (class 2606 OID 28309)
-- Name: phys_location_region_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY phys_location
    ADD CONSTRAINT phys_location_region_fkey FOREIGN KEY (region) REFERENCES region(id);


--
-- TOC entry 2447 (class 2606 OID 28332)
-- Name: profile_parameter_parameter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY profile_parameter
    ADD CONSTRAINT profile_parameter_parameter_fkey FOREIGN KEY (parameter) REFERENCES parameter(id) ON DELETE CASCADE;


--
-- TOC entry 2448 (class 2606 OID 28337)
-- Name: profile_parameter_profile_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY profile_parameter
    ADD CONSTRAINT profile_parameter_profile_fkey FOREIGN KEY (profile) REFERENCES profile(id) ON DELETE CASCADE;


--
-- TOC entry 2449 (class 2606 OID 28348)
-- Name: regex_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY regex
    ADD CONSTRAINT regex_type_fkey FOREIGN KEY (type) REFERENCES type(id);


--
-- TOC entry 2450 (class 2606 OID 28359)
-- Name: region_division_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY region
    ADD CONSTRAINT region_division_fkey FOREIGN KEY (division) REFERENCES division(id);


--
-- TOC entry 2456 (class 2606 OID 28399)
-- Name: server_cachegroup_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY server
    ADD CONSTRAINT server_cachegroup_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroup(id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- TOC entry 2451 (class 2606 OID 28374)
-- Name: server_cdn_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY server
    ADD CONSTRAINT server_cdn_id_fkey FOREIGN KEY (cdn_id) REFERENCES cdn(id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2455 (class 2606 OID 28394)
-- Name: server_phys_location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY server
    ADD CONSTRAINT server_phys_location_fkey FOREIGN KEY (phys_location) REFERENCES phys_location(id);


--
-- TOC entry 2452 (class 2606 OID 28379)
-- Name: server_profile_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY server
    ADD CONSTRAINT server_profile_fkey FOREIGN KEY (profile) REFERENCES profile(id);


--
-- TOC entry 2453 (class 2606 OID 28384)
-- Name: server_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY server
    ADD CONSTRAINT server_status_fkey FOREIGN KEY (status) REFERENCES status(id);


--
-- TOC entry 2454 (class 2606 OID 28389)
-- Name: server_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY server
    ADD CONSTRAINT server_type_fkey FOREIGN KEY (type) REFERENCES type(id);


--
-- TOC entry 2457 (class 2606 OID 28424)
-- Name: servercheck_server_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY servercheck
    ADD CONSTRAINT servercheck_server_fkey FOREIGN KEY (server) REFERENCES server(id) ON DELETE CASCADE;


--
-- TOC entry 2458 (class 2606 OID 28436)
-- Name: staticdnsentry_cachegroup_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT staticdnsentry_cachegroup_fkey FOREIGN KEY (cachegroup) REFERENCES cachegroup(id);


--
-- TOC entry 2459 (class 2606 OID 28441)
-- Name: staticdnsentry_deliveryservice_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT staticdnsentry_deliveryservice_fkey FOREIGN KEY (deliveryservice) REFERENCES deliveryservice(id);


--
-- TOC entry 2460 (class 2606 OID 28446)
-- Name: staticdnsentry_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY staticdnsentry
    ADD CONSTRAINT staticdnsentry_type_fkey FOREIGN KEY (type) REFERENCES type(id);


--
-- TOC entry 2461 (class 2606 OID 28470)
-- Name: tm_user_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tm_user
    ADD CONSTRAINT tm_user_role_fkey FOREIGN KEY (role) REFERENCES role(id) ON DELETE SET NULL;


--
-- TOC entry 2462 (class 2606 OID 28487)
-- Name: to_extension_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY to_extension
    ADD CONSTRAINT to_extension_type_fkey FOREIGN KEY (type) REFERENCES type(id);


--
-- TOC entry 2578 (class 0 OID 0)
-- Dependencies: 5
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2015-12-26 15:32:00 MST

--
-- PostgreSQL database dump complete
--

