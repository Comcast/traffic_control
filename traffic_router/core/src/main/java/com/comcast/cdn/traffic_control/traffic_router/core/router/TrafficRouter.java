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

package com.comcast.cdn.traffic_control.traffic_router.core.router;

import java.io.IOException;
import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.SortedMap;
import java.util.TreeMap;

import org.apache.commons.pool.ObjectPool;
import org.apache.log4j.Logger;
import org.json.JSONObject;
import org.xbill.DNS.Name;
import org.xbill.DNS.Zone;

import com.comcast.cdn.traffic_control.traffic_router.core.cache.Cache;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheLocation;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheRegister;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.InetRecord;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.Cache.DeliveryServiceReference;
import com.comcast.cdn.traffic_control.traffic_router.core.dns.ZoneManager;
import com.comcast.cdn.traffic_control.traffic_router.core.ds.DeliveryService;
import com.comcast.cdn.traffic_control.traffic_router.core.ds.Dispersion;
import com.comcast.cdn.traffic_control.traffic_router.core.hash.HashFunction;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.Geolocation;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.GeolocationException;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.GeolocationService;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.NetworkNode;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.NetworkNodeException;
import com.comcast.cdn.traffic_control.traffic_router.core.request.DNSRequest;
import com.comcast.cdn.traffic_control.traffic_router.core.request.HTTPRequest;
import com.comcast.cdn.traffic_control.traffic_router.core.request.Request;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.ResultType;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.RouteType;

public class TrafficRouter {
	public static final Logger LOGGER = Logger.getLogger(TrafficRouter.class);

	private final CacheRegister cacheRegister;
	private final ZoneManager zoneManager;
	private final GeolocationService geolocationService;
	private final GeolocationService geolocationService6;
	private final ObjectPool hashFunctionPool;

	private final Random random = new Random(System.nanoTime());

	public TrafficRouter(final CacheRegister cr, 
			final GeolocationService geolocationService, 
			final GeolocationService geolocationService6, 
			final ObjectPool hashFunctionPool,
			final StatTracker statTracker,
			final String dnsRoutingName,
			final String httpRoutingName) throws IOException {
		this.cacheRegister = cr;
		this.geolocationService = geolocationService;
		this.geolocationService6 = geolocationService6;
		this.hashFunctionPool = hashFunctionPool;
		this.zoneManager = new ZoneManager(this, statTracker, dnsRoutingName, httpRoutingName);
	}

	public ZoneManager getZoneManager() {
		return zoneManager;
	}

	/**
	 * Returns a {@link List} of all of the online {@link Cache}s that support the specified
	 * {@link DeliveryService}. If no online caches are found to support the specified
	 * DeliveryService an empty list is returned.
	 * 
	 * @param ds
	 *            the DeliveryService to check
	 * @return collection of supported caches
	 */
	protected List<Cache> getSupportingCaches(final List<Cache> caches, final DeliveryService ds) {
		for(int i = 0; i < caches.size(); i++) {
			final Cache cache = caches.get(i);
			boolean isAvailable = true;
			if(cache.hasAuthority()) {
				isAvailable = cache.isAvailable();
			}
			if (!isAvailable || !cacheSupportsDeliveryService(cache, ds)) {
				caches.remove(i);
				i--;
			}
		}
		return caches;
	}

	private boolean cacheSupportsDeliveryService(final Cache cache, final DeliveryService ds) {
		boolean result = false;
		for (final DeliveryServiceReference dsRef : cache.getDeliveryServices()) {
			if (dsRef.getDeliveryServiceId().equals(ds.getId())) {
				result = true;
				break;
			}
		}
		return result;
	}

	public CacheRegister getCacheRegister() {
		return cacheRegister;
	}
	protected DeliveryService selectDeliveryService(final Request request, final boolean isHttp) {
		if(cacheRegister==null) {
			LOGGER.warn("no caches yet");
			return null;
		}
		final DeliveryService ds = cacheRegister.getDeliveryService(request, isHttp);
		if (LOGGER.isDebugEnabled()) {
			LOGGER.debug("Selected DeliveryService: " + ds);
		}
		return ds;
	}

	boolean setState(final JSONObject states) throws UnknownHostException {
		setCacheStates(states.optJSONObject("caches"));
		setDsStates(states.optJSONObject("deliveryServices"));
		return true;
	}
	private boolean setDsStates(final JSONObject dsStates) {
		if(dsStates == null) {
			return false;
		}
		final Map<String, DeliveryService> dsMap = cacheRegister.getDeliveryServices();
		for (final String dsName : dsMap.keySet()) {
			dsMap.get(dsName).setState(dsStates.optJSONObject(dsName));
		}
		return true;
	}
	private boolean setCacheStates(final JSONObject cacheStates) {
		if(cacheStates == null) {
			return false;
		}
		final Map<String, Cache> cacheMap = cacheRegister.getCacheMap();
		if(cacheMap == null) { return false; }
		for (final String cacheName : cacheMap.keySet()) {
			final String monitorCacheName = cacheName.replaceFirst("@.*", "");
			final JSONObject state = cacheStates.optJSONObject(monitorCacheName);
			cacheMap.get(cacheName).setState(state);
		}
		return true;
	}

	protected static final String UNABLE_TO_ROUTE_REQUEST = "Unable to route request.";
	protected static final String URL_ERR_STR = "Unable to create URL.";

	public GeolocationService getGeolocationService() {
		return geolocationService;
	}
	public Geolocation getLocation(final String clientIP) throws GeolocationException {
		if(clientIP.contains(":")) {
			return geolocationService6.location(clientIP);
		}
		return geolocationService.location(clientIP);
	}

	/**
	 * Gets hashFunctionPool.
	 * 
	 * @return the hashFunctionPool
	 */
	public ObjectPool getHashFunctionPool() {
		return hashFunctionPool;
	}

	private List<Cache> getCachesByGeo(final Request request, final DeliveryService ds, final Geolocation clientLocation) throws GeolocationException {
		final String zoneId = null; 
		// the specific use of the popularity zone
		// manager was not understood and not used
		// and was therefore was eliminated
		// final String zoneId = getZoneManager().getZone(request.getRequestedUrl());
		final int locationLimit = ds.getLocationLimit();
		int locationsTested = 0;
		final List<CacheLocation> cacheLocations = orderCacheLocations(request,
				getCacheRegister().getCacheLocations(zoneId), ds, clientLocation);
		for (final CacheLocation location : cacheLocations) {
			final List<Cache> caches = selectCache(location, ds);
			if (caches != null) {
				return caches;
			}
			locationsTested++;
			if(locationLimit != 0 && locationsTested >= locationLimit) {
				return null;
			}
		}
		return null;
	}
	protected List<Cache> selectCache(final Request request, final DeliveryService ds, final Track track, final boolean isHttp) throws GeolocationException {
		final String ip = request.getClientIP();
		String requestType = null;
		String requestStr = null;
		if(isHttp) {
			requestStr = ((HTTPRequest)request).getPath();
			requestType = "http";
		} else {
			requestStr = request.getHostname();
			requestType = "dns";
		}
		final CacheLocation cacheLocation = getCoverageZoneCache(ip);
		if(ds.isLocationAvailable(cacheLocation)) {
			final List<Cache> caches = selectCache(cacheLocation, ds);// consistentHash(caches, request);List<Cache>
			if (caches != null) {
				track.setResult(ResultType.CZ);
				return caches;
			}
		}

		if (ds.isCoverageZoneOnly() && cacheLocation == null) {
			LOGGER.warn(String
					.format("No Cache found in CZM (%s, ip=%s, path=%s), geo not supported",
							requestType, ip, requestStr));
			track.setResult(ResultType.MISS);
			return null;
		}

		LOGGER.warn(String.format(
				"No Cache found by CZM (%s, ip=%s, path=%s)", requestType, ip,
				requestStr));

		Geolocation clientLocation = null;
		if(cacheLocation != null) {
			clientLocation = cacheLocation.getGeolocation();
		} else {
			clientLocation = getLocation(request.getClientIP());
			clientLocation = ds.supportLocation(clientLocation, requestType);
			if (clientLocation == null) {
				// particular error was logged in ds.supportLocation
				track.setResult(ResultType.MISS);
				return null;
			}
		}

		final List<Cache> caches = getCachesByGeo(request, ds, clientLocation);
		if(caches != null) {
			track.setResult(ResultType.GEO);
			return caches;
		}
		LOGGER.warn(String.format(
				"No Cache found by Geo (%s, ip=%s, path=%s)", requestType, ip,
				requestStr));
		track.setResult(ResultType.MISS);
		return null;
	}

	public List<InetRecord> route(final DNSRequest request, final Track track) throws GeolocationException {
		track.setRouteType(RouteType.DNS, request.getHostname());

		final DeliveryService ds = selectDeliveryService(request, false);
		if (ds == null) {
			LOGGER.warn("[dns] No DeliveryService found for: "
					+ request.getHostname());
			track.setResult(ResultType.STATIC_ROUTE);
			return null;
		}
		if(!ds.isAvailable()) {
			LOGGER.warn("ds not available: "+ds);
			return ds.getFailureDnsResponse(request, track);
		}

		final List<Cache> caches = selectCache(request, ds, track, false);
		if(caches == null) {
			return ds.getFailureDnsResponse(request, track);
		}
		final List<InetRecord> addresses = new ArrayList<InetRecord>();
		Collections.shuffle(caches, random );
		final int maxDnsIps = ds.getMaxDnsIps();
		int i = 0;
		for(Cache cache : caches) {
			if(maxDnsIps!=0 && i >= maxDnsIps) { break; }
			i++;
			addresses.addAll(
					cache.getIpAddresses(ds.getTtls(), zoneManager, ds.isIp6RoutingEnabled())
				);
		}
		return addresses;
	}

	public HTTPRouteResult route(final HTTPRequest request, final Track track) throws MalformedURLException, GeolocationException {
		track.setRouteType(RouteType.HTTP, request.getHostname());

		final DeliveryService ds = selectDeliveryService(request, true);

		if (ds == null) {
			LOGGER.warn("No DeliveryService found for: "
					+ request.getRequestedUrl());
			track.setResult(ResultType.DS_MISS);
			return null;
		}

		final HTTPRouteResult routeResult = new HTTPRouteResult();

		routeResult.setDeliveryService(ds);

		if (!ds.isAvailable()) {
			LOGGER.warn("ds unavailable: " + ds);
			routeResult.setUrl(ds.getFailureHttpResponse(request, track));
			return routeResult;
		}

		final List<Cache> caches = selectCache(request, ds, track, true);

		if (caches == null) {
			routeResult.setUrl(ds.getFailureHttpResponse(request, track));
			return routeResult;
		}

		final Dispersion dispersion = ds.getDispersion();
		final Cache cache = dispersion.getCache(consistentHash(caches, request.getPath()));

		routeResult.setUrl(new URL(ds.createURIString(request, cache)));

		return routeResult;
	}

	protected CacheLocation getCoverageZoneCache(final String ip) {
		NetworkNode nn = null;
		try {
			nn = NetworkNode.getInstance().getNetwork(ip);
		} catch (NetworkNodeException e) {
			LOGGER.warn(e);
		}
		if (nn == null) {
			return null;
		}

		final String locId = nn.getLoc();
		final CacheLocation cl = nn.getCacheLocation();
		if(cl != null) {
			return cl;
		}
		if(locId == null) {
			return null;
		}

			// find CacheLocation
		final Collection<CacheLocation> caches = getCacheRegister()
				.getCacheLocations();
		for (CacheLocation cl2 : caches) {
			if (cl2.getId().equals(locId)) {
				nn.setCacheLocation(cl2);
				return cl2;
			}
		}
		return null;
	}

	/**
	 * Utilizes the hashValues stored with each cache to select the cache that
	 * the specified hash should map to.
	 * 
	 * @param caches
	 *            the list of caches to choose from
	 * @param hash
	 *            the hash value for the request
	 * @return a cache or null if no cache can be found to map to
	 */
	protected Cache consistentHashOld(final List<Cache> caches,
			final String request) {
		double hash = 0;
		HashFunction hashFunction = null;
		try {
			hashFunction = (HashFunction) hashFunctionPool.borrowObject();
			try {
				hash = hashFunction.hash(request);
			} catch (final Exception e) {
				LOGGER.debug(e.getMessage(), e);
			}
			hashFunctionPool.returnObject(hashFunction);
		} catch (final Exception e) {
			LOGGER.debug(e.getMessage(), e);
		}
		if (hash == 0) {
			LOGGER.warn("Problem with hashFunctionPool, request: " + request);
			return null;
		}

		return searchCacheOld(caches, hash);
	}

	private Cache searchCacheOld(final List<Cache> caches, final double hash) {
		Cache minCache = null;
		double minHash = Double.MAX_VALUE;
		Cache foundCache = null;
		double minDiff = Double.MAX_VALUE;

		for (final Cache cache : caches) {
			for (final double hashValue : cache.getHashValues()) {
				if (hashValue < minHash) {
					minCache = cache;
					minHash = hashValue;
				}
				final double diff = hashValue - hash;
				if ((diff >= 0) && (diff < minDiff)) {
					foundCache = cache;
					minDiff = diff;
				}
			}
		}

		final Cache result = (foundCache != null) ? foundCache : minCache;
		if (LOGGER.isDebugEnabled()) {
			LOGGER.debug("Selected cache: " + result);
		}
		return result;
	}

	/**
	 * Utilizes the hashValues stored with each cache to select the cache that
	 * the specified hash should map to.
	 * 
	 * @param caches
	 *            the list of caches to choose from
	 * @param request
	 *            the request string from which the hash will be generated
	 * @return a cache or null if no cache can be found to map to
	 */
	protected SortedMap<Double, Cache> consistentHash(final List<Cache> caches,
			final String request) {
		double hash = 0;
		HashFunction hashFunction = null;
		try {
			hashFunction = (HashFunction) hashFunctionPool.borrowObject();
			try {
				hash = hashFunction.hash(request);
			} catch (final Exception e) {
				LOGGER.debug(e.getMessage(), e);
			}
			hashFunctionPool.returnObject(hashFunction);
		} catch (final Exception e) {
			LOGGER.debug(e.getMessage(), e);
		}
		if (hash == 0) {
			LOGGER.warn("Problem with hashFunctionPool, request: " + request);
			return null;
		}

		final SortedMap<Double, Cache> cacheMap = new TreeMap<Double, Cache>();

		for (final Cache cache : caches) {
			final double r = cache.getClosestHash(hash);
			if (r == 0) {
				LOGGER.warn("Error: getClosestHash returned 0: " + cache);
				return null;
			}

			double diff = Math.abs(r - hash);

			if (cacheMap.containsKey(diff)) {
				LOGGER.warn("Error: cacheMap contains diff " + diff + "; incrementing to avoid collision");
				long bits = Double.doubleToLongBits(diff);

				while (cacheMap.containsKey(diff)) {
					bits++;
					diff = Double.longBitsToDouble(bits);
				}
			}

			cacheMap.put(diff, cache);
		}

		return cacheMap;
	}

	/**
	 * Returns a list {@link CacheLocation}s sorted by distance from the client.
	 * If the client's location could not be determined, then the list is
	 * unsorted.
	 * 
	 * @param request
	 *            the client's request
	 * @param cacheLocations
	 *            the collection of CacheLocations to order
	 * @param ds
	 * @return the ordered list of locations
	 */
	protected List<CacheLocation> orderCacheLocations(final Request request,
			final Collection<CacheLocation> cacheLocations,
			final DeliveryService ds,
			final Geolocation clientLocation) {
		final List<CacheLocation> locations = new ArrayList<CacheLocation>();
		for(CacheLocation cl : cacheLocations) {
			if(ds.isLocationAvailable(cl)) {
				locations.add(cl);
			}
		}

		Collections.sort(locations, new CacheLocationComparator(
				clientLocation));

		return locations;
	}

	/**
	 * Selects a {@link Cache} from the {@link CacheLocation} provided.
	 * 
	 * @param location
	 *            the caches that will considered
	 * @param ds
	 *            the delivery service for the request
	 * @param request
	 *            the request to consider for cache selection
	 * @return the selected cache or null if none can be found
	 */
	private List<Cache> selectCache(final CacheLocation location,
			final DeliveryService ds) {
		if (LOGGER.isDebugEnabled()) {
			LOGGER.debug("Trying location: " + location.getId());
		}

		final List<Cache> caches = getSupportingCaches(location.getCaches(), ds);
		if (caches.isEmpty()) {
			if (LOGGER.isDebugEnabled()) {
				LOGGER.debug("No online, supporting caches were found at location: "
						+ location.getId());
			}
			return null;
		}

		return caches;//consistentHash(caches, request);List<Cache>
	}

	public Zone getDynamicZone(final Name qname, final int qtype, final InetAddress clientAddress) {
		return zoneManager.getDynamicZone(qname, qtype, clientAddress);
	}

}
