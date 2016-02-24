/** @file

  A brief file description

  @section license License

  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 */


#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <limits.h>
#include <ts/ts.h>
#include <string.h>
#include <stdbool.h>
#include <sys/stat.h>
#include <time.h>

#include <inttypes.h>
#include <sys/types.h>
#include <dirent.h>

#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

typedef struct {
	unsigned int recordTypes;
	char *stats_path;
	int stats_path_len;
	char *allowIps;
	int ipCount;
	char *allowIps6;
	int ip6Count;
} config_t;
typedef struct {
	char *config_path;
	volatile time_t last_load;
	config_t* config;
} config_holder_t;
#define FREE_TMOUT        300000
static int free_handler(TSCont cont, TSEvent event, void *edata);
static int config_handler(TSCont cont, TSEvent event, void *edata);
static config_t* get_config(TSCont cont);
static config_holder_t* new_config_holder(const char* path);

#define STR_BUFFER_SIZE 	1024

#define SYSTEM_RECORD_TYPE 		(0x100)
#define DEFAULT_RECORD_TYPES	(SYSTEM_RECORD_TYPE | TS_RECORDTYPE_PROCESS | TS_RECORDTYPE_PLUGIN)

typedef struct stats_state_t {
	TSVConn net_vc;
	TSVIO read_vio;
	TSVIO write_vio;

	TSIOBuffer req_buffer;
	TSIOBuffer resp_buffer;
	TSIOBufferReader resp_reader;

	int output_bytes;
	int body_written;

	int globals_cnt;
	char **globals;
	char *interfaceName;
	char *query;
	unsigned int recordTypes;
} stats_state;

int configReloadRequests = 0;
int configReloads = 0;
time_t lastReloadRequest = 0;
time_t lastReload = 0;
time_t astatsLoad = 0;

#define PLUGIN_TAG              "astats_over_http"
#define DEFAULT_CONFIG_NAME     "astats.config"
#define DEFAULT_IP              "127.0.0.1"
#define DEFAULT_IP6             "::1"

static bool is_ip_allowed(const config_t* config, const struct sockaddr* addr);

static char * nstr(const char *s) {
	char *mys = (char *)TSmalloc(strlen(s)+1);
	strcpy(mys, s);
	return mys;
}

static char * nstrl(const char *s, int len) {
	char *mys = (char *)TSmalloc(len + 1);
	memcpy(mys, s, len);
	mys[len] = 0;
	return mys;
}

static char ** parseGlobals(char *str, int *globals_cnt) {
	char *tok = 0;
	char **globals = 0;
	char **old = 0;
	int globals_size = 0, cnt = 0, i;

	while (1) {
		tok = strtok_r(str, ";", &str);
		if (!tok)
			break;
		if (cnt >= globals_size) {
			old = globals;
			globals = (char **) TSmalloc(sizeof(char *) * (globals_size + 20));
			if (old) {
				memcpy(globals, old, sizeof(char *) * (globals_size));
				TSfree(old);
				old = NULL;
			}
			globals_size += 20;
		}
		globals[cnt] = tok;
		cnt++;
	}
	*globals_cnt = cnt;

	for (i = 0; i < cnt; i++)
		TSDebug(PLUGIN_TAG, "globals[%d]: '%s'", i, globals[i]);

	return globals;
}

static void stats_fillState(stats_state *my_state, char *query, int query_len) {
	char* arg = 0;

	while (1) {
		arg = strtok_r(query, "&", &query);
		if (!arg)
			break;
		if (strstr(arg, "application=")) {
			arg = arg + strlen("application=");
			my_state->globals = parseGlobals(arg, &my_state->globals_cnt);
		} else if (strstr(arg, "inf.name=")) {
			my_state->interfaceName = arg + strlen("inf.name=");
		} else if(strstr(arg, "record.types=")) {
			my_state->recordTypes = strtol(arg + strlen("record.types="), NULL, 16);
		}
	}
}

static void stats_cleanup(TSCont contp, stats_state *my_state) {
	if (my_state->req_buffer) {
		TSIOBufferDestroy(my_state->req_buffer);
		my_state->req_buffer = NULL;
	}

	if (my_state->resp_buffer) {
		TSIOBufferDestroy(my_state->resp_buffer);
		my_state->resp_buffer = NULL;
	}

	TSVConnClose(my_state->net_vc);
	TSfree(my_state);
	my_state = NULL;
	TSContDestroy(contp);
}

static void
stats_process_accept(TSCont contp, stats_state *my_state) {
	my_state->req_buffer = TSIOBufferCreate();
	my_state->resp_buffer = TSIOBufferCreate();
	my_state->resp_reader = TSIOBufferReaderAlloc(my_state->resp_buffer);
	my_state->read_vio = TSVConnRead(my_state->net_vc, contp, my_state->req_buffer, INT64_MAX);
}

static int
stats_add_data_to_resp_buffer(const char *s, stats_state *my_state) {
	int s_len = strlen(s);

	TSIOBufferWrite(my_state->resp_buffer, s, s_len);

	return s_len;
}

static const char RESP_HEADER[] = "HTTP/1.0 200 Ok\r\nContent-Type: text/javascript\r\nCache-Control: no-cache\r\n\r\n";

static void
stats_process_read(TSCont contp, TSEvent event, stats_state *my_state) {
	TSDebug(PLUGIN_TAG, "stats_process_read(%d)", event);

	if (event == TS_EVENT_VCONN_READ_READY) {
		my_state->output_bytes = stats_add_data_to_resp_buffer(RESP_HEADER, my_state);
		TSVConnShutdown(my_state->net_vc, 1, 0);
		my_state->write_vio = TSVConnWrite(my_state->net_vc, contp, my_state->resp_reader, INT64_MAX);
	}
	else if (event == TS_EVENT_ERROR)
		TSError("stats_process_read: Received TS_EVENT_ERROR\n");
	else if (event == TS_EVENT_VCONN_EOS)
		/* client may end the connection, simply return */
		return;
	else if (event == TS_EVENT_NET_ACCEPT_FAILED)
		TSError("stats_process_read: Received TS_EVENT_NET_ACCEPT_FAILED\n");
	else {
		printf("Unexpected Event %d\n", event);
		TSReleaseAssert(!"Unexpected Event");
	}
}

#define APPEND(a) my_state->output_bytes += stats_add_data_to_resp_buffer(a, my_state)
#define APPEND_STAT(a, fmt, v) do { \
		char b[3048]; \
		if (snprintf(b, sizeof(b), "   \"%s\": " fmt ",\n", a, v) < sizeof(b)) \
		APPEND(b); \
} while(0)

static void
json_out_stat(TSRecordType rec_type, void *edata, int registered, const char *name, TSRecordDataType data_type, TSRecordData *datum) {
	stats_state *my_state = edata;
	int found = 0;
	int i;

	if (my_state->globals_cnt) {
		for (i = 0; i < my_state->globals_cnt; i++) {
			if (strstr(name, my_state->globals[i])) {
				found = 1;
				break;
			}
		}

		if (!found)
			return; // skip
	}

	switch(data_type) {
	case TS_RECORDDATATYPE_COUNTER:
		APPEND_STAT(name, "%" PRIu64, datum->rec_counter); break;
	case TS_RECORDDATATYPE_INT:
		APPEND_STAT(name, "%" PRIu64, datum->rec_int); break;
	case TS_RECORDDATATYPE_FLOAT:
		APPEND_STAT(name, "%f", datum->rec_float); break;
	case TS_RECORDDATATYPE_STRING:
		APPEND_STAT(name, "\"%s\"", datum->rec_string); break;
	default:
		TSDebug(PLUGIN_TAG, "unkown type for %s: %d", name, data_type);
		break;
	}
}

static char * getFile(char *filename, char *buffer, int bufferSize) {
	TSFile f= 0;
	size_t s = 0;

	f = TSfopen(filename, "r");
	if (!f)
	{
		buffer[0] = 0;
		return buffer;
	}

	s = TSfread(f, buffer, bufferSize);
	if (s > 0)
		buffer[s] = 0;
	else
		buffer[0] = 0;

	TSfclose(f);

	return buffer;
}

static int getSpeedForIF(char *inf, char *buffer, int bufferSize) {
	char* str;
	char b[256];
	int speed = 0;

	snprintf(b, sizeof(b), "/sys/class/net/%s/operstate", inf);
	str = getFile(b, buffer, bufferSize);
	if (str && strstr(str, "up"))
	{
		snprintf(b, sizeof(b), "/sys/class/net/%s/speed", inf);
		str = getFile(b, buffer, bufferSize);
		speed = strtol(str, 0, 10);
	}

	return speed;
}

static int getSpeed(char *interface, char *buffer, int bufferSize) {
	//  List<String> interfaces = new ArrayList<String>();
	//  String str = getFile("/sys/class/net/bonding_masters");
	//  if(str !=null && str.contains(myInterface)) {
	//          String base = "/sys/class/net/"+myInterface+"/";
	//          File directory = new File(base);
	//          String[] children = directory.list();
	//          for(String child : children) {
	//                  if(child.contains("slave_")) {
	//                          child = child.replace("slave_", "");
	//                          interfaces.add(child);
	//                  }
	//          }
	//  } else {
	//          interfaces.add(myInterface);
	//  }

	//  for(String ifName : interfaces) {
	//          str = getFile("/sys/class/net/" +ifName+ "/operstate");
	//          if(str.contains("up")) {
	//                  str = getFile("/sys/class/net/" +ifName+ "/speed");
	//                  result.speed += Long.parseLong(str.trim());
	//          }
	//  }
	DIR *dp;
	struct dirent *ep;
	char *str;
	char *inf;
	char b[256];
	int speed = 0;

	if (!interface)
		return 0;

	str = getFile("/sys/class/net/bonding_masters", buffer, bufferSize);
	if (str) {
		str = strstr(str, interface);
		if (!str)
			return getSpeedForIF(interface, buffer, bufferSize);
	}

	snprintf(b, sizeof(b), "/sys/class/net/%s/", interface);
	dp = opendir (b);

	if (dp != NULL) {
		while ((ep = readdir (dp))) {
			str = strstr(ep->d_name, "slave_");
			if (str) {
				inf = str + strlen("slave_");
				speed += getSpeedForIF (inf, buffer, bufferSize);
			}
		}

		(void) closedir(dp);
	}

	return speed;
}

static void appendSystemState(stats_state *my_state) {
	char *interface = my_state->interfaceName;
	char buffer[2024];
	int bsize = 2024;
	char *str;
	char *end;
	int speed = 0;

	APPEND_STAT("inf.name", "\"%s\"", interface);

	speed = getSpeed(interface, buffer, bsize);

	APPEND_STAT("inf.speed", "%d", speed);

	str = getFile("/proc/net/dev", buffer, bsize);
	if (str && interface) {
		str = strstr(str, interface);
		if (str) {
			end = strstr(str, "\n");
			if (end)
				*end = 0;
			APPEND_STAT("proc.net.dev", "\"%s\"", str);
		}
	}

	str = getFile("/proc/loadavg", buffer, bsize);
	if (str) {
		end = strstr(str, "\n");
		if (end)
			*end = 0;
		APPEND_STAT("proc.loadavg", "\"%s\"", str);
	}
}

static void json_out_stats(stats_state *my_state) {
	const char *version;
	TSDebug(PLUGIN_TAG, "recordTypes: '0x%x'", my_state->recordTypes);
	APPEND("{ \"ats\": {\n");
        TSRecordDump(my_state->recordTypes, json_out_stat, my_state);
	version = TSTrafficServerVersionGet();
	APPEND("   \"server\": \"");
	APPEND(version);
	APPEND("\"\n");
	APPEND("  }");

	if (my_state->recordTypes & SYSTEM_RECORD_TYPE) {
		APPEND(",\n \"system\": {\n");
		appendSystemState(my_state);
		APPEND_STAT("configReloadRequests", "%d", configReloadRequests);
		APPEND_STAT("lastReloadRequest", "%" PRIu64, lastReloadRequest);
		APPEND_STAT("configReloads", "%d", configReloads);
		APPEND_STAT("lastReload", "%" PRIu64, lastReload);
		APPEND_STAT("astatsLoad", "%" PRIu64, astatsLoad);
		APPEND("\"something\": \"here\"");
		APPEND("\n  }");
	}

	APPEND("\n}\n");
}

static void stats_process_write(TSCont contp, TSEvent event, stats_state *my_state) {
	if (event == TS_EVENT_VCONN_WRITE_READY) {
		if (my_state->body_written == 0) {
			TSDebug(PLUGIN_TAG, "plugin adding response body");
			my_state->body_written = 1;
			json_out_stats(my_state);
			TSVIONBytesSet(my_state->write_vio, my_state->output_bytes);
		}
		TSVIOReenable(my_state->write_vio);
		TSfree(my_state->globals);
		my_state->globals = NULL;
		TSfree(my_state->query);
		my_state->query = NULL;
	} else if (TS_EVENT_VCONN_WRITE_COMPLETE)
		stats_cleanup(contp, my_state);
	else if (event == TS_EVENT_ERROR)
		TSError("stats_process_write: Received TS_EVENT_ERROR\n");
	else
		TSReleaseAssert(!"Unexpected Event");
}

static int stats_dostuff(TSCont contp, TSEvent event, void *edata) {
	stats_state *my_state = TSContDataGet(contp);
	if (event == TS_EVENT_NET_ACCEPT) {
		my_state->net_vc = (TSVConn) edata;
		stats_process_accept(contp, my_state);
	} else if (edata == my_state->read_vio)
		stats_process_read(contp, event, my_state);
	else if (edata == my_state->write_vio)
		stats_process_write(contp, event, my_state);
	else
		TSReleaseAssert(!"Unexpected Event");

	return 0;
}

static int astats_origin(TSCont cont, TSEvent event, void *edata) {
	TSCont icontp;
	stats_state *my_state;
	config_t* config;
	TSHttpTxn txnp = (TSHttpTxn) edata;
	TSMBuffer reqp;
	TSMLoc hdr_loc = NULL, url_loc = NULL;
	TSEvent reenable = TS_EVENT_HTTP_CONTINUE;
	config = get_config(cont);

	TSDebug(PLUGIN_TAG, "in the read stuff");

	if (TSHttpTxnClientReqGet(txnp, &reqp, &hdr_loc) != TS_SUCCESS)
		goto cleanup;

	if (TSHttpHdrUrlGet(reqp, hdr_loc, &url_loc) != TS_SUCCESS)
		goto cleanup;

	int path_len = 0;
	const char* path = TSUrlPathGet(reqp,url_loc,&path_len);
	TSDebug(PLUGIN_TAG,"Path: %.*s",path_len,path);
	TSDebug(PLUGIN_TAG,"Path: %.*s",path_len,path);

	if (!(path_len == config->stats_path_len && !memcmp(path, config->stats_path, config->stats_path_len))) {
//		TSDebug(PLUGIN_TAG, "not right path: %.*s",path_len,path);
		goto notforme;
	}

	const struct sockaddr *addr = TSHttpTxnClientAddrGet(txnp);
	if(!is_ip_allowed(config, addr)) {
		TSDebug(PLUGIN_TAG, "not right ip");
		goto notforme;
	}
//	TSDebug(PLUGIN_TAG,"Path...: %.*s",path_len,path);

	int query_len;
	char *query = (char*)TSUrlHttpQueryGet(reqp,url_loc,&query_len);
	TSDebug(PLUGIN_TAG,"query: %.*s",query_len,query);

	TSSkipRemappingSet(txnp,1); //not strictly necessary, but speed is everything these days

	/* This is us -- register our intercept */
	TSDebug(PLUGIN_TAG, "Intercepting request");

	icontp = TSContCreate(stats_dostuff, TSMutexCreate());
	my_state = (stats_state *) TSmalloc(sizeof(*my_state));
	memset(my_state, 0, sizeof(*my_state));

	my_state->recordTypes = config->recordTypes;
	if (query_len) {
		my_state->query = nstrl(query, query_len);
		TSDebug(PLUGIN_TAG,"new query: %s", my_state->query);
		stats_fillState(my_state, my_state->query, query_len);
	}

	TSContDataSet(icontp, my_state);
	TSHttpTxnIntercept(icontp, txnp);

	goto cleanup;

	notforme:

	cleanup:
#if (TS_VERSION_NUMBER < 2001005)
	if (path)
		TSHandleStringRelease(reqp, url_loc, path);
#endif
	if (url_loc)
		TSHandleMLocRelease(reqp, hdr_loc, url_loc);
	if (hdr_loc)
		TSHandleMLocRelease(reqp, TS_NULL_MLOC, hdr_loc);

	TSHttpTxnReenable(txnp, reenable);

	return 0;
}

void TSPluginInit(int argc, const char *argv[]) {
	TSPluginRegistrationInfo info;
	TSCont main_cont, config_cont;
	config_holder_t *config_holder;

	info.plugin_name = PLUGIN_TAG;
	info.vendor_name = "Comcast";
	info.support_email = "justin@fp-x.com";
	astatsLoad = time(NULL);

	if (TSPluginRegister(&info) != TS_SUCCESS) {
        TSError("Plugin registration failed. \n");
	}

	config_holder = new_config_holder(argc > 1 ? argv[1] : NULL);

	main_cont = TSContCreate(astats_origin, NULL);
	TSContDataSet(main_cont, (void *) config_holder);
	TSHttpHookAdd(TS_HTTP_READ_REQUEST_HDR_HOOK, main_cont);

	config_cont = TSContCreate(config_handler, TSMutexCreate());
	TSContDataSet(config_cont, (void *) config_holder);
	TSMgmtUpdateRegister(config_cont, PLUGIN_TAG);
	/* Create a continuation with a mutex as there is a shared global structure
       containing the headers to add */
	TSDebug(PLUGIN_TAG, "astats module registered, path: '%s'", config_holder->config->stats_path);
}

static bool is_ip_match(const char *ip, char *ipmask, char mask) {
	int j, i,k;
	char cm;
	for(j=0, i=0; ((i+1)*8) <= mask; i++) {
		if(ip[i] != ipmask[i]) {
			return false;
		}
		j+=8;
	}
	cm = 0;
	for(k=0; j<mask;j++,k++) {
		cm |= 1<<(7-k);
	}
	if((ip[i]&cm) != (ipmask[i]&cm)) {
		return false;
	}
	return true;
}

static bool is_ip_allowed(const config_t* config, const struct sockaddr* addr) {
	char ip_port_text_buffer[INET6_ADDRSTRLEN];
	int i;
	char *ipmask;
	if(!addr) {
		return true;
	}
	const char *ip = addr->sa_data+2;

	if (addr->sa_family == AF_INET && config->allowIps) {
		for(i=0; i < config->ipCount; i++) {
			ipmask = config->allowIps+ (i*5);
			if(is_ip_match(ip, ipmask, ipmask[4])) {
				TSDebug(PLUGIN_TAG, "clientip is %s--> ALLOW", inet_ntop(AF_INET,ip,ip_port_text_buffer,INET6_ADDRSTRLEN));
				return true;
			}
		}
		TSDebug(PLUGIN_TAG, "clientip is %s--> DENY", inet_ntop(AF_INET,ip,ip_port_text_buffer,INET6_ADDRSTRLEN));
		return false;
	} else if (addr->sa_family == AF_INET6 && config->allowIps6) {
		for(i=0; i < config->ip6Count; i++) {
			ipmask = config->allowIps6+ (i*9);
			if(is_ip_match(ip, ipmask, ipmask[8])) {
				TSDebug(PLUGIN_TAG, "clientip6 is %s--> ALLOW", inet_ntop( AF_INET6,ip,ip_port_text_buffer,INET6_ADDRSTRLEN));
				return true;
			}
		}
		TSDebug(PLUGIN_TAG, "clientip6 is %s--> DENY", inet_ntop( AF_INET6,ip,ip_port_text_buffer,INET6_ADDRSTRLEN));
		return false;
	}
	return true;
}

static void parseIps(config_t* config, char* ipStr) {
	char buffer[STR_BUFFER_SIZE];
	char *p, *tok1, *tok2, *ip;
	int i, mask;
	char ip_port_text_buffer[INET_ADDRSTRLEN];

	if(!ipStr) {
	    config->ipCount = 1;
	    ip = config->allowIps = TSmalloc(5);
            inet_pton(AF_INET, DEFAULT_IP, ip);
            ip[4] = 32;
	    return;
	}

	strcpy(buffer, ipStr);
	p = buffer;
	while(strtok_r(p, ", \n", &p)) {
		config->ipCount++;
	}
	if(!config->ipCount) {
		return;
	}
	config->allowIps = TSmalloc(5*config->ipCount); // 4 bytes for ip + 1 for bit mask
	strcpy(buffer, ipStr);
	p = buffer;
	i = 0;
	while((tok1 = strtok_r(p, ", \n", &p))) {
		TSDebug(PLUGIN_TAG, "%d) parsing: %s", i+1,tok1);
		tok2 = strtok_r(tok1, "/", &tok1);
		ip = config->allowIps+(5*i);
		if(!inet_pton(AF_INET, tok2, ip)) {
			TSDebug(PLUGIN_TAG, "%d) skipping: %s", i+1,tok1);
			continue;
		}
		tok2 = strtok_r(tok1, "/", &tok1);
		if(!tok2) {
			mask = 32;
		} else {
			mask = atoi(tok2);
		}
		ip[4] = mask;
		TSDebug(PLUGIN_TAG, "%d) adding netmask: %s/%d", i+1,
				inet_ntop(AF_INET,ip,ip_port_text_buffer,INET_ADDRSTRLEN),ip[4]);
		i++;
	}
}
static void parseIps6(config_t* config, char* ipStr) {
	char buffer[STR_BUFFER_SIZE];
	char *p, *tok1, *tok2, *ip;
	int i, mask;
	char ip_port_text_buffer[INET6_ADDRSTRLEN];

        if(!ipStr) {
            config->ip6Count = 1;
            ip = config->allowIps6 = TSmalloc(5);
            inet_pton(AF_INET, DEFAULT_IP6, ip);
            ip[8] = 64;
            return;
        }

        strcpy(buffer, ipStr);
	p = buffer;
	while(strtok_r(p, ", \n", &p)) {
		config->ip6Count++;
	}
	if(!config->ip6Count) {
		return;
	}
	config->allowIps6 = TSmalloc(9*config->ip6Count); // 4 bytes for ip + 1 for bit mask
	strcpy(buffer, ipStr);
	p = buffer;
	i = 0;
	while((tok1 = strtok_r(p, ", \n", &p))) {
		TSDebug(PLUGIN_TAG, "%d) parsing: %s", i+1,tok1);
		tok2 = strtok_r(tok1, "/", &tok1);
		ip = config->allowIps6+(9*i);
		if(!inet_pton(AF_INET, tok2, ip)) {
			TSDebug(PLUGIN_TAG, "%d) skipping: %s", i+1,tok1);
			continue;
		}
		tok2 = strtok_r(tok1, "/", &tok1);
		if(!tok2) {
			mask = 64;
		} else {
			mask = atoi(tok2);
		}
		ip[8] = mask;
		TSDebug(PLUGIN_TAG, "%d) adding netmask: %s/%d", i+1,
				inet_ntop(AF_INET6,ip,ip_port_text_buffer,INET6_ADDRSTRLEN),ip[8]);
		i++;
	}
}
static config_t* new_config(TSFile fh) {
	char buffer[STR_BUFFER_SIZE];
	config_t* config = NULL;
        config = (config_t*)TSmalloc(sizeof(config_t));
        config->stats_path = 0;
        config->stats_path_len = 0;
        config->allowIps = 0;
        config->ipCount = 0;
        config->allowIps6 = 0;
        config->ip6Count = 0;
        config->recordTypes = DEFAULT_RECORD_TYPES;
	//	TSmalloc(6);

	if(!fh) {
		config->stats_path = nstr("_astats");
		config->stats_path_len = strlen(config->stats_path);

		TSDebug(PLUGIN_TAG, "No config, using defaults");
		return config;
	}

	while (TSfgets(fh, buffer, STR_BUFFER_SIZE - 1)) {
		if (*buffer == '#') {
			continue; /* # Comments, only at line beginning */
		}
		char* p = 0;
		if((p = strstr(buffer, "path="))) {
			p+=strlen("path=");
			config->stats_path = nstr(strtok_r(p, " \n", &p));
			config->stats_path_len = strlen(config->stats_path);
		} else if((p = strstr(buffer, "record_types="))) {
			p+=strlen("record_types=");
			config->recordTypes = strtol(strtok_r(p, " \n", &p), NULL, 16);
		} else if((p = strstr(buffer, "allow_ip="))) {
			p+=strlen("allow_ip=");
			parseIps(config, p);
		} else if((p = strstr(buffer, "allow_ip6="))) {
			p+=strlen("allow_ip6=");
			parseIps6(config, p);
		}
	}
	if(!config->ipCount) {
            parseIps(config, NULL);
	}
	if(config->ip6Count) {
            parseIps6(config, NULL);
	}
	TSDebug(PLUGIN_TAG, "config path=%s", config->stats_path);

	return config;
}
static void delete_config(config_t* config) {
	TSDebug(PLUGIN_TAG, "Freeing config");
	TSfree(config->allowIps);
	TSfree(config->allowIps6);
	TSfree(config->stats_path);
	TSfree(config);
}


// standard api below...


static config_t* get_config(TSCont cont) {
	config_holder_t* configh = (config_holder_t *) TSContDataGet(cont);
	if(!configh) {
		return 0;
	}
	return configh->config;
}
static void load_config_file(config_holder_t *config_holder) {
	TSFile fh;
	struct stat s;

	config_t *newconfig, *oldconfig;
	TSCont free_cont;

	configReloadRequests++;
	lastReloadRequest = time(NULL);

	// check date
	if (stat(config_holder->config_path, &s) < 0) {
		TSDebug(PLUGIN_TAG, "Could not stat %s", config_holder->config_path);
		if(config_holder->config) {
			return;
		}
	} else {
		TSDebug(PLUGIN_TAG, "s.st_mtime=%lu, last_load=%lu", s.st_mtime, config_holder->last_load);
		if (s.st_mtime < config_holder->last_load) {
			return;
		}
	}

	TSDebug(PLUGIN_TAG, "Opening config file: %s", config_holder->config_path);
	fh = TSfopen(config_holder->config_path, "r");

	if (!fh) {
		TSError("[%s] Unable to open config: %s.\n",
				PLUGIN_TAG, config_holder->config_path);
		if(config_holder->config) {
			return;
		}
	}

	newconfig = 0;
	newconfig = new_config(fh);
	if(newconfig) {
		configReloads++;
		lastReload = lastReloadRequest;
		config_holder->last_load = lastReloadRequest;
		config_t ** confp = &(config_holder->config);
		oldconfig = __sync_lock_test_and_set(confp, newconfig);
		if (oldconfig) {
			TSDebug(PLUGIN_TAG, "scheduling free: %p (%p)", oldconfig, newconfig);
			free_cont = TSContCreate(free_handler, NULL);
			TSContDataSet(free_cont, (void *) oldconfig);
			TSContSchedule(free_cont, FREE_TMOUT, TS_THREAD_POOL_TASK);
		}
	}
	if(fh)
		TSfclose(fh);
	return;
}
static config_holder_t* new_config_holder(const char* path) {
	char default_config_file[1024];
	config_holder_t* config_holder = TSmalloc(sizeof(config_holder_t));
	config_holder->config_path = 0;
	config_holder->config = 0;
	config_holder->last_load = 0;
	//	TSmalloc(32);
	//
	if(path) {
		config_holder->config_path = nstr(path);
	} else {
		/* Default config file of plugins/cacheurl.config */
		//		sprintf(default_config_file, "%s/astats.config", TSPluginDirGet());
		sprintf(default_config_file, "%s/"DEFAULT_CONFIG_NAME, TSConfigDirGet());
		config_holder->config_path = nstr(default_config_file);
	}
	load_config_file(config_holder);
	return config_holder;
}

static int free_handler(TSCont cont, TSEvent event, void *edata) {
	config_t *config;

	TSDebug(PLUGIN_TAG, "Freeing old config");
	config = (config_t *) TSContDataGet(cont);
	delete_config(config);
	TSContDestroy(cont);
	return 0;
}
static int config_handler(TSCont cont, TSEvent event, void *edata) {
	config_holder_t *config_holder;

	TSDebug(PLUGIN_TAG, "In config Handler");
	config_holder = (config_holder_t *) TSContDataGet(cont);
	load_config_file(config_holder);
	return 0;
}

