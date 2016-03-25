// Copyright 2015 Comcast Cable Communications Management, LLC

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// \todo change time members to ISO 8601 strings, instead of nanosecond integers.

package api

import (
	_ "github.com/Comcast/traffic_control/traffic_ops/experimental/server/output_format" // needed for swagger
	"github.com/jmoiron/sqlx"
	"log"
	"time"
)

type CachingProxyRecordPort struct {
	Port uint `json:"port"`
	IPv6 bool `json:"ipv6"`
	SSL  bool `json:"ssl"`
}

type CachingProxyRecordSSL struct {
	Profile                  string `db:"profile" json:"-"`
	ClientCaCertFilename     string `db:"client_ca_cert_filename"`
	ClientCaCertPath         string `db:"client_ca_cert_path"`
	ClientCertFilename       string `db:"client_cert_filename"`
	ClientCertPath           string `db:"client_cert_path"`
	ClientCertificationLevel int    `db:"client_certification_level"`
	ClientPrivateKeyFilename string `db:"client_private_key_filename"`
	ClientPrivateKeyPath     string `db:"client_private_key_path"`
	ClientVerifyServer       int    `db:"client_verify_server"`
	Compression              int    `db:"compression"`
	NumberThreads            int    `db:"number_threads"`
	ServerCertPath           string `db:"server_cert_path"`
	ServerCertChainFilename  string `db:"server_cert_chain_filename"`
	ServerCipherSuite        string `db:"server_cipher_suite"`
	ServerHonorCipherOrder   int    `db:"server_honor_cipher_order"`
	ServerMulticertFilename  string `db:"server_multicert_filename"`
	ServerPrivateKeyPath     string `db:"server_private_key_path"`
	Sslv2                    bool   `db:"sslv2"`
	Sslv3                    bool   `db:"sslv3"`
	Tlsv1                    bool   `db:"tlsv1"`
	CaCertFilename           string `db:"ca_cert_filename"`
	CaCertPath               string `db:"ca_cert_path"`
}

type CachingProxyRecordHostDb struct {
	Profile          string        `db:"profile" json:"-"`
	ServerStaleFor   time.Duration `db:"server_stale_for"`
	Size             int           `db:"size"`
	StorageSize      int           `db:"storage_size"`
	StrictRoundRobin bool          `db:"strict_round_robin"`
	Timeout          int           `db:"timeout"`
	TtlMode          string        `db:"ttl_mode"`
}

type CachingProxyRecordCache struct {
	Profile                   string `db:"profile" json:"-"`
	ControlFilename           string `db:"filename"`
	HostingFilename           string `db:"hosting_filename"`
	HttpCompatability420Fixup int    `db:"http_compatability_420_fixup"`
	LimitsHttpMaxAlts         int    `db:"limits_http_max_alts"`
	MaxDocSize                int    `db:"max_doc_size"`
	MinAverageObjectSize      int    `db:"min_average_object_size"`
	MutexRetryDelay           int    `db:"mutex_retry_delay"`
	PermitPinning             int    `db:"permit_pinning"`
	RamCacheAlgorithm         int    `db:"ram_cache_algorithm"`
	RamCacheCompress          int    `db:"ram_cache_compress"`
	RamCacheSize              int    `db:"ram_cache_size"`
	RamCacheUseSeenFilter     bool   `db:"ram_cache_use_seen_filter"`
	RamCacheCutoff            int    `db:"ram_cache_cutoff"`
	TargetFragmentSize        int    `db:"target_fragment_size"`
	ThreadsPerDisk            int    `db:"threads_per_disk"`
}

type CachingProxyRecordHttpCache struct {
	Profile                        string        `db:"profile" json:"-"`
	AllowEmptyDoc                  bool          `db:"allow_empty_doc"`
	CacheResponsesToCookies        string        `db:"cache_responses_to_cookies"`
	CacheUrlsThatLookDynamic       bool          `db:"cache_urls_that_look_dynamic"`
	EnableDefaultVaryHeaders       bool          `db:"enable_default_vary_headers"`
	FuzzProbability                float64       `db:"fuzz_probability"`
	FuzzTime                       time.Duration `db:"fuzz_time"`
	HeuristicLmFactor              float64       `db:"heuristic_lm_factor"`
	HeuristicMaxLifetime           int           `db:"heuristic_max_lifetime"`
	HeuristicMinLifetime           int           `db:"heuristic_min_lifetime"`
	Http                           bool          `db:"http"`
	IgnoreAcceptEncodingMismatch   bool          `db:"ignore_accept_encoding_mismatch"`
	IgnoreAuthentication           bool          `db:"ignore_authentication"`
	IgnoreClientCcMaxAge           int           `db:"ignore_client_cc_max_age"`
	IgnoreClientNoCache            bool          `db:"ignore_client_no_cache"`
	IgnoreServerNoCache            bool          `db:"ignore_server_no_cache"`
	ImsOnClientNoCache             bool          `db:"ims_on_client_no_cache"`
	MaxStaleAge                    int           `db:"max_stale_age"`
	RangeLookup                    bool          `db:"range_lookup"`
	RequiredHeaders                string        `db:"required_headers"`
	VaryDefaultImages              string        `db:"vary_default_images"`
	VaryDefaultOther               string        `db:"vary_default_other"`
	VaryDefaultText                string        `db:"vary_default_text"`
	WhenToAddNoCacheToMsieRequests int           `db:"when_to_add_no_cache_to_msie_requests"`
	WhenToRevalidate               string        `db:"when_to_revalidate"`
}

type CachingProxyRecordHttp struct {
	Profile string `db:"profile" json:"-"`
	Cache   CachingProxyRecordHttpCache

	AcceptNoActivityTimeout                       int           `db:"accept_no_activity_timeout"`
	AnonymizeInsertClientIp                       int           `db:"anonymize_insert_client_ip"`
	AnonymizeOtherHeaderList                      string        `db:"anonymize_other_header_list"`
	AnonymizeRemoveClientIp                       bool          `db:"anonymize_remove_client_ip"`
	AnonymizeRemoveCookie                         bool          `db:"anonymize_remove_cookie"`
	AnonymizeRemoveFrom                           bool          `db:"anonymize_remove_from"`
	AnonymizeRemoveReferer                        bool          `db:"anonymize_remove_referer"`
	AnonymizeRemoveUserAgent                      bool          `db:"anonymize_remove_user_agent"`
	BackgroundFillActiveTimeout                   int           `db:"background_fill_active_timeout"`
	BackgroundFillCompletedThreshold              float64       `db:"background_fill_completed_threshold"`
	ChunkingEnabled                               string        `db:"chunking_enabled"`
	CongestionControlEnabled                      bool          `db:"congestion_control_enabled"`
	ConnectAttemptsMaxRetries                     int           `db:"connect_attempts_max_retries"`
	ConnectAttemptsMaxRetriesDeadServer           int           `db:"connect_attempts_max_retries_dead_server"`
	ConnectAttemptsRrRetries                      int           `db:"connect_attempts_rr_retries"`
	ConnectAttemptsTimeout                        int           `db:"connect_attempts_timeout"`
	DownServerAbortThreshold                      int           `db:"down_server_abort_threshold"`
	DownServerCacheTime                           int           `db:"down_server_cache_time"`
	EnableHttpStats                               bool          `db:"enable_http_stats"`
	EnableUrlExpandomatic                         bool          `db:"enable_url_expandomatic"`
	ForwardProxyAuthToParent                      bool          `db:"forward_proxy_auth_to_parent"`
	InsertAgeInResponse                           bool          `db:"insert_age_in_response"`
	InsertRequestViaStr                           string        `db:"insert_request_via_str"`
	InsertResponseViaStr                          string        `db:"insert_response_via_str"`
	InsertSquidXForwardedFor                      bool          `db:"insert_squid_x_forwarded_for"`
	KeepAliveEnabledIn                            bool          `db:"keep_alive_enabled_in"`
	KeepAliveEnabledOut                           bool          `db:"keep_alive_enabled_out"`
	KeepAliveEnabledNoActivityTimeoutIn           int           `db:"keep_alive_enabled_no_activity_timeout_in"`
	KeepAliveEnabledNoActivityTimeoutOut          int           `db:"keep_alive_enabled_no_activity_timeout_out"`
	NegativeCachingEnabled                        bool          `db:"negative_caching_enabled"`
	NegativeCachingLifetime                       int           `db:"negative_caching_lifetime"`
	NoDnsJustForwardToParent                      bool          `db:"no_dns_just_forward_to_parent"`
	NormalizeAeGzip                               bool          `db:"normalize_ae_gzip"`
	OriginServerPipeline                          int           `db:"origin_server_pipeline"`
	ParentProxyConnectAttemptsTimeout             int           `db:"parent_proxy_connect_attempts_timeout"`
	ParentProxyFailThreshold                      int           `db:"parent_proxy_fail_threshold"`
	ParentProxyFile                               string        `db:"parent_proxy_file"`
	ParentProxyPerParentConnectionAttempts        int           `db:"parent_proxy_per_parent_connection_attempts"`
	ParentProxyParentProxyRetryTime               int           `db:"parent_proxy_parent_proxy_retry_time"`
	ParentProxyParentProxyTotalConnectionAttempts int           `db:"parent_proxy_parent_proxy_total_connection_attempts"`
	ParentProxyParentProxyRoutingEnable           bool          `db:"parent_proxy_parent_proxy_routing_enable"`
	PostConnectAttemptsTimeout                    int           `db:"post_connect_attempts_timeout"`
	ParentPushMethodEnabled                       bool          `db:"parent_push_method_enabled"`
	RefererDefaultRedirect                        string        `db:"referer_default_redirect"`
	RefererFilter                                 int           `db:"referer_filter"`
	RefererFormatRedirect                         int           `db:"referer_format_redirect"`
	ResponseServerEnabled                         string        `db:"response_server_enabled"`
	SendHttp11Requests                            string        `db:"send_http11_requests"`
	ShareServerSessions                           int           `db:"share_server_sessions"`
	SlowLogThreshold                              int           `db:"slow_log_threshold"`
	TransactionActiveTimeoutIn                    time.Duration `db:"transaction_active_timeout_in"`
	TransactionActiveTimeoutOut                   time.Duration `db:"transaction_active_timeout_out"`
	TransactionNoActivityTimeoutIn                time.Duration `db:"transaction_no_activity_timeout_in"`
	TransactionNoActivityTimeoutOut               time.Duration `db:"transaction_no_activity_timeout_out"`
	UncacheableRequestsBypassParent               bool          `db:"uncacheable_requests_bypass_parent"`
	UserAgentPipeline                             int           `db:"user_agent_pipeline"`
}

type CachingProxyRecordLogData struct {
	Profile string `db:"profile" json:"-"`
	Name    string `db:"name"`
	Enabled bool   `db:"enabled"`
	Header  string `db:"header"`
	IsAscii bool   `db:"is_ascii"`
}

type CachingProxyRecordLog struct {
	Profile string `db:"profile" json:"-"`

	Squid     CachingProxyRecordLogData
	Common    CachingProxyRecordLogData
	Extended2 CachingProxyRecordLogData
	Extended  CachingProxyRecordLogData

	AutoDeleteRolledFiles   bool          `db:"auto_delete_rolled_files"`
	CollationHost           string        `db:"collation_host"`
	CollationHostTagged     bool          `db:"collation_host_tagged"`
	CollationPort           int           `db:"collation_port"`
	CollationRetry          time.Duration `db:"collation_retry"`
	CollationSecret         string        `db:"collation_secret"`
	CustomLogsEnabled       int           `db:"custom_logs_enabled"`
	Hostname                string        `db:"hostname"`
	LogfileDir              string        `db:"logfile_dir"`
	LogfilePerm             string        `db:"logfile_perm"`
	LoggingEnabled          string        `db:"logging_enabled"`
	MaxSecsPerBuffer        int           `db:"max_secs_per_buffer"`
	MaxSpaceMbForLogs       int           `db:"max_space_mb_for_logs"`
	MaxSpaceMbForOrphanLogs int           `db:"max_space_mb_for_orphan_logs"`
	MaxSpaceMbHeadroom      int           `db:"max_space_mb_headroom"`
	RollingEnabled          string        `db:"rolling_enabled"`
	RollingInterval         time.Duration `db:"rolling_interval"`
	RollingOffset           time.Duration `db:"rolling_offset"`
	RollingSizeMb           int           `db:"rolling_size_mb"`
	SamplingFrequency       int           `db:"sampling_frequency"`
	SeparateHostLogs        int           `db:"separate_host_logs"`
	SeparateIcpLogs         int           `db:"separate_icp_logs"`
	XmlConfigFile           string        `db:"xml_config_file"`
}

type CachingProxyRecord struct {
	Profile string `db:"profile"`

	Ssl    CachingProxyRecordSSL
	HostDb CachingProxyRecordHostDb
	Cache  CachingProxyRecordCache
	Http   CachingProxyRecordHttp
	Log    CachingProxyRecordLog

	// \todo add these to sql schema
	Location         string        `db:"location"`
	DnsLookupTimeout time.Duration `db:"dns_lookup_timeout"`
	IpAllowFilename  string        `db:"ip_allow_filename"`

	AcceptThreads                         int           `db:"accept_threads"`
	AdminUser                             string        `db:"admin_user"`
	UserId                                string        `db:"user_id"`
	AutoconfPort                          int           `db:"autoconf_port"`
	NumberConfig                          int           `db:"number_config"`
	AlarmAbsPath                          string        `db:"alarm_abs_path"`
	AlarmBin                              string        `db:"alarm_bin"`
	AlarmEmail                            string        `db:"alarm_email"`
	AllocatorDebugFilter                  int           `db:"allocator_debug_filter"`
	AllocatorEnableReclaim                bool          `db:"allocator_enable_reclaim"`
	AllocatorHugePages                    bool          `db:"allocator_huge_pages"`
	AllocatorMaxOverage                   int           `db:"allocator_max_overage"`
	AllocatorThreadFreelistSize           int           `db:"allocator_thread_freelist_size"`
	BodyFactoryEnableCustomizations       string        `db:"body_factory_enable_customizations"`
	BodyFactoryEnableLogging              bool          `db:"body_factory_enable_logging"`
	BodyFactoryResponseSuppressionMode    string        `db:"body_factory_response_suppression_mode"`
	BodyFactoryTemplateSetsDir            string        `db:"body_factory_template_sets_dir"`
	EnableReadWhileWriter                 string        `db:"enable_read_while_writer"`
	ClusterConfiguration                  string        `db:"cluster_configuration"`
	ClusterClusterPort                    int           `db:"cluster_cluster_port"`
	ClusterEthernetInterface              string        `db:"cluster_ethernet_interface"`
	ClusterLogBogusMcMsgs                 int           `db:"cluster_log_bogus_mc_msgs"`
	ClusterMcGroupAddr                    string        `db:"cluster_mc_group_addr"`
	ClusterMcTtl                          int           `db:"cluster_mc_ttl"`
	ClusterMcport                         int           `db:"cluster_mcport"`
	ClusterRsport                         int           `db:"cluster_rsport"`
	ConfigDir                             string        `db:"config_dir"`
	CoreLimit                             int           `db:"core_limit"`
	DiagsDebugEnabled                     bool          `db:"diags_debug_enabled"`
	DiagsDebugTags                        string        `db:"diags_debug_tags"`
	DiagsShowLocation                     bool          `db:"diags_show_location"`
	DnsMaxDnsInFlight                     int           `db:"dns_max_dns_in_flight"`
	DnsNameservers                        string        `db:"dns_nameservers"`
	DnsResolvConf                         string        `db:"dns_resolv_conf"`
	DnsRoundRobinNameservers              bool          `db:"dns_round_robin_nameservers"`
	DnsSearchDefaultDomains               string        `db:"dns_search_default_domains"`
	DnsSplitDnsEnabled                    bool          `db:"dns_splitdns_enabled"`
	DnsUrlExpansions                      string        `db:"dns_url_expansions"`
	DnsValidateQueryName                  bool          `db:"dns_validate_query_name"`
	DumpMemInfoFrequency                  int           `db:"dump_mem_info_frequency"`
	EnvPrep                               string        `db:"env_prep"`
	ExecThreadAffinity                    string        `db:"exec_thread_affinity"`
	ExecThreadAutoconfig                  bool          `db:"exec_thread_autoconfig"`
	ExecThreadAutoconfigScale             float64       `db:"exec_thread_autoconfig_scale"`
	ExecThreadLimit                       int           `db:"exec_thread_limit"`
	ParseNoHostUrlRedirect                string        `db:"parse_no_host_url_redirect"`
	IcpEnabled                            string        `db:"icp_enabled"`
	IcpInterface                          string        `db:"icp_interface"`
	IcpPort                               int           `db:"icp_port"`
	IcpMulticastEnabled                   int           `db:"icp_multicast_enabled"`
	IcpQueryTimeout                       int           `db:"icp_query_timeout"`
	MlocEnabled                           int           `db:"mloc_enabled"`
	NetConnectionsThrottle                int           `db:"net_connections_throttle"`
	NetDeferAccept                        bool          `db:"net_defer_accept"`
	NetSockRecvBufferSizeIn               int           `db:"net_sock_recv_buffer_size_in"`
	NetSockRecvBufferSizeOut              int           `db:"net_sock_recv_buffer_size_out"`
	NetSockSendBufferSizeIn               int           `db:"net_sock_send_buffer_size_in"`
	NetSockSendBufferSizeOut              int           `db:"net_sock_send_buffer_size_out"`
	OutputLogfile                         string        `db:"output_logfile"`
	ProcessManagerManagementPort          int           `db:"process_manager_management_port"`
	ProxyBinaryOpts                       string        `db:"proxy_binary_opts"`
	ProxyName                             string        `db:"proxy_name"`
	ReverseProxyEnabled                   bool          `db:"reverse_proxy_enabled"`
	SnapshotDir                           string        `db:"snapshot_dir"`
	StackDumpEnabled                      int           `db:"stack_dump_enabled"`
	SyslogFacility                        string        `db:"syslog_facility"`
	SystemMmapMax                         int           `db:"system_mmap_max"`
	TaskThreads                           int           `db:"task_threads"`
	TempDir                               string        `db:"temp_dir"`
	UpdateConcurrentUpdates               int           `db:"update_concurrent_updates"`
	UpdateEnabled                         int           `db:"update_enabled"`
	UpdateForce                           int           `db:"update_force"`
	UpdateRetryCount                      int           `db:"update_retry_count"`
	UpdateRetryInterval                   time.Duration `db:"update_retry_interval"`
	UrlRemapDefaultToServerPac            int           `db:"url_remap_default_to_server_pac"`
	UrlRemapDefaultToServerPacPort        *int          `db:"url_remap_default_to_server_pac_port"`
	UrlRemapFilename                      string        `db:"url_remap_filename"`
	UrlRemapPristineHostHdr               int           `db:"url_remap_pristine_host_hdr"`
	UrlRemapRemapRequired                 int           `db:"url_remap_remap_required"`
	CronOrtSyncdsCdn                      string        `db:"cron_ort_syncds_cdn"`
	DomainName                            string        `db:"domain_name"`
	HealthConnectionTimeout               int           `db:"health_connection_timeout"`
	HealthPollingUrl                      string        `db:"health_polling_url"`
	HealthThresholdAvailableBandwidthKbps int           `db:"health_threshold_available_bandwidth_kbps"`
	HealthThresholdLoadAverage            int           `db:"health_threshold_load_average"`
	HealthThresholdQueryTime              int           `db:"health_threshold_query_time"`
	HistoryCount                          int           `db:"history_count"`
	LocalClusterType                      int           `db:"local_cluster_type"`

	LocalLogCollationMode  int           `db:"local_log_collation_mode"`
	LogFormatFormat        string        `db:"log_format_format"`
	LogFormatName          string        `db:"log_format_name"`
	MaxRevalDuration       time.Duration `db:"max_reval_duration"`
	AstatsPath             string        `db:"astats_path"`
	Qstring                string        `db:"qstring"`
	AstatsRecordTypes      int           `db:"astats_record_types"`
	RegexRevalidate        string        `db:"regex_revalidate"`
	AstatsLibrary          string        `db:"astats_library"`
	TrafficServerChkconfig string        `db:"traffic_server_chkconfig"`

	CrconfigWeight     float64 `db:"crconfig_weight"`
	ParentConfigWeight float64 `db:"parent_config_weight"`
	ServerPorts        []CachingProxyRecordPort
	ConnectPorts       []uint

	CacheInterimStorage string `db:"cache_interim_storage"`
}

func loadCachingProxyRecordSsl(profile string, db *sqlx.DB) (CachingProxyRecordSSL, error) {
	ret := []CachingProxyRecordSSL{}
	arg := CachingProxyRecordSSL{Profile: profile}
	queryStr := `select profile, ca_cert_filename, ca_cert_path, client_ca_cert_filename, client_ca_cert_path, client_cert_filename, client_cert_path, client_certification_level, client_private_key_filename, client_private_key_path, client_verify_server, compression, number_threads, server_cert_path, server_cert_chain_filename, server_cipher_suite, server_honor_cipher_order, server_multicert_filename, server_private_key_path, SSLv2, SSLv3, TLSv1 from caching_proxy_record_data_ssl where profile=:profile`
	nstmt, err := db.PrepareNamed(queryStr)
	err = nstmt.Select(&ret, arg)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordSSL{}, err
	}
	nstmt.Close()

	log.Println("DEBUG 0")

	if len(ret) != 1 {
		log.Printf("loadCachingProxyRecordSsl expecting 1 record, query returned %d", len(ret))
		return CachingProxyRecordSSL{}, err
	}

	return ret[0], nil
}

func loadCachingProxyRecordHostDb(profile string, db *sqlx.DB) (CachingProxyRecordHostDb, error) {
	ret := []CachingProxyRecordHostDb{}
	arg := CachingProxyRecordHostDb{Profile: profile}
	queryStr := `select profile, extract(epoch from server_stale_for) as server_stale_for, size, storage_size, strict_round_robin, timeout, ttl_mode from caching_proxy_record_data_hostdb where profile=:profile`
	nstmt, err := db.PrepareNamed(queryStr)
	err = nstmt.Select(&ret, arg)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordHostDb{}, err
	}
	nstmt.Close()

	if len(ret) != 1 {
		log.Printf("loadCachingProxyRecordHostDb expecting 1 record, query returned %d", len(ret))
		return CachingProxyRecordHostDb{}, err
	}

	hostdb := ret[0]
	hostdb.ServerStaleFor *= time.Second // Postgres epoch returns seconds. This multiplies it into nanoseconds, which are the correct internal representation of time.Duration
	return hostdb, nil
}

func loadCachingProxyRecordCache(profile string, db *sqlx.DB) (CachingProxyRecordCache, error) {
	ret := []CachingProxyRecordCache{}
	arg := CachingProxyRecordCache{Profile: profile}
	queryStr := `select profile, filename, hosting_filename, http_compatability_420_fixup, limits_http_max_alts, max_doc_size, min_average_object_size, mutex_retry_delay, permit_pinning, ram_cache_algorithm, ram_cache_compress, ram_cache_size, ram_cache_use_seen_filter, ram_cache_cutoff, target_fragment_size, threads_per_disk from caching_proxy_cache where profile=:profile`
	nstmt, err := db.PrepareNamed(queryStr)
	err = nstmt.Select(&ret, arg)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordCache{}, err
	}
	nstmt.Close()

	if len(ret) != 1 {
		log.Printf("loadCachingProxyRecordCache expecting 1 record, query returned %d", len(ret))
		return CachingProxyRecordCache{}, err
	}

	return ret[0], nil
}

func loadCachingProxyRecordHttpCache(profile string, db *sqlx.DB) (CachingProxyRecordHttpCache, error) {
	ret := []CachingProxyRecordHttpCache{}
	arg := CachingProxyRecordHttpCache{Profile: profile}
	queryStr := `select profile, allow_empty_doc, cache_responses_to_cookies, cache_urls_that_look_dynamic, enable_default_vary_headers, fuzz_probability, extract(epoch from fuzz_time) as fuzz_time, heuristic_lm_factor, heuristic_max_lifetime, heuristic_min_lifetime, http, ignore_accept_encoding_mismatch, ignore_authentication, ignore_client_cc_max_age, ignore_client_no_cache, ignore_server_no_cache, ims_on_client_no_cache, max_stale_age, range_lookup, required_headers, vary_default_images, vary_default_other, vary_default_text, when_to_add_no_cache_to_msie_requests, when_to_revalidate from caching_proxy_record_data_http_cache where profile=:profile`
	nstmt, err := db.PrepareNamed(queryStr)
	err = nstmt.Select(&ret, arg)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordHttpCache{}, err
	}
	nstmt.Close()

	if len(ret) != 1 {
		log.Printf("loadCachingProxyRecordHttpCache expecting 1 record, query returned %d", len(ret))
		return CachingProxyRecordHttpCache{}, err
	}

	httpCache := ret[0]
	httpCache.FuzzTime *= time.Second // Postgres epoch returns seconds. This multiplies it into nanoseconds, which are the correct internal representation of time.Duration
	return httpCache, nil
}

func loadCachingProxyRecordHttp(profile string, db *sqlx.DB) (CachingProxyRecordHttp, error) {
	ret := []CachingProxyRecordHttp{}
	arg := CachingProxyRecordHttp{Profile: profile}
	queryStr := `select profile, accept_no_activity_timeout, anonymize_insert_client_ip, anonymize_other_header_list, anonymize_remove_client_ip, anonymize_remove_cookie, anonymize_remove_from, anonymize_remove_referer, anonymize_remove_user_agent, background_fill_active_timeout, background_fill_completed_threshold, chunking_enabled, congestion_control_enabled, connect_attempts_max_retries, connect_attempts_max_retries_dead_server, connect_attempts_rr_retries, connect_attempts_timeout, down_server_abort_threshold, down_server_cache_time, enable_http_stats, enable_url_expandomatic, forward_proxy_auth_to_parent, insert_age_in_response, insert_request_via_str, insert_response_via_str, insert_squid_x_forwarded_for, keep_alive_enabled_in, keep_alive_enabled_out, keep_alive_enabled_no_activity_timeout_in, keep_alive_enabled_no_activity_timeout_out, negative_caching_enabled, negative_caching_lifetime, no_dns_just_forward_to_parent, normalize_ae_gzip, origin_server_pipeline, parent_proxy_connect_attempts_timeout, parent_proxy_fail_threshold, parent_proxy_file, parent_proxy_per_parent_connection_attempts, parent_proxy_parent_proxy_retry_time, parent_proxy_parent_proxy_total_connection_attempts, parent_proxy_parent_proxy_routing_enable, post_connect_attempts_timeout, parent_push_method_enabled, referer_default_redirect, referer_filter, referer_format_redirect, response_server_enabled, send_http11_requests, share_server_sessions, slow_log_threshold, extract(epoch from transaction_active_timeout_in) as transaction_active_timeout_in, extract(epoch from transaction_active_timeout_out) as transaction_active_timeout_out, extract(epoch from transaction_no_activity_timeout_in) as transaction_no_activity_timeout_in, extract(epoch from transaction_no_activity_timeout_out) as transaction_no_activity_timeout_out, uncacheable_requests_bypass_parent, user_agent_pipeline from caching_proxy_record_data_http where profile=:profile`
	nstmt, err := db.PrepareNamed(queryStr)
	err = nstmt.Select(&ret, arg)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordHttp{}, err
	}
	nstmt.Close()

	if len(ret) != 1 {
		log.Printf("loadCachingProxyRecordHttp expecting 1 record, query returned %d", len(ret))
		return CachingProxyRecordHttp{}, err
	}

	recordHttp := ret[0]
	recordHttp.Cache, err = loadCachingProxyRecordHttpCache(profile, db)
	if err != nil {
		log.Println(err)
		return recordHttp, err
	}

	// Postgres epoch returns seconds. This multiplies it into nanoseconds, which are the correct internal representation of time.Duration
	recordHttp.TransactionActiveTimeoutIn *= time.Second
	recordHttp.TransactionActiveTimeoutOut *= time.Second
	recordHttp.TransactionNoActivityTimeoutIn *= time.Second
	recordHttp.TransactionNoActivityTimeoutOut *= time.Second
	return recordHttp, nil
}

func loadCachingProxyRecordLogData(profile string, logName string, db *sqlx.DB) (CachingProxyRecordLogData, error) {
	ret := []CachingProxyRecordLogData{}
	arg := CachingProxyRecordLogData{Profile: profile, Name: logName}
	queryStr := `select profile, name, enabled, header, is_ascii from caching_proxy_record_data_log_data where profile=:profile and name=:name`
	nstmt, err := db.PrepareNamed(queryStr)
	err = nstmt.Select(&ret, arg)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordLogData{}, err
	}
	nstmt.Close()

	if len(ret) != 1 {
		log.Printf("loadCachingProxyRecordLogData expecting 1 record, query returned %d", len(ret))
		return CachingProxyRecordLogData{}, err
	}

	logData := ret[0]
	return logData, nil
}

func loadCachingProxyRecordLog(profile string, db *sqlx.DB) (CachingProxyRecordLog, error) {
	ret := []CachingProxyRecordLog{}
	arg := CachingProxyRecordLog{Profile: profile}
	queryStr := `select profile, auto_delete_rolled_files, collation_host, collation_host_tagged, collation_port, extract(epoch from collation_retry) as collation_retry, collation_secret, custom_logs_enabled, hostname, logfile_dir, logfile_perm, logging_enabled, max_secs_per_buffer, max_space_mb_for_logs, max_space_mb_for_orphan_logs, max_space_mb_headroom, rolling_enabled, extract(epoch from rolling_interval) as rolling_interval, extract(epoch from rolling_offset) as rolling_offset, rolling_size_mb, sampling_frequency, separate_host_logs, separate_icp_logs, xml_config_file from caching_proxy_record_data_log where profile=:profile`
	nstmt, err := db.PrepareNamed(queryStr)
	err = nstmt.Select(&ret, arg)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordLog{}, err
	}
	nstmt.Close()

	if len(ret) != 1 {
		log.Printf("loadCachingProxyRecordLog expecting 1 record, query returned %d", len(ret))
		return CachingProxyRecordLog{}, err
	}

	recordLog := ret[0]
	// Postgres epoch returns seconds. This multiplies it into nanoseconds, which are the correct internal representation of time.Duration
	recordLog.CollationRetry *= time.Second
	recordLog.RollingInterval *= time.Second
	recordLog.RollingOffset *= time.Second

	recordLog.Squid, err = loadCachingProxyRecordLogData(profile, "squid", db)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordLog{}, err
	}

	recordLog.Common, err = loadCachingProxyRecordLogData(profile, "common", db)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordLog{}, err
	}

	recordLog.Extended2, err = loadCachingProxyRecordLogData(profile, "extended2", db)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordLog{}, err
	}

	recordLog.Extended, err = loadCachingProxyRecordLogData(profile, "extended", db)
	if err != nil {
		log.Println(err)
		return CachingProxyRecordLog{}, err
	}

	return recordLog, nil
}

func loadCachingProxyRecord(profile string, db *sqlx.DB) (CachingProxyRecord, error) {
	ret := []CachingProxyRecord{}
	arg := CachingProxyRecord{Profile: profile}
	queryStr := `select profile, accept_threads, admin_user, user_id, autoconf_port, number_config, alarm_abs_path, alarm_bin, alarm_email, allocator_debug_filter, allocator_enable_reclaim, allocator_huge_pages, allocator_max_overage, allocator_thread_freelist_size, body_factory_enable_customizations, body_factory_enable_logging, body_factory_response_suppression_mode, body_factory_template_sets_dir, enable_read_while_writer, cluster_configuration, cluster_cluster_port, cluster_ethernet_interface, cluster_log_bogus_mc_msgs, cluster_mc_group_addr, cluster_mc_ttl, cluster_mcport, cluster_rsport, config_dir, core_limit, diags_debug_enabled, diags_debug_tags, diags_show_location, dns_max_dns_in_flight, dns_nameservers, dns_resolv_conf, dns_round_robin_nameservers, dns_search_default_domains, dns_splitDNS_enabled, dns_url_expansions, dns_validate_query_name, dump_mem_info_frequency, env_prep, exec_thread_affinity, exec_thread_autoconfig, exec_thread_autoconfig_scale, exec_thread_limit, parse_no_host_url_redirect, icp_enabled, icp_interface, icp_port, icp_multicast_enabled, icp_query_timeout, mloc_enabled, net_connections_throttle, net_defer_accept, net_sock_recv_buffer_size_in, net_sock_recv_buffer_size_out, net_sock_send_buffer_size_in, net_sock_send_buffer_size_out, output_logfile, process_manager_management_port, proxy_binary_opts, proxy_name, reverse_proxy_enabled, snapshot_dir, stack_dump_enabled, syslog_facility, system_mmap_max, task_threads, temp_dir, update_concurrent_updates, update_enabled, update_force, update_retry_count, extract(epoch from update_retry_interval) as update_retry_interval,  url_remap_default_to_server_pac, url_remap_default_to_server_pac_port, url_remap_filename, url_remap_pristine_host_hdr, url_remap_remap_required, cron_ort_syncds_cdn, domain_name, health_connection_timeout, health_polling_url, health_threshold_available_bandwidth_kbps, health_threshold_load_average, health_threshold_query_time, history_count, cache_interim_storage, local_cluster_type, local_log_collation_mode, log_format_format, log_format_name, extract(epoch from max_reval_duration) as max_reval_duration, astats_path, qstring, astats_record_types, regex_revalidate, astats_library, traffic_server_chkconfig, crconfig_weight, parent_config_weight from caching_proxy_record_data where profile=:profile`
	nstmt, err := db.PrepareNamed(queryStr)
	err = nstmt.Select(&ret, arg)
	if err != nil {
		log.Println(err)
		return CachingProxyRecord{}, err
	}
	nstmt.Close()

	if len(ret) != 1 {
		log.Printf("loadCachingProxyRecord expecting 1 record, query returned %d", len(ret))
		return CachingProxyRecord{}, err
	}

	record := ret[0]

	// Postgres epoch returns seconds. This multiplies it into nanoseconds, which are the correct internal representation of time.Duration
	record.MaxRevalDuration *= time.Second
	record.UpdateRetryInterval *= time.Second

	record.Ssl, err = loadCachingProxyRecordSsl(profile, db)
	if err != nil {
		log.Println(err)
		return record, err
	}
	record.HostDb, err = loadCachingProxyRecordHostDb(profile, db)
	if err != nil {
		log.Println(err)
		return record, err
	}

	record.Cache, err = loadCachingProxyRecordCache(profile, db)
	if err != nil {
		log.Println(err)
		return record, err
	}

	record.Http, err = loadCachingProxyRecordHttp(profile, db)
	if err != nil {
		log.Println(err)
		return record, err
	}

	record.Log, err = loadCachingProxyRecordLog(profile, db)
	if err != nil {
		log.Println(err)
		return record, err
	}

	return record, nil
}

// @Title getCachingProxyConfig
// @Description retrieves the caching proxy configuration information for a certain profile
// @Accept  application/json
// @Param   profile              path    string     false        "The row id"
// @Success 200 {object}    CachingProxyRecord
// @Resource /api/2.0
// @Router /api/2.0/caching_proxy_record/{profile} [get]
func getCachingProxyConfig(profile string, db *sqlx.DB) (interface{}, error) {
	r, err := loadCachingProxyRecord(profile, db)
	return []CachingProxyRecord{r}, err
}
