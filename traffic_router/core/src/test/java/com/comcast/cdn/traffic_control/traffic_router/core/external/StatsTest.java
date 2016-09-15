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

package com.comcast.cdn.traffic_control.traffic_router.core.external;

import com.comcast.cdn.traffic_control.traffic_router.core.util.ExternalTest;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.catalina.LifecycleException;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.util.EntityUtils;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.experimental.categories.Category;

import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.hasItems;
import static org.hamcrest.core.IsEqual.equalTo;

@Category(ExternalTest.class)
public class StatsTest {
	CloseableHttpClient httpClient;

	@Before
	public void before() throws LifecycleException {
		httpClient = HttpClientBuilder.create().build();
	}
	
	@After
	public void after() throws Exception {
		if (httpClient != null) httpClient.close();
	}
	
	@Test
	public void itGetsApplicationStats() throws Exception {
		HttpGet httpGet = new HttpGet("http://localhost:3333/crs/stats");

		CloseableHttpResponse httpResponse = null;
		
		try {
			
			httpResponse = httpClient.execute(httpGet);
			String responseContent = EntityUtils.toString(httpResponse.getEntity());

			ObjectMapper objectMapper = new ObjectMapper();

			Map<String, Object> data = objectMapper.readValue(responseContent, new TypeReference<HashMap<String, Object>>() { });

			assertThat(data.keySet(), containsInAnyOrder("app", "stats"));

			Map<String, Object> appData = (Map<String, Object>) data.get("app");
			assertThat(appData.keySet(), containsInAnyOrder("buildTimestamp", "name", "deploy-dir", "git-revision", "version"));

			Map<String, Object> statsData = (Map<String, Object>) data.get("stats");
			assertThat(statsData.keySet(), containsInAnyOrder("dnsMap", "httpMap", "totalDnsCount", "totalHttpCount", "totalDsMissCount", "appStartTime", "averageDnsTime", "averageHttpTime", "updateTracker"));


			Map<String, Object> dnsStats = (Map<String, Object>) statsData.get("dnsMap");
			Map<String, Object> cacheDnsStats = (Map<String, Object>) dnsStats.values().iterator().next();
			assertThat(cacheDnsStats.keySet(), containsInAnyOrder("czCount", "geoCount", "missCount", "dsrCount", "errCount",
				"staticRouteCount", "fedCount", "regionalDeniedCount", "regionalAlternateCount"));

			Map<String, Object> httpStats = (Map<String, Object>) statsData.get("httpMap");
			Map<String, Object> cacheHttpStats = (Map<String, Object>) httpStats.values().iterator().next();
			assertThat(cacheHttpStats.keySet(), containsInAnyOrder("czCount", "geoCount", "missCount", "dsrCount", "errCount",
				"staticRouteCount", "fedCount", "regionalDeniedCount", "regionalAlternateCount"));

			Map<String, Object> updateTracker = (Map<String, Object>) statsData.get("updateTracker");
			assertThat(updateTracker.keySet(), hasItems("lastCacheStateCheck", "lastCacheStateChange", "lastConfigCheck", "lastConfigChange"));

		} finally {
			if (httpResponse != null) httpResponse.close();
		}
	}

	@Test
	public void itGetsLocationsByIp() throws Exception {
		HttpGet httpGet = new HttpGet("http://localhost:3333/crs/stats/ip/8.8.8.8");

		CloseableHttpResponse response = null;
		
		try {
			response = httpClient.execute(httpGet);
			String actual = EntityUtils.toString(response.getEntity());

			Map<String, Object> data = new ObjectMapper().readValue(actual, new TypeReference<HashMap<String, Object>>() { });

			assertThat(data.get("requestIp"), equalTo("8.8.8.8"));
			assertThat(data.get("locationByFederation"), equalTo("not found"));
			assertThat(data.get("locationByCoverageZone"), equalTo("not found"));

			Map<String, Object> locationByGeo = (Map<String, Object>) data.get("locationByGeo");
			assertThat(locationByGeo.keySet(), containsInAnyOrder("city", "countryCode", "latitude", "longitude", "postalCode", "countryName"));
		} finally {
			if (response != null) response.close();
		}
	}
}
