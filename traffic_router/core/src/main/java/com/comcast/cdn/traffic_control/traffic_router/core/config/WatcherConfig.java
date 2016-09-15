/*
 * Copyright 2015 Comcast Cable Communications Management, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.comcast.cdn.traffic_control.traffic_router.core.config;

import com.comcast.cdn.traffic_control.traffic_router.core.util.TrafficOpsUtils;
import org.json.JSONObject;

public class WatcherConfig {
	private final String url;
	private final long interval;
	// this is an int instead of a long because of protected resource fetcher
	private final int timeout;

	public WatcherConfig(final String prefix, final JSONObject config, final TrafficOpsUtils trafficOpsUtils) {
		url = trafficOpsUtils.getUrl(prefix + ".polling.url", "");
		interval = config.optLong(prefix + ".polling.interval", -1L);
		timeout = config.optInt(prefix + ".polling.timeout", -1);
	}

	public long getInterval() {
		return interval;
	}

	public String getUrl() {
		return url;
	}

	public int getTimeout() {
		return timeout;
	}
}
