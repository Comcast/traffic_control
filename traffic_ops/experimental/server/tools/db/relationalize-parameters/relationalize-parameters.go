package main

import (
	"database/sql"
	"strings"
	"strconv"
	"time"
	_ "github.com/lib/pq"
	"fmt"
	"flag"
	"log"
	"github.com/Comcast/traffic_control/traffic_ops/experimental/server/api"
)

func createConnectionStringPostgres(server, database, user, pass string, port uint) (string, error) {
	connString := fmt.Sprintf("dbname=%s user=%s password=%s sslmode=disable", database, user, pass)
	if server != "" {
		connString += fmt.Sprintf(" host=%s", server)
	}
	if server != "" {
		connString += fmt.Sprintf(" port=%d", port)
	}
	return connString, nil
}

// Args encapsulates the command line arguments
type Args struct {
	Server   string
	Port     uint
	User     string
	Pass     string
	Database string
}

// getFlags parses and returns the command line arguments. The returned error
// will be non-nil if any expected arg is missing.
func getFlags() (Args, error) {
	var args Args
	flag.StringVar(&args.Server, "server", "localhost", "the PostgreSQL server")
	flag.UintVar(&args.Port, "port", 5432, "the PostgreSQL port")
	flag.StringVar(&args.User, "user", "", "the PostgreSQL user")
	flag.StringVar(&args.Pass, "pass", "", "the PostgreSQL password")
	flag.StringVar(&args.Database, "database", "", "the PostgreSQL database")
	flag.Parse()
	return args, nil
}

// getProfileParameters returns a map[parameter_id][profile_id]
func getParameterProfiles(db *sql.DB) (map[int]int, error) {
	rows, err := db.Query("select profile, parameter from profile_parameter;")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	parameterProfiles := make(map[int]int)
	for rows.Next() {
		var profile int
		var parameter int
		rows.Scan(&profile, &parameter)
		parameterProfiles[parameter] = profile
	}
	return parameterProfiles, nil
}

type Profile struct {
	Id int
	Name string
}

// getProfileParameters returns a map[parameter_id][profile_id]
func getProfiles(db *sql.DB) ([]Profile, error) {
	rows, err := db.Query("select id, name from profile;")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var profiles []Profile
	for rows.Next() {
		var id int
		var name string
		rows.Scan(&id, &name)
		profiles = append(profiles, Profile{Id: id, Name: name})
	}
	return profiles, nil
}

type Parameter struct {
	Id int
	Name string
	ConfigFile string
	Value string
}

func getParametersForProfile(db *sql.DB, profileId int) ([]Parameter, error)  {
	rows, err := db.Query("select id, name, config_file, value from parameter where id in (select parameter from profile_parameter where profile = $1);", profileId)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var parameters []Parameter
	for rows.Next() {
		var id int
		var name string
		var configFile string
		var value string
		rows.Scan(&id, &name, &configFile, &value)
		parameters = append(parameters, Parameter{Id: id, Name: name, ConfigFile: configFile, Value: value})
	}
	return parameters, nil
}

func processParameter(db *sql.DB, parameter Parameter, profileId int, record api.CachingProxyRecord) (api.CachingProxyRecord, error) {
	switch parameter.ConfigFile {
	case "records.config":
//		fmt.Printf("%s\n", parameter.Name)
		var err error
		record, err = processParameterRecords(db, parameter, profileId, record)
		if err != nil {
			return record, err
		}
	// 	fmt.Printf("--record--\n")
	// case "astats.config":
	// 	fmt.Printf("##astats##\n")
	// default:
	// 	fmt.Printf("Profile %d - Param %d > %s | %s | %s\n", profileId, parameter.Id, parameter.Name, parameter.ConfigFile, parameter.Value)
	}
	return record, nil
}


// processParameterRecord adds the records.config parameter to the in-progres api.CachingProxyRecord struct.
// `record` could be changed to a pointer, if performance mattered.
func processParameterRecords(db *sql.DB, parameter Parameter, profileId int, r api.CachingProxyRecord) (api.CachingProxyRecord, error) {
	getInt := func() (int, error) {
		prefix := "INT "
		if !strings.HasPrefix(parameter.Value, prefix) {
			return 0, fmt.Errorf("Error parsing int parameter %s, missing prefix 'INT ': %s", parameter.Name, parameter.Value)
		}
		parameter.Value = parameter.Value[len(prefix):]

		v, err := strconv.Atoi(parameter.Value)
		if err != nil {
			return 0, fmt.Errorf("Error parsing int parameter %s: %s", parameter.Name, err)
		}
		return v, nil
	}
	getFloat := func() (float64, error) {
		prefix := "FLOAT "
		if !strings.HasPrefix(parameter.Value, prefix) {
			return 0, fmt.Errorf("Error parsing int parameter %s, missing prefix 'FLOAT ': %s", parameter.Name, parameter.Value)
		}
		parameter.Value = parameter.Value[len(prefix):]

		v, err := strconv.ParseFloat(parameter.Value, 64)
		if err != nil {
			return 0, fmt.Errorf("Error parsing int parameter %s: %s", parameter.Name, err)
		}
		return v, nil
	}
	getBool := func() (bool, error) {
		v, err := getInt()
		if err != nil {
			return false, fmt.Errorf("Error parsing bool parameter %s: %s", parameter.Name, err)
		}
		return v != 0, nil
	}
	getString := func() (string, error) {
		prefix := "STRING "
		if strings.HasPrefix(parameter.Value, prefix) {
			parameter.Value = parameter.Value[len(prefix):]
		}
		return parameter.Value, nil
	}
	getDuration := func(unit time.Duration) (time.Duration, error) {
		intVal, err := getInt()
		if err != nil {
			return time.Nanosecond, err
		}
		return unit * time.Duration(intVal), nil
	}
	getDurationSeconds := func() (time.Duration, error) {
		return getDuration(time.Second)
	}
	getPorts := func() ([]api.CachingProxyRecordPort, error) {
		// example; "STRING 80 80:ipv6 443:ssl 443:ipv6:ssl"
		var ports []api.CachingProxyRecordPort

		prefix := "STRING "
		if len(parameter.Value) < len(prefix) {
				return nil, fmt.Errorf("Error parsing ports %s: %s", parameter.Name, "missing prefix 'STRING '")
		}
		parameter.Value = parameter.Value[len(prefix):]

		portStrs := strings.Split(parameter.Value, " ")
		for _, portFullStr := range portStrs {
			components := strings.Split(portFullStr, ":")
			if len(components) < 1 {
				return nil, fmt.Errorf("Error parsing ports %s: %s", parameter.Name, "no ports")
			}
			portStr := components[0]
			port, err := strconv.Atoi(portStr)
			if err != nil || port < 0 || port > 65535 {
				return nil, fmt.Errorf("Error parsing ports %s: '%s' not a port", parameter.Name, port)
			}
			ipv6 := false
			ssl := false
			for i := 1; i < 3; i++ {
				if len(components) <= i {
					break
				}
				if components[i] == "ssl" {
					ssl = true
				} else if components[i] == "ipv6" {
					ipv6 = true
				} else if components[i] != "ipv4" {
					return nil, fmt.Errorf("Error parsing ports %s: unexpected port string component '%s' (expecting ssl|ipv4|ipv6)", parameter.Name, components[i])
				}
			}

			ports = append(ports, api.CachingProxyRecordPort{Port: uint(port), IPv6: ipv6, SSL: ssl})
		}
		return ports, nil
	}

	getSimplePorts := func() ([]uint, error) {
		// example; "STRING 80 443"
		var ports []uint

		prefix := "STRING "
		if len(parameter.Value) < len(prefix) {
				return nil, fmt.Errorf("Error parsing ports %s: %s", parameter.Name, "missing prefix 'STRING '")
		}
		parameter.Value = parameter.Value[len(prefix):]

		portStrs := strings.Split(parameter.Value, " ")
		for _, portStr := range portStrs {
			port, err := strconv.Atoi(portStr)
			if err != nil {
				return nil, fmt.Errorf("Error parsing ports %s: %s", parameter.Name, parameter.Value)
			}
			ports = append(ports, uint(port))
		}
		return ports, nil
	}

	// getDurationDays := func() (time.Duration, error) {
	// 	return getDuration(time.Hour * 24)
	// }

	// fmt.Printf("Profile %d - Param %d > %s | %s | %s\n", profileId, parameter.Id, parameter.Name, parameter.ConfigFile, parameter.Value)

	// getEnum takes a string 'int' number, e.g. `INT 0`, and returns the entry in enumVals for that index.
	// If the given string doesn't contain an index of enumVals, the string is returned unmodified.
	// This is designed to compose with `getString`, and s and err are returned unmodified if err != nil
	getEnum := func(enumVals []string) (string, error) {
		v, err := getInt()
		if err != nil {
			return strconv.Itoa(v), err
		}
		// this could be made efficient, if necessary
		for i, enumVal := range enumVals {
			if v == i {
				return enumVal, nil
			}
		}
		return strconv.Itoa(v), nil
	}

	var err error
	switch parameter.Name {
	case "location":
		r.Location, err = getString()
	case "CONFIG proxy.config.dns.lookup_timeout":
		r.DnsLookupTimeout, err = getDurationSeconds()
	case "CONFIG proxy.config.cache.ip_allow.filename":
		r.IpAllowFilename, err = getString()
	case "CONFIG proxy.config.accept_threads":
		r.AcceptThreads, err = getInt()
	case "CONFIG proxy.config.admin.admin_user":
		r.AdminUser, err = getString()
	case "CONFIG proxy.config.admin.user_id":
		r.UserId, err = getString()
	case "CONFIG proxy.config.admin.autoconf_port":
		r.AutoconfPort, err = getInt()
	case "CONFIG proxy.config.admin.number_config_bak":
		fallthrough
	case "CONFIG proxy.config.admin.number_config":
		r.NumberConfig, err = getInt()
	case "CONFIG proxy.config.alarm.abs_path":
		r.AlarmAbsPath, err = getString()
	case "CONFIG proxy.config.alarm.bin":
		r.AlarmBin, err = getString()
	case "CONFIG proxy.config.alarm_email":
		r.AlarmEmail, err = getString()
	case "CONFIG proxy.config.allocator.debug_filter":
		r.AllocatorDebugFilter, err = getInt()
	case "CONFIG proxy.config.allocator.enable_reclaim":
		r.AllocatorEnableReclaim, err = getBool()
	case "CONFIG proxy.config.allocator.hugepages":
		r.AllocatorHugePages, err = getBool()
	case "CONFIG proxy.config.allocator.max_overage":
		r.AllocatorMaxOverage, err = getInt()
	case "CONFIG proxy.config.allocator.thread_freelist_size":
		r.AllocatorThreadFreelistSize, err = getInt()
	case "CONFIG proxy.config.body_factory.enable_customizations":
		r.BodyFactoryEnableCustomizations, err = getEnum([]string{"customizable response pages", "language-targetted response pages", "host-targetted response pages"})
	case "CONFIG proxy.config.body_factory.enable_logging":
		r.BodyFactoryEnableLogging, err = getBool()
	case "CONFIG proxy.config.body_factory.response_suppression_mode":
		r.BodyFactoryResponseSuppressionMode, err = getEnum([]string{"never", "always", "only intercepted traffic"})
	case "CONFIG proxy.config.body_factory.template_sets_dir":
		r.BodyFactoryTemplateSetsDir, err = getString()
	case "CONFIG proxy.config.cache.control.filename":
		r.Cache.ControlFilename, err = getString()
	case "CONFIG proxy.config.cache.enable_read_while_writer":
		r.EnableReadWhileWriter, err = getEnum([]string{"never", "always", "always_and_allow_range"})
	case "CONFIG proxy.config.cache.hosting_filename":
		r.Cache.HostingFilename, err = getString()
	case "CONFIG proxy.config.cache.http.compatibility.4-2-0-fixup":
		r.Cache.HttpCompatability420Fixup, err = getInt()
	case "CONFIG proxy.config.cache.limits.http.max_alts":
		r.Cache.LimitsHttpMaxAlts, err = getInt()
	case "CONFIG proxy.config.cache.max_doc_size":
		r.Cache.MaxDocSize, err = getInt()
	case "CONFIG proxy.config.cache.min_average_object_size":
		r.Cache.MinAverageObjectSize, err = getInt()
	case "CONFIG proxy.config.cache.mutex_retry_delay":
		r.Cache.MutexRetryDelay, err = getInt()
	case "CONFIG proxy.config.cache.permit.pinning":
		r.Cache.PermitPinning, err = getInt()
	case "CONFIG proxy.config.cache.ram_cache.algorithm":
		r.Cache.RamCacheAlgorithm, err = getInt()
	case "CONFIG proxy.config.cache.ram_cache.compress":
		r.Cache.RamCacheCompress, err = getInt()
	case "CONFIG proxy.config.cache.ram_cache.size":
		r.Cache.RamCacheSize, err = getInt()
	case "CONFIG proxy.config.cache.ram_cache.use_seen_filter":
		r.Cache.RamCacheUseSeenFilter, err = getBool()
	case "CONFIG proxy.config.cache.ram_cache_cutoff":
		r.Cache.RamCacheCutoff, err = getInt()
	case "CONFIG proxy.config.cache.target_fragment_size":
		r.Cache.TargetFragmentSize, err = getInt()
	case "CONFIG proxy.config.cache.threads_per_disk":
		r.Cache.ThreadsPerDisk, err = getInt()
	case "CONFIG proxy.config.cluster.cluster_configuration ": // yes, the postfix space is intentional
		fallthrough
	case "CONFIG proxy.config.cluster.cluster_configuration":
		r.ClusterConfiguration, err = getString()
	case "CONFIG proxy.config.cluster.cluster_port":
		r.ClusterClusterPort, err = getInt()
	case "CONFIG proxy.config.cluster.ethernet_interface":
		r.ClusterEthernetInterface, err = getString()
	case "CONFIG proxy.config.cluster.log_bogus_mc_msgs":
		r.ClusterLogBogusMcMsgs, err = getInt()
	case "CONFIG proxy.config.cluster.mc_group_addr":
		r.ClusterMcGroupAddr, err = getString()
	case "CONFIG proxy.config.cluster.mc_ttl":
		r.ClusterMcTtl, err = getInt()
	case "CONFIG proxy.config.cluster.mcport":
		r.ClusterMcport, err = getInt()
	case "CONFIG proxy.config.cluster.rsport":
		r.ClusterRsport, err = getInt()
	case "CONFIG proxy.config.config_dir":
		r.ConfigDir, err = getString()
	case "CONFIG proxy.config.core_limit":
		r.CoreLimit, err = getInt()
	case "CONFIG proxy.config.diags.debug.enabled":
		r.DiagsDebugEnabled, err = getBool()
	case "CONFIG proxy.config.diags.debug.tags":
		r.DiagsDebugTags, err = getString()
	case "CONFIG proxy.config.diags.show_location":
		r.DiagsShowLocation, err = getBool()
	case "CONFIG proxy.config.dns.max_dns_in_flight":
		r.DnsMaxDnsInFlight, err = getInt()
	case "CONFIG proxy.config.dns.nameservers":
		r.DnsNameservers, err = getString()
	case "CONFIG proxy.config.dns.resolv_conf":
		r.DnsResolvConf, err = getString()
	case "CONFIG proxy.config.dns.round_robin_nameservers":
		r.DnsRoundRobinNameservers, err = getBool()
	case "CONFIG proxy.config.dns.search_default_domains":
		r.DnsSearchDefaultDomains, err = getEnum([]string{"disable", "enable", "enable_restrain_splitting"})
	case "CONFIG proxy.config.dns.splitDNS.enabled":
		r.DnsSplitDnsEnabled, err = getBool()
	case "CONFIG proxy.config.dns.url_expansions":
		r.DnsUrlExpansions, err = getString()
	case "CONFIG proxy.config.dns.validate_query_name":
		r.DnsValidateQueryName, err = getBool()
	case "CONFIG proxy.config.dump_mem_info_frequency":
		r.DumpMemInfoFrequency, err = getInt()
	case "CONFIG proxy.config.env_prep":
		r.EnvPrep, err = getString()
	case "CONFIG proxy.config.exec_thread.affinity":
		r.ExecThreadAffinity, err = getEnum([]string{"machine", "numa", "sockets", "cores", "processing units"})
	case "CONFIG proxy.config.exec_thread.autoconfig":
		r.ExecThreadAutoconfig, err = getBool()
	case "CONFIG proxy.config.exec_thread.autoconfig.scale":
		r.ExecThreadAutoconfigScale, err = getFloat()
	case "CONFIG proxy.config.exec_thread.limit":
		r.ExecThreadLimit, err = getInt()
	case "CONFIG proxy.config.header.parse.no_host_url_redirect":
		r.ParseNoHostUrlRedirect, err = getString()
	case "CONFIG proxy.config.hostdb.serve_stale_for":
		r.HostDb.ServerStaleFor, err = getDurationSeconds()
	case "CONFIG proxy.config.hostdb.size":
		r.HostDb.Size, err = getInt()
	case "CONFIG proxy.config.hostdb.storage_size":
		r.HostDb.StorageSize, err = getInt()
	case "CONFIG proxy.config.hostdb.strict_round_robin":
		r.HostDb.StrictRoundRobin, err = getBool()
	case "CONFIG proxy.config.hostdb.timeout":
		r.HostDb.Timeout, err = getInt()
	case "CONFIG proxy.config.hostdb.ttl_mode":
		r.HostDb.TtlMode, err = getEnum([]string{"dns", "internal", "smaller", "larger"})
	case "CONFIG proxy.config.http.accept_no_activity_timeout":
		r.Http.AcceptNoActivityTimeout, err = getInt()
	case "CONFIG proxy.config.http.anonymize_insert_client_ip":
		r.Http.AnonymizeInsertClientIp, err = getInt()
	case "CONFIG proxy.config.http.anonymize_other_header_list":
		r.Http.AnonymizeOtherHeaderList, err = getString()
	case "CONFIG proxy.config.http.anonymize_remove_client_ip":
		r.Http.AnonymizeRemoveClientIp, err = getBool()
	case "CONFIG proxy.config.http.anonymize_remove_cookie":
		r.Http.AnonymizeRemoveCookie, err = getBool()
	case "CONFIG proxy.config.http.anonymize_remove_from":
		r.Http.AnonymizeRemoveFrom, err = getBool()
	case "CONFIG proxy.config.http.anonymize_remove_referer":
		r.Http.AnonymizeRemoveReferer, err = getBool()
	case "CONFIG proxy.config.http.anonymize_remove_user_agent":
		r.Http.AnonymizeRemoveUserAgent, err = getBool()
	case "CONFIG proxy.config.http.background_fill_active_timeout":
		r.Http.BackgroundFillActiveTimeout, err = getInt()
	case "CONFIG proxy.config.http.background_fill_completed_threshold":
		r.Http.BackgroundFillCompletedThreshold, err = getFloat()
	case "CONFIG proxy.config.http.cache.allow_empty_doc":
		r.Http.Cache.AllowEmptyDoc, err = getBool()
	case "CONFIG proxy.config.http.cache.cache_responses_to_cookies":
		r.Http.Cache.CacheResponsesToCookies, err = getEnum([]string{"no", "any", "only images", "except text"})
	case "CONFIG proxy.config.http.cache.cache_urls_that_look_dynamic":
		r.Http.Cache.CacheUrlsThatLookDynamic, err = getBool()
	case "CONFIG proxy.config.http.cache.enable_default_vary_headers":
		r.Http.Cache.EnableDefaultVaryHeaders, err = getBool()
	case "CONFIG proxy.config.http.cache.fuzz.probability":
		r.Http.Cache.FuzzProbability, err = getFloat()
	case "CONFIG proxy.config.http.cache.fuzz.time":
		r.Http.Cache.FuzzTime, err =  getDurationSeconds()
	case "CONFIG proxy.config.http.cache.heuristic_lm_factor":
		r.Http.Cache.HeuristicLmFactor, err = getFloat()
	case "CONFIG proxy.config.http.cache.heuristic_max_lifetime":
		r.Http.Cache.HeuristicMaxLifetime, err = getInt()
	case "CONFIG proxy.config.http.cache.heuristic_min_lifetime":
		r.Http.Cache.HeuristicMinLifetime, err = getInt()
	case "CONFIG proxy.config.http.cache.http":
		r.Http.Cache.Http, err = getBool()
	case "CONFIG proxy.config.http.cache.ignore_accept_encoding_mismatch":
		r.Http.Cache.IgnoreAcceptEncodingMismatch, err = getBool()
	case "CONFIG proxy.config.http.cache.ignore_authentication":
		r.Http.Cache.IgnoreAuthentication, err = getBool()
	case "CONFIG proxy.config.http.cache.ignore_client_cc_max_age":
		r.Http.Cache.IgnoreClientCcMaxAge, err = getInt()
	case "CONFIG proxy.config.http.cache.ignore_client_no_cache":
		r.Http.Cache.IgnoreClientNoCache, err = getBool()
	case "CONFIG proxy.config.http.cache.ignore_server_no_cache":
		r.Http.Cache.IgnoreServerNoCache, err = getBool()
	case "CONFIG proxy.config.http.cache.ims_on_client_no_cache":
		r.Http.Cache.ImsOnClientNoCache, err = getBool()
	case "CONFIG proxy.config.http.cache.max_stale_age":
		r.Http.Cache.MaxStaleAge, err = getInt()
	case "CONFIG proxy.config.http.cache.range.lookup":
		r.Http.Cache.RangeLookup, err = getBool()
	case "CONFIG proxy.config.http.cache.required_headers":
		r.Http.Cache.RequiredHeaders, err = getEnum([]string{"no", "implicit", "explicit"})
	case "CONFIG proxy.config.http.cache.vary_default_images":
		r.Http.Cache.VaryDefaultImages, err = getString()
	case "CONFIG proxy.config.http.cache.vary_default_other":
		r.Http.Cache.VaryDefaultOther, err = getString()
	case "CONFIG proxy.config.http.cache.vary_default_text":
		r.Http.Cache.VaryDefaultText, err = getString()
	case "CONFIG proxy.config.http.cache.when_to_add_no_cache_to_msie_requests":
		r.Http.Cache.WhenToAddNoCacheToMsieRequests, err = getInt()
	case "CONFIG proxy.config.http.cache.when_to_revalidate":
		r.Http.Cache.WhenToRevalidate, err = getEnum([]string{"directive or heuristic", "stale if heuristic", "always stale", "never stale", "directive or heuristic unless if-modified-since"})
	case "CONFIG proxy.config.http.chunking_enabled":
		r.Http.ChunkingEnabled, err = getEnum([]string{"never", "always", "if prior response HTTP/1.1", "if request and prior response HTTP/1.1"})
	case "CONFIG proxy.config.http.congestion_control.enabled":
		r.Http.CongestionControlEnabled, err = getBool()
	case "CONFIG proxy.config.http.connect_attempts_max_retries":
		r.Http.ConnectAttemptsMaxRetries, err = getInt()
	case "CONFIG proxy.config.http.connect_attempts_max_retries_dead_server":
		r.Http.ConnectAttemptsMaxRetriesDeadServer, err = getInt()
	case "CONFIG proxy.config.http.connect_attempts_rr_retries":
		r.Http.ConnectAttemptsRrRetries, err = getInt()
	case "CONFIG proxy.config.http.connect_attempts_timeout":
		r.Http.ConnectAttemptsTimeout, err = getInt()
	case "CONFIG proxy.config.http.down_server.abort_threshold":
		r.Http.DownServerAbortThreshold, err = getInt()
	case "CONFIG proxy.config.http.down_server.cache_time":
		r.Http.DownServerCacheTime, err = getInt()
	case "CONFIG proxy.config.http.enable_http_stats":
		r.Http.EnableHttpStats, err = getBool()
	case "CONFIG proxy.config.http.enable_url_expandomatic":
		r.Http.EnableUrlExpandomatic, err = getBool()
	case "CONFIG proxy.config.http.forward.proxy_auth_to_parent":
		r.Http.ForwardProxyAuthToParent, err = getBool()
	case "CONFIG proxy.config.http.insert_age_in_response":
		r.Http.InsertAgeInResponse, err = getBool()
	case "CONFIG proxy.config.http.insert_request_via_str":
		r.Http.InsertRequestViaStr, err = getEnum([]string{"no", "normal", "higher", "highest"})
	case "CONFIG proxy.config.http.insert_response_via_str":
		r.Http.InsertResponseViaStr, err = getEnum([]string{"no", "normal", "higher", "highest"})
	case "CONFIG proxy.config.http.insert_squid_x_forwarded_for":
		r.Http.InsertSquidXForwardedFor, err = getBool()
	case "CONFIG proxy.config.http.keep_alive_enabled_in":
		r.Http.KeepAliveEnabledIn, err = getBool()
	case "CONFIG proxy.config.http.keep_alive_enabled_out":
		r.Http.KeepAliveEnabledOut, err = getBool()
	case "CONFIG proxy.config.http.keep_alive_no_activity_timeout_in":
		r.Http.KeepAliveEnabledNoActivityTimeoutIn, err = getInt()
	case "CONFIG proxy.config.http.keep_alive_no_activity_timeout_out":
		r.Http.KeepAliveEnabledNoActivityTimeoutOut, err = getInt()
	case "CONFIG proxy.config.http.negative_caching_enabled":
		r.Http.NegativeCachingEnabled, err = getBool()
	case "CONFIG proxy.config.http.negative_caching_lifetime":
		r.Http.NegativeCachingLifetime, err = getInt()
	case "CONFIG proxy.config.http.no_dns_just_forward_to_parent":
		r.Http.NoDnsJustForwardToParent, err = getBool()
	case "CONFIG proxy.config.http.normalize_ae_gzip":
		r.Http.NormalizeAeGzip, err = getBool()
	case "CONFIG proxy.config.http.origin_server_pipeline":
		r.Http.OriginServerPipeline, err = getInt()
	case "CONFIG proxy.config.http.parent_proxy.connect_attempts_timeout":
		r.Http.ParentProxyConnectAttemptsTimeout, err = getInt()
	case "CONFIG proxy.config.http.parent_proxy.fail_threshold":
		r.Http.ParentProxyFailThreshold, err = getInt()
	case "CONFIG proxy.config.http.parent_proxy.file":
		r.Http.ParentProxyFile, err = getString()
	case "CONFIG proxy.config.http.parent_proxy.per_parent_connect_attempts":
		r.Http.ParentProxyPerParentConnectionAttempts, err = getInt()
	case "CONFIG proxy.config.http.parent_proxy.retry_time":
		r.Http.ParentProxyParentProxyRetryTime, err = getInt()
	case "CONFIG proxy.config.http.parent_proxy.total_connect_attempts":
		r.Http.ParentProxyParentProxyTotalConnectionAttempts, err = getInt()
	case "CONFIG proxy.config.http.parent_proxy_routing_enable":
		r.Http.ParentProxyParentProxyRoutingEnable, err = getBool()
	case "CONFIG proxy.config.http.post_connect_attempts_timeout":
		r.Http.PostConnectAttemptsTimeout, err = getInt()
	case "CONFIG proxy.config.http.push_method_enabled":
		r.Http.ParentPushMethodEnabled, err = getBool()
	case "CONFIG proxy.config.http.referer_default_redirect":
		r.Http.RefererDefaultRedirect, err = getString()
	case "CONFIG proxy.config.http.referer_filter":
		r.Http.RefererFilter, err = getInt()
	case "CONFIG proxy.config.http.referer_format_redirect":
		r.Http.RefererFormatRedirect, err = getInt()
	case "CONFIG proxy.config.http.response_server_enabled":
		r.Http.ResponseServerEnabled, err = getEnum([]string{"no", "add header", "add header if nonexistent"})
	case "CONFIG proxy.config.http.send_http11_requests":
		r.Http.SendHttp11Requests, err = getEnum([]string{"never", "always", "if prior response HTTP/1.1", "if request and prior response HTTP/1.1"})
	case "CONFIG proxy.config.http.share_server_sessions":
		r.Http.ShareServerSessions, err = getInt()
	case "CONFIG proxy.config.http.slow.log.threshold":
		r.Http.SlowLogThreshold, err = getInt()
	case "CONFIG proxy.config.http.transaction_active_timeout_in":
		r.Http.TransactionActiveTimeoutIn, err = getDurationSeconds()
	case "CONFIG proxy.config.http.transaction_active_timeout_out":
		r.Http.TransactionActiveTimeoutOut, err = getDurationSeconds()
	case "CONFIG proxy.config.http.transaction_no_activity_timeout_in":
		r.Http.TransactionNoActivityTimeoutIn, err = getDurationSeconds()
	case "CONFIG proxy.config.http.transaction_no_activity_timeout_out":
		r.Http.TransactionNoActivityTimeoutOut, err = getDurationSeconds()
	case "CONFIG proxy.config.http.uncacheable_requests_bypass_parent":
		r.Http.UncacheableRequestsBypassParent, err = getBool()
	case "CONFIG proxy.config.http.user_agent_pipeline":
		r.Http.UserAgentPipeline, err = getInt()
	case "CONFIG proxy.config.icp.enabled":
		r.IcpEnabled, err = getEnum([]string{"disabled", "receive", "send and receive"})
	case "CONFIG proxy.config.icp.icp_interface":
		r.IcpInterface, err = getString()
	case "CONFIG proxy.config.icp.icp_port":
		r.IcpPort, err = getInt()
	case "CONFIG proxy.config.icp.multicast_enabled":
		r.IcpMulticastEnabled, err = getInt()
	case "CONFIG proxy.config.icp.query_timeout":
		r.IcpQueryTimeout, err = getInt()
	case "CONFIG proxy.config.log.auto_delete_rolled_files":
		r.Log.AutoDeleteRolledFiles, err = getBool()
	case "CONFIG proxy.config.log.collation_host":
		r.Log.CollationHost, err = getString()
	case "CONFIG proxy.config.log.collation_host_tagged":
		r.Log.CollationHostTagged, err = getBool()
	case "CONFIG proxy.config.log.collation_port":
		r.Log.CollationPort, err = getInt()
	case "CONFIG proxy.config.log.collation_retry_sec":
		r.Log.CollationRetry, err = getDurationSeconds()
	case "CONFIG proxy.config.log.collation_secret":
		r.Log.CollationSecret, err = getString()
	case "CONFIG proxy.config.log.common_log_enabled":
		r.Log.Common.Enabled, err = getBool()
	case "CONFIG proxy.config.log.common_log_header":
		r.Log.Common.Header, err = getString()
	case "CONFIG proxy.config.log.common_log_is_ascii":
		r.Log.Common.IsAscii, err = getBool()
	case "CONFIG proxy.config.log.common_log_name":
		r.Log.Common.Name, err = getString()
	case "CONFIG proxy.config.log.custom_logs_enabled":
		r.Log.CustomLogsEnabled, err = getInt()
	case "CONFIG proxy.config.log.extended2_log_enabled":
		r.Log.Extended2.Enabled, err = getBool()
	case "CONFIG proxy.config.log.extended2_log_header":
		r.Log.Extended2.Header, err = getString()
	case "CONFIG proxy.config.log.extended2_log_is_ascii":
		r.Log.Extended2.IsAscii, err = getBool()
	case "CONFIG proxy.config.log.extended2_log_name":
		r.Log.Extended2.Name, err = getString()
	case "CONFIG proxy.config.log.extended_log_enabled":
		r.Log.Extended.Enabled, err = getBool()
	case "CONFIG proxy.config.log.extended_log_header":
		r.Log.Extended.Header, err = getString()
	case "CONFIG proxy.config.log.extended_log_is_ascii":
		r.Log.Extended.IsAscii, err = getBool()
	case "CONFIG proxy.config.log.extended_log_name":
		r.Log.Extended.Name, err = getString()
	case "CONFIG proxy.config.log.hostname":
		r.Log.Hostname, err = getString()
	case "CONFIG proxy.config.log.logfile_dir":
		r.Log.LogfileDir, err = getString()
	case "CONFIG proxy.config.log.logfile_perm":
		r.Log.LogfilePerm, err = getString()
	case "CONFIG proxy.config.log.logging_enabled":
		r.Log.LoggingEnabled, err = getEnum([]string{"disabled", "errors", "transactions", "all"})
	case "CONFIG proxy.config.log.max_secs_per_buffer":
		r.Log.MaxSecsPerBuffer, err = getInt()
	case "CONFIG proxy.config.log.max_space_mb_for_logs":
		r.Log.MaxSpaceMbForLogs, err = getInt()
	case "CONFIG proxy.config.log.max_space_mb_for_orphan_logs":
		r.Log.MaxSpaceMbForOrphanLogs, err = getInt()
	case "CONFIG proxy.config.log.max_space_mb_headroom":
		r.Log.MaxSpaceMbHeadroom, err = getInt()
	case "CONFIG proxy.config.log.rolling_enabled":
		r.Log.RollingEnabled, err = getEnum([]string{"disabled", "interval", "size", "either", "both"})
	case "CONFIG proxy.config.log.rolling_interval_sec":
		r.Log.RollingInterval, err = getDurationSeconds()
	case "CONFIG proxy.config.log.rolling_offset_hr":
		r.Log.RollingOffset, err = getDurationSeconds()
	case "CONFIG proxy.config.log.rolling_size_mb":
		r.Log.RollingSizeMb, err = getInt()
	case "CONFIG proxy.config.log.sampling_frequency":
		r.Log.SamplingFrequency, err = getInt()
	case "CONFIG proxy.config.log.separate_host_logs":
		r.Log.SeparateHostLogs, err = getInt()
	case "CONFIG proxy.config.log.separate_icp_logs":
		r.Log.SeparateIcpLogs, err = getInt()
	case "CONFIG proxy.config.log.squid_log_enabled":
		r.Log.Squid.Enabled, err = getBool()
	case "CONFIG proxy.config.log.squid_log_header":
		r.Log.Squid.Header, err = getString()
	case "CONFIG proxy.config.log.squid_log_is_ascii":
		r.Log.Squid.IsAscii, err = getBool()
	case "CONFIG proxy.config.log.squid_log_name":
		r.Log.Squid.Name, err = getString()
	case "CONFIG proxy.config.log.xml_config_file":
		r.Log.XmlConfigFile, err = getString()
	case "CONFIG proxy.config.mlock_enabled":
		r.MlocEnabled, err = getInt()
	case "CONFIG proxy.config.net.connections_throttle":
		r.NetConnectionsThrottle, err = getInt()
	case "CONFIG proxy.config.net.defer_accept":
		r.NetDeferAccept, err = getBool()
	case "CONFIG proxy.config.net.sock_recv_buffer_size_in":
		r.NetSockRecvBufferSizeIn, err = getInt()
	case "CONFIG proxy.config.net.sock_recv_buffer_size_out":
		r.NetSockRecvBufferSizeOut, err = getInt()
	case "CONFIG proxy.config.net.sock_send_buffer_size_in":
		r.NetSockSendBufferSizeIn, err = getInt()
	case "CONFIG proxy.config.net.sock_send_buffer_size_out":
		r.NetSockSendBufferSizeOut, err = getInt()
	case "CONFIG proxy.config.output.logfile":
		r.OutputLogfile, err = getString()
	case "CONFIG proxy.config.process_manager.mgmt_port":
		r.ProcessManagerManagementPort, err = getInt()
	case "CONFIG proxy.config.proxy_binary_opts":
		r.ProxyBinaryOpts, err = getString()
	case "CONFIG proxy.config.proxy_name":
		r.ProxyName, err = getString()
	case "CONFIG proxy.config.reverse_proxy.enabled":
		r.ReverseProxyEnabled, err = getBool()
	case "CONFIG proxy.config.snapshot_dir":
		r.SnapshotDir, err = getString()
	case "CONFIG proxy.config.ssl.client.CA.cert.filename":
		r.Ssl.ClientCaCertFilename, err = getString()
	case "CONFIG proxy.config.ssl.CA.cert.filename":
		r.Ssl.CaCertFilename, err = getString()
	case "CONFIG proxy.config.ssl.CA.cert.path":
		r.Ssl.CaCertPath, err = getString()
	case "CONFIG proxy.config.ssl.client.CA.cert.path":
		r.Ssl.ClientCaCertPath, err = getString()
	case "CONFIG proxy.config.ssl.client.cert.filename":
		r.Ssl.ClientCertFilename, err = getString()
	case "CONFIG proxy.config.ssl.client.cert.path":
		r.Ssl.ClientCertPath, err = getString()
	case "CONFIG proxy.config.ssl.client.certification_level":
		r.Ssl.ClientCertificationLevel, err = getInt()
	case "CONFIG proxy.config.ssl.client.private_key.filename":
		r.Ssl.ClientPrivateKeyFilename, err = getString()
	case "CONFIG proxy.config.ssl.client.private_key.path":
		r.Ssl.ClientPrivateKeyPath, err = getString()
	case "CONFIG proxy.config.ssl.client.verify.server":
		r.Ssl.ClientVerifyServer, err = getInt()
	case "CONFIG proxy.config.ssl.compression":
		r.Ssl.Compression, err = getInt()
	case "CONFIG proxy.config.ssl.number.threads":
		r.Ssl.NumberThreads, err = getInt()
	case "CONFIG proxy.config.ssl.server.cert.path":
		r.Ssl.ServerCertPath, err = getString()
	case "CONFIG proxy.config.ssl.server.cert_chain.filename":
		r.Ssl.ServerCertChainFilename, err = getString()
	case "CONFIG proxy.config.ssl.server.cipher_suite":
		r.Ssl.ServerCipherSuite, err = getString()
	case "CONFIG proxy.config.ssl.server.honor_cipher_order":
		r.Ssl.ServerHonorCipherOrder, err = getInt()
	case "CONFIG proxy.config.ssl.server.multicert.filename":
		r.Ssl.ServerMulticertFilename, err = getString()
	case "CONFIG proxy.config.ssl.server.private_key.path":
		r.Ssl.ServerPrivateKeyPath, err = getString()
	case "CONFIG proxy.config.ssl.SSLv2":
		r.Ssl.Sslv2, err = getBool()
	case "CONFIG proxy.config.ssl.SSLv3":
		r.Ssl.Sslv3, err = getBool()
	case "CONFIG proxy.config.ssl.TLSv1":
		r.Ssl.Tlsv1, err = getBool()
	case "CONFIG proxy.config.stack_dump_enabled":
		r.StackDumpEnabled, err = getInt()
	case "CONFIG proxy.config.syslog_facility":
		r.SyslogFacility, err = getString()
	case "CONFIG proxy.config.system.mmap_max":
		r.SystemMmapMax, err = getInt()
	case "CONFIG proxy.config.task_threads":
		r.TaskThreads, err = getInt()
	case "CONFIG proxy.config.temp_dir":
		r.TempDir, err = getString()
	case "CONFIG proxy.config.update.concurrent_updates":
		r.UpdateConcurrentUpdates, err = getInt()
	case "CONFIG proxy.config.update.enabled":
		r.UpdateEnabled, err = getInt()
	case "CONFIG proxy.config.update.force":
		r.UpdateForce, err = getInt()
	case "CONFIG proxy.config.update.retry_count":
		r.UpdateRetryCount, err = getInt()
	case "CONFIG proxy.config.update.retry_interval":
		r.UpdateRetryInterval, err = getDurationSeconds()
	case "CONFIG proxy.config.url_remap.default_to_server_pac":
		r.UrlRemapDefaultToServerPac, err = getInt()
	case "CONFIG proxy.config.url_remap.default_to_server_pac_port":
		var v int
		v, err = getInt()
		r.UrlRemapDefaultToServerPacPort = &v
		if *r.UrlRemapDefaultToServerPacPort < 0 || *r.UrlRemapDefaultToServerPacPort > 65535 {
			r.UrlRemapDefaultToServerPacPort = nil
		}
	case "CONFIG proxy.config.url_remap.filename":
		r.UrlRemapFilename, err = getString()
	case "CONFIG proxy.config.url_remap.pristine_host_hdr":
		r.UrlRemapPristineHostHdr, err = getInt()
	case "CONFIG proxy.config.url_remap.remap_required":
		r.UrlRemapRemapRequired, err = getInt()
	// \todo handle params not in records.config
	// case "FOO":
	// 	r.CronOrtSyncdsCdn, err = getString()
	// case "FOO":
	// 	r.DomainName, err = getString()
	// case "BAR":
	// 	r.HealthConnectionTimeout, err = getInt()
	// case "FOO":
	// 	r.HealthPollingUrl, err = getString()
	// case "BAR":
	// 	r.HealthThresholdAvailableBandwidthKbps, err = getInt()
	// case "BAR":
	// 	r.HealthThresholdLoadAverage, err = getInt()
	// case "BAR":
	// 	r.HealthThresholdQueryTime, err = getInt()
	// case "BAR":
	// 	r.HistoryCount, err = getInt()
	case "LOCAL proxy.config.cache.interim.storage":
		r.CacheInterimStorage, err = getString()
	case "LOCAL proxy.local.cluster.type":
		r.LocalClusterType, err = getInt()
	case "LOCAL proxy.local.log.collation_mode":
		r.LocalLogCollationMode, err = getInt()
	// case "FOO":
	// 	r.Log.FormatFormat, err = getString()
	// case "FOO":
	// 	r.Log.FormatName, err = getString()
	// case "FOOTHREE":
	// 	r.MaxRevalDuration, err = getDurationDays()
	// case "FOO":
	// 	r.AstatsPath, err = getString()
	// case "FOO":
	// 	r.Qstring, err = getString()
	// case "BAR":
	// 	r.Astatsapi.CachingProxyRecordTypes, err = getInt()
	// case "FOO":
	// 	r.RegexRevalidate, err = getString()
	// case "FOO":
	// 	r.AstatsLibrary, err = getString()
	// case "FOO":
	// 	r.TrafficServerChkconfig, err = getString()
	// case "FOOTWO":
	// 	r.CrconfigWeight, err = getFloat()
	// case "FOOTWO":
		// 	r.ParentConfigWeight, err = getFloat()
	case "CONFIG proxy.config.http.server_ports":
		r.ServerPorts, err = getPorts()
	case "CONFIG proxy.config.http.connect_ports":
		r.ConnectPorts, err = getSimplePorts()
	default:
		err = fmt.Errorf("Unmatched Parameter: Profile %d - Param %d > %s | %s | %s\n", profileId, parameter.Id, parameter.Name, parameter.ConfigFile, parameter.Value)
	}
	return r, err
}

// getAtsProfiles gets the profile IDs of all profiles assigned to an Edge or Mid in the database
func getAtsProfileIds(db *sql.DB) ([]int, error) {
	rows, err := db.Query("select distinct profile from server where type in (select id from type where name = 'EDGE' or name = 'MID');")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var profiles []int
	for rows.Next() {
		var id int
		rows.Scan(&id)
		profiles = append(profiles, id)
	}
	return profiles, nil
}

func getProfileName(db *sql.DB, profileId int) (string, error) {
	var name string
	err := db.QueryRow("select name from profiles where id = $1;", profileId).Scan(&name)
	return name, err
}

// DEBUG: more target columns than expressios
func saveRecord(db *sql.DB, r api.CachingProxyRecord) error {
	// this could be built from db tags in the struct, via reflection

	fmt.Println("DEBUG inserting record")
	fmt.Printf("DEBUG UpdateRetryInterval: %v\n", r.UpdateRetryInterval.Seconds())
	fmt.Printf("DEBUG MaxRevalDuration: %v\n", r.MaxRevalDuration.Seconds())

	query := `INSERT INTO caching_proxy_record_data (
profile,
accept_threads,
admin_user,
user_id,
autoconf_port,
number_config,
alarm_abs_path,
alarm_bin,
alarm_email,
allocator_debug_filter,
allocator_enable_reclaim,
allocator_huge_pages,
allocator_max_overage,
allocator_thread_freelist_size,
body_factory_enable_customizations,
body_factory_enable_logging,
body_factory_response_suppression_mode,
body_factory_template_sets_dir,
enable_read_while_writer,
cluster_configuration,
cluster_cluster_port,
cluster_ethernet_interface,
cluster_log_bogus_mc_msgs,
cluster_mc_group_addr,
cluster_mc_ttl,
cluster_mcport,
cluster_rsport,
config_dir,
core_limit,
diags_debug_enabled,
diags_debug_tags,
diags_show_location,
dns_max_dns_in_flight,
dns_nameservers,
dns_resolv_conf,
dns_round_robin_nameservers,
dns_search_default_domains,
dns_splitDNS_enabled,
dns_url_expansions,
dns_validate_query_name,
dump_mem_info_frequency,
env_prep,
exec_thread_affinity,
exec_thread_autoconfig,
exec_thread_autoconfig_scale,
exec_thread_limit,
parse_no_host_url_redirect,
icp_enabled,
icp_interface,
icp_port,
icp_multicast_enabled,
icp_query_timeout,
mloc_enabled,
net_connections_throttle,
net_defer_accept,
net_sock_recv_buffer_size_in,
net_sock_recv_buffer_size_out,
net_sock_send_buffer_size_in,
net_sock_send_buffer_size_out,
output_logfile,
process_manager_management_port,
proxy_binary_opts,
proxy_name,
reverse_proxy_enabled,
snapshot_dir,
stack_dump_enabled,
syslog_facility,
system_mmap_max,
task_threads,
temp_dir,
update_concurrent_updates,
update_enabled,
update_force,
update_retry_count,
update_retry_interval,
url_remap_default_to_server_pac,
url_remap_default_to_server_pac_port,
url_remap_filename,
url_remap_pristine_host_hdr,
url_remap_remap_required,
cron_ort_syncds_cdn,
domain_name,
health_connection_timeout,
health_polling_url,
health_threshold_available_bandwidth_kbps,
health_threshold_load_average,
health_threshold_query_time,
history_count,
cache_interim_storage,
local_cluster_type,
local_log_collation_mode,
log_format_format,
log_format_name,
max_reval_duration,
astats_path,
qstring,
astats_record_types,
regex_revalidate,
astats_library,
traffic_server_chkconfig,
crconfig_weight,
parent_config_weight
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45::double precision, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $70, $71, $72, $73, $74, $75 * INTERVAL '1 second', $76, $77, $78, $79, $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $90, $91, $92, $93, $94 * INTERVAL '1 second', $95, $96, $97, $98, $99, $100, $101, $102);`
	_, err := db.Exec(query,
		r.Profile,
		//		r.Location,
		//		r.DnsLookupTimeout,
		//		r.IpAllowFilename,
		r.AcceptThreads,
		r.AdminUser,
		r.UserId,
		r.AutoconfPort,
		r.NumberConfig,
		r.AlarmAbsPath,
		r.AlarmBin,
		r.AlarmEmail,
		r.AllocatorDebugFilter,
		r.AllocatorEnableReclaim,
		r.AllocatorHugePages,
		r.AllocatorMaxOverage,
		r.AllocatorThreadFreelistSize,
		r.BodyFactoryEnableCustomizations,
		r.BodyFactoryEnableLogging,
		r.BodyFactoryResponseSuppressionMode,
		r.BodyFactoryTemplateSetsDir,
		r.EnableReadWhileWriter,
		r.ClusterConfiguration,
		r.ClusterClusterPort,
		r.ClusterEthernetInterface,
		r.ClusterLogBogusMcMsgs,
		r.ClusterMcGroupAddr,
		r.ClusterMcTtl,
		r.ClusterMcport,
		r.ClusterRsport,
		r.ConfigDir,
		r.CoreLimit,
		r.DiagsDebugEnabled,
		r.DiagsDebugTags,
		r.DiagsShowLocation,
		r.DnsMaxDnsInFlight,
		r.DnsNameservers,
		r.DnsResolvConf,
		r.DnsRoundRobinNameservers,
		r.DnsSearchDefaultDomains,
		r.DnsSplitDnsEnabled,
		r.DnsUrlExpansions,
		r.DnsValidateQueryName,
		r.DumpMemInfoFrequency,
		r.EnvPrep,
		r.ExecThreadAffinity,
		r.ExecThreadAutoconfig,
		r.ExecThreadAutoconfigScale,
		r.ExecThreadLimit,
		r.ParseNoHostUrlRedirect,
		r.IcpEnabled,
		r.IcpInterface,
		r.IcpPort,
		r.IcpMulticastEnabled,
		r.IcpQueryTimeout,
		r.MlocEnabled,
		r.NetConnectionsThrottle,
		r.NetDeferAccept,
		r.NetSockRecvBufferSizeIn,
		r.NetSockRecvBufferSizeOut,
		r.NetSockSendBufferSizeIn,
		r.NetSockSendBufferSizeOut,
		r.OutputLogfile,
		r.ProcessManagerManagementPort,
		r.ProxyBinaryOpts,
		r.ProxyName,
		r.ReverseProxyEnabled,
		r.SnapshotDir,
		r.StackDumpEnabled,
		r.SyslogFacility,
		r.SystemMmapMax,
		r.TaskThreads,
		r.TempDir,
		r.UpdateConcurrentUpdates,
		r.UpdateEnabled,
		r.UpdateForce,
		r.UpdateRetryCount,
		r.UpdateRetryInterval.Seconds(),
		r.UrlRemapDefaultToServerPac,
		r.UrlRemapDefaultToServerPacPort,
		r.UrlRemapFilename,
		r.UrlRemapPristineHostHdr,
		r.UrlRemapRemapRequired,
		r.CronOrtSyncdsCdn,
		r.DomainName,
		r.HealthConnectionTimeout,
		r.HealthPollingUrl,
		r.HealthThresholdAvailableBandwidthKbps,
		r.HealthThresholdLoadAverage,
		r.HealthThresholdQueryTime,
		r.HistoryCount,
		r.CacheInterimStorage,
		r.LocalClusterType,
		r.LocalLogCollationMode,
		r.LogFormatFormat,
		r.LogFormatName,
 		r.MaxRevalDuration.Seconds(),
 		r.AstatsPath,
 		r.Qstring,
 		r.AstatsRecordTypes,
		r.RegexRevalidate,
 		r.AstatsLibrary,
 		r.TrafficServerChkconfig,
		r.CrconfigWeight,
		r.ParentConfigWeight,
	)

	if err != nil {
		fmt.Println("DEBUG RECORD DATA ERR")
		return err
	}

	fmt.Println("DEBUG inserting ssl")

	query = `INSERT INTO caching_proxy_record_data_ssl (
profile,
ca_cert_filename,
ca_cert_path,
client_ca_cert_filename,
client_ca_cert_path,
client_cert_filename,
client_cert_path,
client_certification_level,
client_private_key_filename,
client_private_key_path,
client_verify_server,
compression,
number_threads,
server_cert_path,
server_cert_chain_filename,
server_cipher_suite,
server_honor_cipher_order,
server_multicert_filename,
server_private_key_path,
SSLv2,
SSLv3,
TLSv1
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22)`
	_, err = db.Exec(query,
		r.Profile,
		r.Ssl.CaCertFilename,
		r.Ssl.CaCertPath,
		r.Ssl.ClientCaCertFilename,
		r.Ssl.ClientCaCertPath,
		r.Ssl.ClientCertFilename,
		r.Ssl.ClientCertPath,
		r.Ssl.ClientCertificationLevel,
		r.Ssl.ClientPrivateKeyFilename,
		r.Ssl.ClientPrivateKeyPath,
		r.Ssl.ClientVerifyServer,
		r.Ssl.Compression,
		r.Ssl.NumberThreads,
		r.Ssl.ServerCertPath,
		r.Ssl.ServerCertChainFilename,
		r.Ssl.ServerCipherSuite,
		r.Ssl.ServerHonorCipherOrder,
		r.Ssl.ServerMulticertFilename,
		r.Ssl.ServerPrivateKeyPath,
		r.Ssl.Sslv2,
		r.Ssl.Sslv3,
		r.Ssl.Tlsv1)

	fmt.Println("DEBUG inserting hostdb")

	query = `INSERT INTO caching_proxy_record_data_hostdb (
profile,
server_stale_for,
size,
storage_size,
strict_round_robin,
timeout,
ttl_mode
) VALUES ($1, $2 * INTERVAL '1 second', $3, $4, $5, $6, $7)`
	_, err = db.Exec(query,
		r.Profile,
		r.HostDb.ServerStaleFor.Seconds(),
		r.HostDb.Size,
		r.HostDb.StorageSize,
		r.HostDb.StrictRoundRobin,
		r.HostDb.Timeout,
		r.HostDb.TtlMode)

	if err != nil {
		return err
	}

	fmt.Println("DEBUG inserting cache")

	query = `INSERT INTO caching_proxy_cache (
profile,
filename,
hosting_filename,
http_compatability_420_fixup,
limits_http_max_alts,
max_doc_size,
min_average_object_size,
mutex_retry_delay,
permit_pinning,
ram_cache_algorithm,
ram_cache_compress,
ram_cache_size,
ram_cache_use_seen_filter,
ram_cache_cutoff,
target_fragment_size,
threads_per_disk
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)`

	_, err = db.Exec(query,
		r.Profile,
		r.Cache.ControlFilename,
		r.Cache.HostingFilename,
		r.Cache.HttpCompatability420Fixup,
		r.Cache.LimitsHttpMaxAlts,
		r.Cache.MaxDocSize,
		r.Cache.MinAverageObjectSize,
		r.Cache.MutexRetryDelay,
		r.Cache.PermitPinning,
		r.Cache.RamCacheAlgorithm,
		r.Cache.RamCacheCompress,
		r.Cache.RamCacheSize,
		r.Cache.RamCacheUseSeenFilter,
		r.Cache.RamCacheCutoff,
		r.Cache.TargetFragmentSize,
		r.Cache.ThreadsPerDisk)

	if err != nil {
		return err
	}

	fmt.Println("DEBUG inserting http")

	query = `INSERT INTO caching_proxy_record_data_http (
profile,
accept_no_activity_timeout,
anonymize_insert_client_ip,
anonymize_other_header_list,
anonymize_remove_client_ip,
anonymize_remove_cookie,
anonymize_remove_from,
anonymize_remove_referer,
anonymize_remove_user_agent,
background_fill_active_timeout,
background_fill_completed_threshold,
chunking_enabled,
congestion_control_enabled,
connect_attempts_max_retries,
connect_attempts_max_retries_dead_server,
connect_attempts_rr_retries,
connect_attempts_timeout,
down_server_abort_threshold,
down_server_cache_time,
enable_http_stats,
enable_url_expandomatic,
forward_proxy_auth_to_parent,
insert_age_in_response,
insert_request_via_str,
insert_response_via_str,
insert_squid_x_forwarded_for,
keep_alive_enabled_in,
keep_alive_enabled_out,
keep_alive_enabled_no_activity_timeout_in,
keep_alive_enabled_no_activity_timeout_out,
negative_caching_enabled,
negative_caching_lifetime,
no_dns_just_forward_to_parent,
normalize_ae_gzip,
origin_server_pipeline,
parent_proxy_connect_attempts_timeout,
parent_proxy_fail_threshold,
parent_proxy_file,
parent_proxy_per_parent_connection_attempts,
parent_proxy_parent_proxy_retry_time,
parent_proxy_parent_proxy_total_connection_attempts,
parent_proxy_parent_proxy_routing_enable,
post_connect_attempts_timeout,
parent_push_method_enabled,
referer_default_redirect,
referer_filter,
referer_format_redirect,
response_server_enabled,
send_http11_requests,
share_server_sessions,
slow_log_threshold,
transaction_active_timeout_in,
transaction_active_timeout_out,
transaction_no_activity_timeout_in,
transaction_no_activity_timeout_out,
uncacheable_requests_bypass_parent,
user_agent_pipeline
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57)`

	_, err = db.Exec(query,
		r.Profile,
		r.Http.AcceptNoActivityTimeout,
		r.Http.AnonymizeInsertClientIp,
		r.Http.AnonymizeOtherHeaderList,
		r.Http.AnonymizeRemoveClientIp,
		r.Http.AnonymizeRemoveCookie,
		r.Http.AnonymizeRemoveFrom,
		r.Http.AnonymizeRemoveReferer,
		r.Http.AnonymizeRemoveUserAgent,
		r.Http.BackgroundFillActiveTimeout,
		r.Http.BackgroundFillCompletedThreshold,
		r.Http.ChunkingEnabled,
		r.Http.CongestionControlEnabled,
		r.Http.ConnectAttemptsMaxRetries,
		r.Http.ConnectAttemptsMaxRetriesDeadServer,
		r.Http.ConnectAttemptsRrRetries,
		r.Http.ConnectAttemptsTimeout,
		r.Http.DownServerAbortThreshold,
		r.Http.DownServerCacheTime,
		r.Http.EnableHttpStats,
		r.Http.EnableUrlExpandomatic,
		r.Http.ForwardProxyAuthToParent,
		r.Http.InsertAgeInResponse,
		r.Http.InsertRequestViaStr,
		r.Http.InsertResponseViaStr,
		r.Http.InsertSquidXForwardedFor,
		r.Http.KeepAliveEnabledIn,
		r.Http.KeepAliveEnabledOut,
		r.Http.KeepAliveEnabledNoActivityTimeoutIn,
		r.Http.KeepAliveEnabledNoActivityTimeoutOut,
		r.Http.NegativeCachingEnabled,
		r.Http.NegativeCachingLifetime,
		r.Http.NoDnsJustForwardToParent,
		r.Http.NormalizeAeGzip,
		r.Http.OriginServerPipeline,
		r.Http.ParentProxyConnectAttemptsTimeout,
		r.Http.ParentProxyFailThreshold,
		r.Http.ParentProxyFile,
		r.Http.ParentProxyPerParentConnectionAttempts,
		r.Http.ParentProxyParentProxyRetryTime,
		r.Http.ParentProxyParentProxyTotalConnectionAttempts,
		r.Http.ParentProxyParentProxyRoutingEnable,
		r.Http.PostConnectAttemptsTimeout,
		r.Http.ParentPushMethodEnabled,
		r.Http.RefererDefaultRedirect,
		r.Http.RefererFilter,
		r.Http.RefererFormatRedirect,
		r.Http.ResponseServerEnabled,
		r.Http.SendHttp11Requests,
		r.Http.ShareServerSessions,
		r.Http.SlowLogThreshold,
		r.Http.TransactionActiveTimeoutIn.Seconds(),
		r.Http.TransactionActiveTimeoutOut.Seconds(),
		r.Http.TransactionNoActivityTimeoutIn.Seconds(),
		r.Http.TransactionNoActivityTimeoutOut.Seconds(),
		r.Http.UncacheableRequestsBypassParent,
		r.Http.UserAgentPipeline)

	if err != nil {
		return err
	}

	fmt.Println("DEBUG inserting http cache")

	query = `INSERT INTO caching_proxy_record_data_http_cache (
profile,
allow_empty_doc,
cache_responses_to_cookies,
cache_urls_that_look_dynamic,
enable_default_vary_headers,
fuzz_probability,
fuzz_time,
heuristic_lm_factor,
heuristic_max_lifetime,
heuristic_min_lifetime,
http,
ignore_accept_encoding_mismatch,
ignore_authentication,
ignore_client_cc_max_age,
ignore_client_no_cache,
ignore_server_no_cache,
ims_on_client_no_cache,
max_stale_age,
range_lookup,
required_headers,
vary_default_images,
vary_default_other,
vary_default_text,
when_to_add_no_cache_to_msie_requests,
when_to_revalidate
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25)`

	_, err = db.Exec(query,
		r.Profile,
		r.Http.Cache.AllowEmptyDoc,
		r.Http.Cache.CacheResponsesToCookies,
		r.Http.Cache.CacheUrlsThatLookDynamic,
		r.Http.Cache.EnableDefaultVaryHeaders,
		r.Http.Cache.FuzzProbability,
		r.Http.Cache.FuzzTime.Seconds(),
		r.Http.Cache.HeuristicLmFactor,
		r.Http.Cache.HeuristicMaxLifetime,
		r.Http.Cache.HeuristicMinLifetime,
		r.Http.Cache.Http,
		r.Http.Cache.IgnoreAcceptEncodingMismatch,
		r.Http.Cache.IgnoreAuthentication,
		r.Http.Cache.IgnoreClientCcMaxAge,
		r.Http.Cache.IgnoreClientNoCache,
		r.Http.Cache.IgnoreServerNoCache,
		r.Http.Cache.ImsOnClientNoCache,
		r.Http.Cache.MaxStaleAge,
		r.Http.Cache.RangeLookup,
		r.Http.Cache.RequiredHeaders,
		r.Http.Cache.VaryDefaultImages,
		r.Http.Cache.VaryDefaultOther,
		r.Http.Cache.VaryDefaultText,
		r.Http.Cache.WhenToAddNoCacheToMsieRequests,
		r.Http.Cache.WhenToRevalidate)

	if err != nil {
		return err
	}

	fmt.Println("DEBUG inserting log")

	query = `INSERT INTO caching_proxy_record_data_log (
profile,
auto_delete_rolled_files,
collation_host,
collation_host_tagged,
collation_port,
collation_retry,
collation_secret,
custom_logs_enabled,
hostname,
logfile_dir,
logfile_perm,
logging_enabled,
max_secs_per_buffer,
max_space_mb_for_logs,
max_space_mb_for_orphan_logs,
max_space_mb_headroom,
rolling_enabled,
rolling_interval,
rolling_offset,
rolling_size_mb,
sampling_frequency,
separate_host_logs,
separate_icp_logs,
xml_config_file
)	VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24)`

	_, err = db.Exec(query,
		r.Profile,
		r.Log.AutoDeleteRolledFiles,
		r.Log.CollationHost,
		r.Log.CollationHostTagged,
		r.Log.CollationPort,
		r.Log.CollationRetry.Seconds(),
		r.Log.CollationSecret,
		r.Log.CustomLogsEnabled,
		r.Log.Hostname,
		r.Log.LogfileDir,
		r.Log.LogfilePerm,
		r.Log.LoggingEnabled,
		r.Log.MaxSecsPerBuffer,
		r.Log.MaxSpaceMbForLogs,
		r.Log.MaxSpaceMbForOrphanLogs,
		r.Log.MaxSpaceMbHeadroom,
		r.Log.RollingEnabled,
		r.Log.RollingInterval.Seconds(),
		r.Log.RollingOffset.Seconds(),
		r.Log.RollingSizeMb,
		r.Log.SamplingFrequency,
		r.Log.SeparateHostLogs,
		r.Log.SeparateIcpLogs,
		r.Log.XmlConfigFile)

	if err != nil {
		return err
	}


	err = saveRecordLogData(db, r.Profile, r.Log.Squid)
	if err != nil {
		return err
	}
	err = saveRecordLogData(db, r.Profile, r.Log.Common)
	if err != nil {
		return err
	}
	err = saveRecordLogData(db, r.Profile, r.Log.Extended)
	if err != nil {
		return err
	}
	err = saveRecordLogData(db, r.Profile, r.Log.Extended2)
	if err != nil {
		return err
	}

	for _, p := range r.ServerPorts {
		fmt.Println("DEBUG inserting server port")
		query = `INSERT INTO caching_proxy_records_data_http_server_ports (
profile,
port,
ipv6,
ssl
) VALUES ($1, $2, $3, $4)`
		_, err = db.Exec(query,
			r.Profile,
			p.Port,
			p.IPv6,
			p.SSL)
		if err != nil {
			return err
		}
	}

	for _, p := range r.ConnectPorts {
		fmt.Println("DEBUG inserting connect port")
		query := `INSERT INTO caching_proxy_records_data_http_connect_ports (
profile,
port
) VALUES ($1, $2)`
		_, err = db.Exec(query,
			r.Profile,
			p)
		if err != nil {
			return err
		}
	}

	return err
}

func saveRecordLogData(db *sql.DB, profile string, r api.CachingProxyRecordLogData) error {
	fmt.Println("DEBUG record data log " + profile)
	query := `INSERT INTO caching_proxy_record_data_log_data (
profile,
name,
enabled,
header,
is_ascii
) VALUES ($1, $2, $3, $4, $5)`
	_, err := db.Exec(query,
		profile,
		r.Name,
		r.Enabled,
		r.Header,
		r.IsAscii)
	return err
}

func main() {
	args, err := getFlags()
	if err != nil {
		log.Println(err)
		return
	}

	if args.Server == "localhost" && args.Port == 5432 && args.User == "" && args.Pass == "" && args.Database == "" {
		flag.Usage()
		return
	}

	connStr, err := createConnectionStringPostgres(args.Server, args.Database, args.User, args.Pass, args.Port)
	if err != nil {
		log.Println(err)
		return
	}

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Println(err)
		return
	}

	profileIds, err := getAtsProfileIds(db)
	if err != nil {
		log.Println(err)
		return
	}

	for _, profileId := range profileIds {
		var record api.CachingProxyRecord
		var err error
		record.Profile, err = getProfileName(db, profileId)
		if err != nil {
			log.Println(err)
			continue
		}
		parameters, err := getParametersForProfile(db, profileId)
		if err != nil {
			log.Println(err)
		}
		for _, parameter := range parameters {
			record, err = processParameter(db, parameter, profileId, record)
			if err != nil {
				log.Println(err)
			}
		}
//		fmt.Println(record)
		err = saveRecord(db, record)
		if err != nil {
			log.Println(err)
		}

//		fmt.Println("Processed:")
//		fmt.Println(record)
//		fmt.Printf("\n")
	}
}
