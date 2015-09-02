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

package com.comcast.cdn.traffic_control.traffic_router.core.dns;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.security.GeneralSecurityException;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.xbill.DNS.AAAARecord;
import org.xbill.DNS.ARecord;
import org.xbill.DNS.CNAMERecord;
import org.xbill.DNS.DClass;
import org.xbill.DNS.NSRecord;
import org.xbill.DNS.Name;
import org.xbill.DNS.RRset;
import org.xbill.DNS.Record;
import org.xbill.DNS.SOARecord;
import org.xbill.DNS.SetResponse;
import org.xbill.DNS.TextParseException;
import org.xbill.DNS.Type;
import org.xbill.DNS.Zone;

import com.comcast.cdn.traffic_control.traffic_router.core.cache.Cache;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.Cache.DeliveryServiceReference;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheRegister;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.InetRecord;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.Resolver;
import com.comcast.cdn.traffic_control.traffic_router.core.ds.DeliveryService;
import com.comcast.cdn.traffic_control.traffic_router.core.request.DNSRequest;
import com.comcast.cdn.traffic_control.traffic_router.core.router.DNSRouteResult;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track;
import com.comcast.cdn.traffic_control.traffic_router.core.router.TrafficRouter;
import com.google.common.cache.CacheBuilder;
import com.google.common.cache.CacheBuilderSpec;
import com.google.common.cache.CacheLoader;
import com.google.common.cache.LoadingCache;
import com.google.common.cache.RemovalListener;
import com.google.common.cache.RemovalNotification;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.ListenableFutureTask;

public class ZoneManager extends Resolver {
	private static final Logger LOGGER = Logger.getLogger(ZoneManager.class);

	private final TrafficRouter trafficRouter;
	private static String dnsRoutingName;
	private static String httpRoutingName;
	private static LoadingCache<ZoneKey, Zone> dynamicZoneCache = null;
	private static LoadingCache<ZoneKey, Zone> zoneCache = null;
	private static ScheduledExecutorService zoneMaintenanceExecutor = null;
	private static ExecutorService zoneExecutor = null;
	private final StatTracker statTracker;

	private static String keyServerUrl;
	private static String keyServerUsername;
	private static String keyServerPassword;
	private static String zoneDirectory;
	private static SignatureManager signatureManager;

	private static Name topLevelDomain;

	protected static enum ZoneCacheType {
		DYNAMIC, STATIC
	}

	public ZoneManager(final TrafficRouter tr, final StatTracker statTracker) throws IOException {
		initTopLevelDomain(tr.getCacheRegister());
		initSignatureManager(tr.getCacheRegister());
		initZoneCache(tr.getCacheRegister());

		this.trafficRouter = tr;
		this.statTracker = statTracker;
	}

	public static void destroy() {
		LOGGER.info("Destroy called; stopping maintenance and zone executors");
		zoneMaintenanceExecutor.shutdownNow();
		zoneExecutor.shutdownNow();
		signatureManager.destroy();
	}

	protected void rebuildZoneCache(final CacheRegister cacheRegister) {
		initZoneCache(cacheRegister);
	}

	private static void initTopLevelDomain(final CacheRegister data) throws TextParseException {
		String tld = data.getConfig().optString("domain_name");

		if (!tld.endsWith(".")) {
			tld = tld + ".";
		}

		setTopLevelDomain(new Name(tld));
	}

	private void initSignatureManager(final CacheRegister cacheRegister) {
		final KeyServer ks = new KeyServer(keyServerUrl, keyServerUsername, keyServerPassword);
		final SignatureManager sm = new SignatureManager(this, cacheRegister, ks);
		ZoneManager.signatureManager = sm;
	}

	protected static void initZoneCache(final CacheRegister cacheRegister) {
		synchronized(ZoneManager.class) {
			final JSONObject config = cacheRegister.getConfig();

			int poolSize = 1;
			final double scale = config.optDouble("zonemanager.threadpool.scale", 0.75);
			final int cores = Runtime.getRuntime().availableProcessors();

			if (cores > 2) {
				final Double s = Math.floor((double) cores * scale);

				if (s.intValue() > 1) {
					poolSize = s.intValue();
				}
			}

			LOGGER.debug("Number of cores on this system: " + cores);
			LOGGER.debug("Scale for thread pools: " + scale);
			LOGGER.debug("Threads in thread pools: " + poolSize);

			final ExecutorService initExecutor = Executors.newFixedThreadPool(poolSize);

			final ExecutorService ze = Executors.newFixedThreadPool(poolSize);
			final ScheduledExecutorService me = Executors.newScheduledThreadPool(2); // 2 threads, one for static, one for dynamic, threads to refresh zones
			final int maintenanceInterval = config.optInt("zonemanager.cache.maintenance.interval", 300); // default 5 minutes
			final String dspec = "expireAfterAccess=" + config.optString("zonemanager.dynamic.response.expiration", "300s"); // default to 5 minutes

			final LoadingCache<ZoneKey, Zone> dzc = createZoneCache(ZoneCacheType.DYNAMIC, CacheBuilderSpec.parse(dspec));
			final LoadingCache<ZoneKey, Zone> zc = createZoneCache(ZoneCacheType.STATIC);

			initZoneDirectory();

			try {
				LOGGER.info("Generating zone data");
				generateZones(cacheRegister, zc, initExecutor);
				initExecutor.shutdown();
				initExecutor.awaitTermination(5, TimeUnit.MINUTES);
				LOGGER.info("Zone generation complete");
			} catch (final InterruptedException ex) {
				LOGGER.warn("Initialization of zone data exceeded time limit of 5 minutes; continuing", ex);
			} catch (IOException ex) {
				LOGGER.fatal("Caught fatal exception while generating zone data!", ex);
			}

			me.scheduleWithFixedDelay(getMaintenanceRunnable(dzc, ZoneCacheType.DYNAMIC, maintenanceInterval), 0, maintenanceInterval, TimeUnit.SECONDS);
			me.scheduleWithFixedDelay(getMaintenanceRunnable(zc, ZoneCacheType.STATIC, maintenanceInterval), 0, maintenanceInterval, TimeUnit.SECONDS);

			final ExecutorService tze = ZoneManager.zoneExecutor;
			final ScheduledExecutorService tme = ZoneManager.zoneMaintenanceExecutor;
			final LoadingCache<ZoneKey, Zone> tzc = ZoneManager.zoneCache;
			final LoadingCache<ZoneKey, Zone> tdzc = ZoneManager.dynamicZoneCache;

			ZoneManager.zoneExecutor = ze;
			ZoneManager.zoneMaintenanceExecutor = me;
			ZoneManager.dynamicZoneCache = dzc;
			ZoneManager.zoneCache = zc;

			if (tze != null) {
				tze.shutdownNow();
			}

			if (tme != null) {
				tme.shutdownNow();
			}

			if (tzc != null) {
				tzc.invalidateAll();
			}

			if (tdzc != null) {
				tdzc.invalidateAll();
			}
		}
	}

	private static Runnable getMaintenanceRunnable(final LoadingCache<ZoneKey, Zone> cache, final ZoneCacheType type, final int refreshInterval) {
		return new Runnable() {
			public void run() {
				cache.cleanUp();

				for (ZoneKey zoneKey : cache.asMap().keySet()) {
					if (signatureManager.needsRefresh(type, zoneKey, refreshInterval)) {
						cache.refresh(zoneKey);
					}
				}
			}
		};
	}

	private static void initZoneDirectory() {
		synchronized(LOGGER) {
			final File zoneDir = new File(getZoneDirectory());
			if (zoneDir.exists()) {
				for (String entry : zoneDir.list()) {
					final File zone = new File(zoneDir.getPath(), entry);
					zone.delete();
				}

				final boolean deleted = zoneDir.delete();

				if (deleted) {
					LOGGER.info("Successfully deleted " + zoneDir);
				} else {
					LOGGER.warn("Unable to delete " + zoneDir);
				}
			}

			zoneDir.mkdir();
		}
	}

	private static void writeZone(final Zone zone) throws IOException {
		synchronized(LOGGER) {
			final String fileName = getZoneDirectory() +"/"+zone.getOrigin().toString();
			LOGGER.info("writing: "+fileName);
			final String file = zone.toMasterFile();
			final FileWriter w = new FileWriter(fileName);
			IOUtils.write(file, w);
			w.flush();
			w.close();
		}
	}

	public StatTracker getStatTracker() {
		return statTracker;
	}

	private static LoadingCache<ZoneKey, Zone> createZoneCache(final ZoneCacheType cacheType) {
		return createZoneCache(cacheType, CacheBuilderSpec.parse(""));
	}

	private static LoadingCache<ZoneKey, Zone> createZoneCache(final ZoneCacheType cacheType, final CacheBuilderSpec spec) {
		final RemovalListener<ZoneKey, Zone> removalListener = new RemovalListener<ZoneKey, Zone>() {
			public void onRemoval(final RemovalNotification<ZoneKey, Zone> removal) {
				if (removal.wasEvicted()) {
					LOGGER.warn(cacheType + ": " + removal.getKey().getName() + " evicted from cache: " + removal.getCause());
				} else {
					LOGGER.warn(cacheType + ": " + removal.getKey().getName() + " evicted from cache: " + removal.getCause());
				}
			}
		};

		return CacheBuilder.from(spec).removalListener(removalListener).build(
			new CacheLoader<ZoneKey, Zone>() {
				final boolean writeZone = (cacheType == ZoneCacheType.STATIC) ? true : false;

				public Zone load(final ZoneKey zoneKey) throws IOException, GeneralSecurityException {
					return loadZone(zoneKey, writeZone);
				}

				public ListenableFuture<Zone> reload(final ZoneKey zoneKey, final Zone prevZone) throws IOException, GeneralSecurityException {
					final ListenableFutureTask<Zone> zoneTask = ListenableFutureTask.create(new Callable<Zone>() {
						public Zone call() throws IOException, GeneralSecurityException {
							return loadZone(zoneKey, writeZone);
						}
					});

					zoneExecutor.execute(zoneTask);

					return zoneTask;
				}
			}
		);
	}

	public static Zone loadZone(final ZoneKey zoneKey, final boolean writeZone) throws IOException, GeneralSecurityException {
		LOGGER.debug("Attempting to load " + zoneKey.getName());
		final Name name = zoneKey.getName();
		List<Record> records = zoneKey.getRecords();
		zoneKey.updateTimestamp();

		if (zoneKey instanceof SignedZoneKey) {
			records = signatureManager.signZone(name, records, (SignedZoneKey) zoneKey);
		}

		final Zone zone = new Zone(name, records.toArray(new Record[records.size()]));

		if (writeZone) {
			writeZone(zone);
		}

		return zone;
	}

	private static void generateZones(final CacheRegister data, final LoadingCache<ZoneKey, Zone> zc, final ExecutorService initExecutor) throws IOException {
		final Map<String, List<Record>> zoneMap = new HashMap<String, List<Record>>();
		final Map<String, DeliveryService> dsMap = new HashMap<String, DeliveryService>();
		final String tld = getTopLevelDomain().toString(true); // Name.toString(true) - omit the trailing dot

		for (DeliveryService ds : data.getDeliveryServices().values()) {
			final JSONArray domains = ds.getDomains();

			if (domains == null) {
				continue;
			}

			for (int j = 0; j < domains.length(); j++) {
				String domain = domains.optString(j);

				if (domain.endsWith("+")) {
					domain = domain.replaceAll("\\+\\z", ".") + tld;
				}

				dsMap.put(domain, ds);
			}
		}

		final Map<String, List<Record>> superDomains = populateZoneMap(zoneMap, dsMap, data);
		final List<Record> superRecords = fillZones(zoneMap, dsMap, data, zc, initExecutor);
		final List<Record> upstreamRecords = fillZones(superDomains, dsMap, data, superRecords, zc, initExecutor);

		for (Record record : upstreamRecords) {
			if (record.getType() == Type.DS) {
				LOGGER.warn("Publish this DS record in the parent zone: " + record);
			}
		}
	}

	private static List<Record> fillZones(final Map<String, List<Record>> zoneMap, final Map<String, DeliveryService> dsMap, final CacheRegister data, final LoadingCache<ZoneKey, Zone> zc, final ExecutorService initExecutor)
			throws IOException {
		return fillZones(zoneMap, dsMap, data, null, zc, initExecutor);
	}

	private static List<Record> fillZones(final Map<String, List<Record>> zoneMap, final Map<String, DeliveryService> dsMap, final CacheRegister data, final List<Record> superRecords, final LoadingCache<ZoneKey, Zone> zc, final ExecutorService initExecutor)
			throws IOException {
		final String hostname = InetAddress.getLocalHost().getHostName().replaceAll("\\..*", "");

		final List<Record> records = new ArrayList<Record>();

		for (String domain : zoneMap.keySet()) {
			if (superRecords != null && !superRecords.isEmpty()) {
				zoneMap.get(domain).addAll(superRecords);
			}

			records.addAll(createZone(domain, zoneMap, dsMap, hostname, data, zc, initExecutor));
		}

		return records;
	}

	private static List<Record> createZone(final String domain, final Map<String, List<Record>> zoneMap, final Map<String, DeliveryService> dsMap, 
			final String hostname, final CacheRegister data, final LoadingCache<ZoneKey, Zone> zc, final ExecutorService initExecutor) throws IOException {
		final DeliveryService ds = dsMap.get(domain);
		final JSONObject trafficRouters = data.getTrafficRouters();
		final JSONObject config = data.getConfig();

		JSONObject ttl = null;
		JSONObject soa = null;

		if (ds != null) {
			ttl = ds.getTtls();
			soa = ds.getSoa();
		} else {
			ttl = config.optJSONObject("ttls");
			soa = config.optJSONObject("soa");
		}

		final Name name = new Name(domain+".");
		LOGGER.debug("Generating zone data for " + name);
		final List<Record> list = zoneMap.get(domain);
		final Name meTr = newName(hostname, domain);
		final Name admin = newName(ZoneUtils.getString(soa, "admin", "traffic_control"), domain);
		list.add(new SOARecord(name, DClass.IN, 
				ZoneUtils.getLong(ttl, "SOA", 86400), meTr, admin, 
				ZoneUtils.getLong(soa, "serial", ZoneUtils.getSerial(data.getStats())), 
				ZoneUtils.getLong(soa, "refresh", 28800), 
				ZoneUtils.getLong(soa, "retry", 7200), 
				ZoneUtils.getLong(soa, "expire", 604800), 
				ZoneUtils.getLong(soa, "minimum", 60)));

		addTrafficRouters(list, trafficRouters, name, ttl, domain, ds);
		addStaticDnsEntries(list, ds, domain);

		final List<Record> records = new ArrayList<Record>();

		try {
			records.addAll(signatureManager.generateDSRecords(name));
			list.addAll(signatureManager.generateDNSKEYRecords(name));
			initExecutor.execute(new Runnable() {
				@Override
				public void run() {
					try {
						zc.get(signatureManager.generateZoneKey(name, list)); // cause the zone to be loaded into the new cache
					} catch (ExecutionException ex) {
						LOGGER.fatal("Unable to load zone into cache: " + ex.getMessage(), ex);
					}
				}
			});
		} catch (NoSuchAlgorithmException ex) {
			LOGGER.fatal("Unable to create zone: " + ex.getMessage(), ex);
		}

		return records;
	}

	private static void addStaticDnsEntries(final List<Record> list, final DeliveryService ds, final String domain)
			throws TextParseException, UnknownHostException {
		if (ds != null && ds.getStaticDnsEntries() != null) {
			final JSONArray entryList = ds.getStaticDnsEntries();

			for (int j = 0; j < entryList.length(); j++) {
				try {
					final JSONObject staticEntry = entryList.getJSONObject(j);
					final String type = staticEntry.getString("type").toUpperCase();
					final String jsName = staticEntry.getString("name");
					final String value = staticEntry.getString("value");
					final Name name = newName(jsName, domain);
					long ttl = staticEntry.optInt("ttl");

					if (ttl == 0) {
						ttl = ZoneUtils.getLong(ds.getTtls(), type, 60);
					}

					if ("A".equals(type)) {
						list.add(new ARecord(name, DClass.IN, ttl, InetAddress.getByName(value)));
					} else if ("AAAA".equals(type)) {
						list.add(new AAAARecord(name, DClass.IN, ttl, InetAddress.getByName(value)));
					} else if ("CNAME".equals(type)) {
						list.add(new CNAMERecord(name, DClass.IN, ttl, new Name(value)));
					}
				} catch (JSONException e) {
					LOGGER.error(e);
				}
			}
		}
	}

	private static void addTrafficRouters(final List<Record> list, final JSONObject trafficRouters, final Name name, 
			final JSONObject ttl, final String domain, final DeliveryService ds) 
					throws TextParseException, UnknownHostException {
		final boolean ip6RoutingEnabled = (ds == null || (ds != null && ds.isIp6RoutingEnabled())) ? true : false;

		for (String key : JSONObject.getNames(trafficRouters)) {
			final JSONObject trJo = trafficRouters.optJSONObject(key);

			if(trJo.has("status") && "OFFLINE".equals(trJo.optString("status"))) {
				// if "status": "OFFLINE"
				continue;
			}

			final Name trName = newName(key, domain.toString());
			Name glueName;

			if (ds == null && trJo.has("fqdn") && trJo.optString("fqdn") != null) {
				glueName = newName(trJo.optString("fqdn"));
			} else {
				final Name superDomain = new Name(name, 1);
				glueName = newName(key, superDomain.toString());
			}

			String ip6 = trJo.optString("ip6");

			list.add(new NSRecord(name, DClass.IN, ZoneUtils.getLong(ttl, "NS", 60), glueName));
			list.add(new ARecord(trName,
					DClass.IN, ZoneUtils.getLong(ttl, "A", 60), 
					InetAddress.getByName(trJo.optString("ip"))));

			if (ip6 != null && !ip6.isEmpty() && ip6RoutingEnabled) {
				ip6 = ip6.replaceAll("/.*", "");
				list.add(new AAAARecord(trName,
						DClass.IN,
						ZoneUtils.getLong(ttl, "AAAA", 60),
						Inet6Address.getByName(ip6)));
			}

			if (ds != null && !ds.isDns()) {
				addHttpRoutingRecords(list, domain, trJo, ttl, ip6RoutingEnabled);
			}
		}
	}

	private static void addHttpRoutingRecords(final List<Record> list, final String domain, final JSONObject trJo, final JSONObject ttl, final boolean addTrafficRoutersAAAA) 
					throws TextParseException, UnknownHostException {
		final Name trName = newName(getHttpRoutingName(), domain);
		list.add(new ARecord(trName,
				DClass.IN,
				ZoneUtils.getLong(ttl, "A", 60),
				InetAddress.getByName(trJo.optString("ip"))));
		String ip6 = trJo.optString("ip6");
		if (addTrafficRoutersAAAA && ip6 != null && !ip6.isEmpty()) {
			ip6 = ip6.replaceAll("/.*", "");
			list.add(new AAAARecord(trName,
					DClass.IN,
					ZoneUtils.getLong(ttl, "AAAA", 60),
					Inet6Address.getByName(ip6)));
		}
	}

	private static Name newName(final String hostname, final String domain) throws TextParseException {
		return newName(hostname + "." + domain);
	}

	private static Name newName(final String fqdn) throws TextParseException {
		if (fqdn.endsWith(".")) {
			return new Name(fqdn);
		} else {
			return new Name(fqdn + ".");
		}
	}

	private static final Map<String, List<Record>> populateZoneMap(final Map<String, List<Record>> zoneMap,
			final Map<String, DeliveryService> dsMap, final CacheRegister data) throws IOException {
		final Map<String, List<Record>> superDomains = new HashMap<String, List<Record>>();

		for (Cache c : data.getCacheMap().values()) {
			for (DeliveryServiceReference dsr : c.getDeliveryServices()) {
				final DeliveryService ds = data.getDeliveryService(dsr.getDeliveryServiceId());
				final String fqdn = dsr.getFqdn();
				final String[] parts = fqdn.split("\\.", 2);
				final String host = parts[0];
				final String domain = parts[1];

				dsMap.put(domain, ds);
				List<Record> zholder = zoneMap.get(domain);

				if (zholder == null) {
					zholder = new ArrayList<Record>();
					zoneMap.put(domain, zholder);
				}

				if (host.equalsIgnoreCase(getDnsRoutingName())) {
					continue;
				}

				final Name name = new Name(fqdn+".");
				final JSONObject ttl = ds.getTtls();

				try {
					zholder.add(new ARecord(name,
						DClass.IN,
						ZoneUtils.getLong(ttl, "A", 60),
						c.getIp4()));
				} catch (IllegalArgumentException e) {
					LOGGER.warn(e+" : "+c.getIp4());
				}

				final InetAddress ip6 = c.getIp6();

				if (ip6 != null && ds != null && ds.isIp6RoutingEnabled()) {
					zholder.add(new AAAARecord(name,
							DClass.IN,
							ZoneUtils.getLong(ttl, "AAAA", 60),
							ip6));
				}

				final String superdomain = domain.split("\\.", 2)[1];
				zholder = superDomains.get(superdomain);

				if (zholder == null) {
					zholder = new ArrayList<Record>();
					superDomains.put(superdomain, zholder);
				}
			}
		}

		return superDomains;
	}

	/**
	 * Gets trafficRouter.
	 * 
	 * @return the trafficRouter
	 */
	public TrafficRouter getTrafficRouter() {
		return trafficRouter;
	}

	/**
	 * Attempts to find a {@link Zone} that would contain the specified {@link Name}.
	 * 
	 * @param name
	 *            the Name to use to attempt to find the Zone
	 * @return the Zone to use to resolve the specified Name
	 */
	public Zone getZone(final Name name) {
		return getZone(name, 0);
	}

	/**
	 * Attempts to find a {@link Zone} that would contain the specified {@link Name}.
	 *
	 * @param name
	 *            the Name to use to attempt to find the Zone
	 * @param qtype
	 *            the Type to use to control Zone ordering
	 * @return the Zone to use to resolve the specified Name
	 */
	public Zone getZone(final Name name, final int qtype) {
		Zone result = null;
		final Map<ZoneKey, Zone> zoneMap = zoneCache.asMap();
		final List<ZoneKey> sorted = new ArrayList<ZoneKey>(zoneMap.keySet());

		Collections.sort(sorted);

		// put the superDomains at the beginning of the list so we look there first for DS records
		if (qtype == Type.DS) {
			Collections.reverse(sorted);
		}

		for (ZoneKey key : sorted) {
			final Zone zone = zoneMap.get(key);
			final Name origin = zone.getOrigin();

			if (name.subdomain(origin)) {
				result = zone;
				break;
			}
		}

		if (result == null) {
			LOGGER.warn(String.format("subdomain NOT found: '%s'", name));
		}

		return result;
	}

	/**
	 * Creates a dynamic zone that serves a set of A and AAAA records for the specified {@link Name}
	 * .
	 * 
	 * @param staticZone
	 *            The Zone that would normally serve this request
	 * @param name
	 *            the Name that is being requested
	 * @param clientAddress
	 *            the IP address of the requestor
	 * @param dnssecRequest
	 *            whether the client requested DNSSEC
	 * @return the new Zone to serve the request or null if the static Zone should be used
	 */
	private Zone createDynamicZone(final Zone staticZone, final Name name, final int qtype, final InetAddress clientAddress, final boolean dnssecRequest) {
		if (clientAddress==null) {
			return staticZone;
		}

		final DNSRequest request = new DNSRequest();
		request.setClientIP(clientAddress.getHostAddress());
		request.setHostname(name.relativize(Name.root).toString());
		request.setQtype(qtype);
		final Track track = StatTracker.getTrack();

		try {
			final DNSRouteResult result = trafficRouter.route(request, track);

			if (result != null) {
				return fillDynamicZone(staticZone, name, result.getAddresses(), dnssecRequest);
			} else {
				return null;
			}

		} catch (final Exception e) {
			LOGGER.error(e.getMessage(), e);
		} finally {
			statTracker.saveTrack(track);
		}

		return null;
	}

	private static Zone fillDynamicZone(final Zone staticZone, final Name name, final List<InetRecord> addresses, final boolean dnssecRequest) {
		if (addresses == null) {
			return null;
		}

		try {
			final List<Record> records = createZoneRecords(staticZone);
			int recordsAdded = 0;

			for (final InetRecord address : addresses) {
				final Record record = createRecord(name, address);

				if (record != null) {
					records.add(record);
					recordsAdded++;
				}
			}

			if (recordsAdded > 0) {
				try {
					final ZoneKey zoneKey = signatureManager.generateDynamicZoneKey(staticZone.getOrigin(), records, dnssecRequest);
					final Zone zone = dynamicZoneCache.get(zoneKey);
					return zone;
				} catch (ExecutionException e) {
					LOGGER.error(e, e);
				}

				return new Zone(staticZone.getOrigin(), records.toArray(new Record[records.size()]));
			}
		} catch (final IOException e) {
			LOGGER.error(e.getMessage(), e);
		}

		return null;
	}

	private static Record createRecord(final Name name, final InetRecord address) throws TextParseException {
		Record record = null;

		if (address.isAlias()) {
			record = new CNAMERecord(name, DClass.IN, address.getTTL(), new Name(address.getAlias() +"."));			
		} else if (address.isInet4()) { // address instanceof Inet4Address
			record = new ARecord(name, DClass.IN, address.getTTL(), address.getAddress());
		} else if (address.isInet6()) {
			record = new AAAARecord(name, DClass.IN, address.getTTL(), address.getAddress());
		}

		return record;
	}

	private static List<Record> createZoneRecords(final Zone staticZone) throws IOException {
		final List<Record> records = new ArrayList<Record>();
		records.add(staticZone.getSOA());

		@SuppressWarnings("unchecked")
		final Iterator<Record> ns = staticZone.getNS().rrs();

		while (ns.hasNext()) {
			records.add(ns.next());
		}

		return records;
	}

	private List<InetRecord> lookup(final Name qname, final Zone zone, final int type) {
		final List<InetRecord> ipAddresses = new ArrayList<InetRecord>();
		final SetResponse sr = zone.findRecords(qname, type);

		if (LOGGER.isDebugEnabled()) {
			LOGGER.debug("SetResponse: " + sr);
		}

		if (sr.isSuccessful()) {
			final RRset[] answers = sr.answers();

			for (final RRset answer : answers) {
				LOGGER.debug("addRRset: " + answer);
				@SuppressWarnings("unchecked")
				final Iterator<Record> it = answer.rrs();

				while (it.hasNext()) {
					final Record r = it.next();

					if (r instanceof ARecord) {
						final ARecord ar = (ARecord)r;
						ipAddresses.add(new InetRecord(ar.getAddress(), ar.getTTL()));
					} else if (r instanceof AAAARecord) {
						final AAAARecord ar = (AAAARecord)r;
						ipAddresses.add(new InetRecord(ar.getAddress(), ar.getTTL()));
					} else {
						LOGGER.debug("record not ARecord or AAAARecord: " + r);
					}
				}
			}

			return ipAddresses;
		} else {
			LOGGER.debug(String.format("failed: zone.findRecords(%s, %d)", qname, type));
		}

		return null;
	}

	public List<InetRecord> resolve(final String fqdn) {
		try {
			final Name name = new Name(fqdn);
			final Zone zone = getZone(name);
			if (zone == null) {
				LOGGER.debug("No zone - Defaulting to system resolver: "+fqdn);
				return super.resolve(fqdn);
			}
			return lookup(name, zone, Type.A);
		} catch (TextParseException e) {
			LOGGER.warn("TextParseException from: "+fqdn,e);
		}

		LOGGER.debug(String.format("resolved from zone: %s", fqdn));
		return null;
	}

	public List<InetRecord> resolve(final String fqdn, final String address) throws UnknownHostException {
		try {
			final Name name = new Name(fqdn);
			Zone zone = getZone(name);
			final InetAddress addr = InetAddress.getByName(address);
			final int qtype = (addr instanceof Inet6Address) ? Type.AAAA : Type.A;
			final Zone dynamicZone = createDynamicZone(zone, name, qtype, addr, true);

			if (dynamicZone != null) { 
				zone = dynamicZone; 
			}

			if (zone == null) {
				LOGGER.debug("No zone - Defaulting to system resolver: "+fqdn);
				return super.resolve(fqdn);
			}

			return lookup(name, zone, Type.A);
		} catch (TextParseException e) {
			LOGGER.warn("TextParseException from: "+fqdn,e);
		}

		LOGGER.debug(String.format("resolved from zone: %s", fqdn));
		return null;
	}

	public Zone getDynamicZone(final Name qname, final int qtype, final InetAddress clientAddress, final boolean isDnssecRequest) {
		final Zone zone = getZone(qname, qtype);

		if (zone == null) {
			LOGGER.debug("Unable to find zone for " + qname);
			return null;
		}

		final SetResponse sr = zone.findRecords(qname, qtype);

		if (sr.isSuccessful()) {
			return zone;
		} else if (qname.toString().toLowerCase().matches(getDnsRoutingName() + "\\..*")) {
			final Zone dynamicZone = createDynamicZone(zone, qname, qtype, clientAddress, isDnssecRequest);

			if (dynamicZone != null) {
				return dynamicZone;
			}
		}

		return zone;
	}

	public static String getKeyServerUrl() {
		return keyServerUrl;
	}

	public static void setKeyServerUrl(final String keyServerUrl) {
		ZoneManager.keyServerUrl = keyServerUrl;
	}

	public static String getKeyServerUsername() {
		return keyServerUsername;
	}

	public static void setKeyServerUsername(final String keyServerUsername) {
		ZoneManager.keyServerUsername = keyServerUsername;
	}

	public static String getKeyServerPassword() {
		return keyServerPassword;
	}

	public static void setKeyServerPassword(final String keyServerPassword) {
		ZoneManager.keyServerPassword = keyServerPassword;
	}

	public static String getZoneDirectory() {
		return zoneDirectory;
	}

	public static void setZoneDirectory(final String zoneDirectory) {
		ZoneManager.zoneDirectory = zoneDirectory;
	}

	private static String getDnsRoutingName() {
		return dnsRoutingName;
	}

	public static void setDnsRoutingName(final String dnsRoutingName) {
		ZoneManager.dnsRoutingName = dnsRoutingName.toLowerCase();
	}

	private static String getHttpRoutingName() {
		return httpRoutingName;
	}

	public static void setHttpRoutingName(final String httpRoutingName) {
		ZoneManager.httpRoutingName = httpRoutingName.toLowerCase();
	}

	protected static Name getTopLevelDomain() {
		return topLevelDomain;
	}

	private static void setTopLevelDomain(final Name topLevelDomain) {
		ZoneManager.topLevelDomain = topLevelDomain;
	}
}
