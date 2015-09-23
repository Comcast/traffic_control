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

package com.comcast.cdn.traffic_control.traffic_router.core.util;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import org.apache.log4j.Logger;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;

import com.comcast.cdn.traffic_control.traffic_router.core.cache.Cache;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheLocation;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheRegister;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.InetRecord;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.Resolver;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.Geolocation;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.GeolocationException;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.NetworkNode;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.NetworkNodeException;
import com.comcast.cdn.traffic_control.traffic_router.core.router.TrafficRouter;
import com.comcast.cdn.traffic_control.traffic_router.core.router.TrafficRouterManager;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker;
import com.comcast.cdn.traffic_control.traffic_router.core.status.model.CacheModel;


public class DataExporter {
	private static final Logger LOGGER = Logger.getLogger(DataExporter.class);

	@Autowired
	private TrafficRouterManager trafficRouterManager;

	@Autowired
	private StatTracker statTracker;

	public void setTrafficRouterManager(final TrafficRouterManager trafficRouterManager) {
		this.trafficRouterManager = trafficRouterManager;
	}

	public void setStatTracker(final StatTracker statTracker) {
		this.statTracker = statTracker;
	}

	public StatTracker getStatTracker() {
		return this.statTracker;
	}

	public Map<String, String> getAppInfo() {
		final Map<String, String> globals = new HashMap<String, String>();
		System.getProperties().keys();

		final InputStream stream = getClass().getResourceAsStream("/version.prop");
		final Properties props = new Properties();

		try {
			props.load(stream);
			stream.close();
		} catch (IOException e) {
			LOGGER.warn(e,e);
		}

		for (final Object key : props.keySet()) {
			globals.put((String) key, props.getProperty((String) key));
		}

		return globals;
	}

	public Map<String, Object> getCachesByIp(final String ip) {
		LOGGER.warn("/ip/"+ip);

		final Map<String, Object> map = new HashMap<String, Object>();
		map.put("requestIp", ip);

		final CacheLocation cl = getLocationFromCzm(ip);

		if (cl != null) {
			map.put("locationByCoverageZone", cl.getProperties());
		} else {
			map.put("locationByCoverageZone", "not found");
		}

		try {
			final Geolocation gl = trafficRouterManager.getTrafficRouter().getLocation(ip);

			if (gl != null) {
				map.put("locationByGeo", gl.getProperties());
			} else {
				map.put("locationByGeo", "not found");
			}
		} catch (GeolocationException e) {
			LOGGER.warn(e,e);
			map.put("locationByGeo", e.toString());
		}

		return map;
	}

	@SuppressWarnings("PMD.LocalVariableCouldBeFinal")
	private CacheLocation getLocationFromCzm(final String ip) {
		NetworkNode nn = null;

		try {
			nn = NetworkNode.getInstance().getNetwork(ip);
		} catch (NetworkNodeException e) {
			LOGGER.warn(e);
		}

		if (nn == null) { return null; }

		final String locId = nn.getLoc();
		final CacheLocation cl = nn.getCacheLocation();

		if (cl != null) {
			return cl;
		}

		if (locId != null) {
			// find CacheLocation
			final TrafficRouter trafficRouter = trafficRouterManager.getTrafficRouter();
			final Collection<CacheLocation> caches = trafficRouter.getCacheRegister().getCacheLocations();

			for (CacheLocation cl2 : caches) {
				if (cl2.getId().equals(locId)) {
					return cl2;
				}
			}
		}

		return null;
	}

	public List<String> getLocations() {
		final List<String> models = new ArrayList<String>();
		final TrafficRouter trafficRouter = trafficRouterManager.getTrafficRouter();

		for (final CacheLocation location : trafficRouter.getCacheRegister().getCacheLocations()) {
			models.add(location.getId());
		}

		Collections.sort(models);
		return models;
	}

	public List<CacheModel> getCaches(final String locationId) {
		final TrafficRouter trafficRouter = trafficRouterManager.getTrafficRouter();
		final CacheLocation location = trafficRouter.getCacheRegister().getCacheLocation(locationId);
		return getCaches(location, trafficRouter.getZoneManager());
	}

	public Map<String, Object> getCaches() {
		final Map<String, Object> models = new HashMap<String, Object>();
		final TrafficRouter trafficRouter = trafficRouterManager.getTrafficRouter();

		for (final CacheLocation location : trafficRouter.getCacheRegister().getCacheLocations()) {
			models.put(location.getId(), getCaches(location.getId()));
		}

		return models;
	}

	private List<CacheModel> getCaches(final CacheLocation location, final Resolver resolver) {
		final List<CacheModel> models = new ArrayList<CacheModel>();

		for (final Cache cache : location.getCaches()) {
			final CacheModel model = new CacheModel();
			final List<String> ipAddresses = new ArrayList<String>();
			final List<InetRecord> ips = cache.getIpAddresses(null, resolver);

			if (ips != null) {
				for (final InetRecord address : ips) {
					ipAddresses.add(address.getAddress().getHostAddress());
				}
			}

			model.setCacheId(cache.getId());
			model.setFqdn(cache.getFqdn());
			model.setIpAddresses(ipAddresses);

			if (cache.hasAuthority()) {
				model.setCacheOnline(cache.isAvailable());
			} else {
				model.setCacheOnline(false);
			}

			models.add(model);
		}

		return models;
	}

	public int getCacheControlMaxAge() {
		int maxAge = 0;

		if (trafficRouterManager != null) {
			final TrafficRouter trafficRouter = trafficRouterManager.getTrafficRouter();

			if (trafficRouter != null) {
				final CacheRegister cacheRegister = trafficRouter.getCacheRegister();
				final JSONObject config = cacheRegister.getConfig();

				if (config != null) {
					maxAge = config.optInt("api.cache-control.max-age", 0);
				}
			}
		}

		return maxAge;
	}
}
