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

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import org.apache.log4j.Logger;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.xbill.DNS.DSRecord;
import org.xbill.DNS.Name;
import org.xbill.DNS.Record;
import org.xbill.DNS.TextParseException;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheRegister;
import com.comcast.cdn.traffic_control.traffic_router.core.dns.ZoneManager.ZoneCacheType;
import com.comcast.cdn.traffic_control.traffic_router.core.util.TrafficOpsUtils;
import com.comcast.cdn.traffic_control.traffic_router.core.util.ProtectedFetcher;
import com.verisignlabs.dnssec.security.DnsKeyPair;
import com.verisignlabs.dnssec.security.JCEDnsSecSigner;
import com.verisignlabs.dnssec.security.SignUtils;


public final class SignatureManager {
	private static final Logger LOGGER = Logger.getLogger(SignatureManager.class);
	private int expirationMultiplier;
	private CacheRegister cacheRegister;
	private static ScheduledExecutorService keyMaintenanceExecutor;
	private TrafficOpsUtils trafficOpsUtils;
	private boolean dnssecEnabled = false;
	private boolean expiredKeyAllowed = true;
	private Map<String, List<DNSKeyPairWrapper>> keyMap;
	private static ProtectedFetcher fetcher = null;
	private ZoneManager zoneManager;

	public SignatureManager(final ZoneManager zoneManager, final CacheRegister cacheRegister, final TrafficOpsUtils trafficOpsUtils) {
		this.setCacheRegister(cacheRegister);
		this.setTrafficOpsUtils(trafficOpsUtils);
		this.setZoneManager(zoneManager);
		initKeyMap();
	}

	protected void destroy() {
		if (keyMaintenanceExecutor != null) {
			keyMaintenanceExecutor.shutdownNow();
		}
	}

	private void initKeyMap() {
		synchronized(SignatureManager.class) {
			final JSONObject config = cacheRegister.getConfig();

			if (config.optBoolean("dnssec.enabled")) {
				setDnssecEnabled(true);
				setExpiredKeyAllowed(config.optBoolean("dnssec.allow.expired.keys", true)); // allowing this by default is the safest option
				setExpirationMultiplier(config.optInt("signaturemanager.expiration.multiplier", 5)); // signature validity is maxTTL * this
				final ScheduledExecutorService me = Executors.newScheduledThreadPool(1);
				final int maintenanceInterval = config.optInt("keystore.maintenance.interval", 300); // default 300 seconds, do we calculate based on the complimentary settings for key generation in TO?
				me.scheduleWithFixedDelay(getKeyMaintenanceRunnable(cacheRegister), 0, maintenanceInterval, TimeUnit.SECONDS);

				if (keyMaintenanceExecutor != null) {
					keyMaintenanceExecutor.shutdownNow();
				}

				keyMaintenanceExecutor = me;

				try {
					while (keyMap == null) {
						LOGGER.info("Waiting for DNSSEC keyMap initialization to complete");
						Thread.sleep(2000);
					}
				} catch (final InterruptedException e) {
					LOGGER.fatal(e, e);
				}
			} else {
				LOGGER.info("DNSSEC not enabled; to enable, activate DNSSEC for this Traffic Router's CDN in Traffic Ops");
			}
		}
	}

	@SuppressWarnings("PMD.CyclomaticComplexity")
	private Runnable getKeyMaintenanceRunnable(final CacheRegister cacheRegister) {
		return new Runnable() {
			public void run() {
				try {
					final Map<String, List<DNSKeyPairWrapper>> newKeyMap = new HashMap<String, List<DNSKeyPairWrapper>>();
					final JSONObject keyPairData = fetchKeyPairData(cacheRegister);

					if (keyPairData != null) {
						final JSONObject response = keyPairData.getJSONObject("response");
						final Iterator<?> dsIt = response.keys();
						final JSONObject config = cacheRegister.getConfig();
						final long defaultTTL = ZoneUtils.getLong(config.optJSONObject("ttls"), "DNSKEY", 60);

						while (dsIt.hasNext()) {
							final JSONObject keyTypes = response.getJSONObject((String) dsIt.next());
							final Iterator<?> typeIt = keyTypes.keys();

							while (typeIt.hasNext()) {
								final JSONArray keyPairs = keyTypes.getJSONArray((String) typeIt.next());

								for (int i = 0; i < keyPairs.length(); i++) {
									try {
										final JSONObject keyPair = keyPairs.getJSONObject(i);
										final DNSKeyPairWrapper dkpw = new DNSKeyPairWrapper(keyPair, defaultTTL);

										if (!newKeyMap.containsKey(dkpw.getName())) {
											newKeyMap.put(dkpw.getName(), new ArrayList<DNSKeyPairWrapper>());
										}

										final List<DNSKeyPairWrapper> keyList = newKeyMap.get(dkpw.getName());
										keyList.add(dkpw);
										newKeyMap.put(dkpw.getName(),  keyList);

										LOGGER.debug("Added " + dkpw.toString() + " to incoming keyList");
									} catch (JSONException ex) {
										LOGGER.fatal("JSONException caught while parsing key for " + keyPairs.getJSONObject(i), ex);
									} catch (TextParseException ex) {
										LOGGER.fatal(ex, ex);
									} catch (IOException ex) {
										LOGGER.fatal(ex, ex);
									}
								}
							}
						}

						if (keyMap == null) {
							// initial startup
							keyMap = newKeyMap;
						} else if (hasNewKeys(keyMap, newKeyMap)) {
							// incoming key map has new keys
							LOGGER.debug("Found new keys in incoming keyMap; rebuilding zone caches");
							keyMap = newKeyMap;
							getZoneManager().rebuildZoneCache();
						} // no need to overwrite the keymap if they're the same, so no else leg
					} else {
						LOGGER.fatal("Unable to read keyPairData: " + keyPairData);
					}
				} catch (JSONException ex) {
					LOGGER.fatal(ex, ex);
				} catch (RuntimeException ex) {
					LOGGER.fatal("RuntimeException caught while trying to maintain keyMap", ex);
				}
			}
		};
	}

	private boolean hasNewKeys(final Map<String, List<DNSKeyPairWrapper>> keyMap, final Map<String, List<DNSKeyPairWrapper>> newKeyMap) {
		for (final String key : newKeyMap.keySet()) {
			if (!keyMap.containsKey(key)) {
				return true;
			}

			for (final DNSKeyPairWrapper newKeyPair : newKeyMap.get(key)) {
				boolean matched = false;

				for (final DNSKeyPairWrapper keyPair : keyMap.get(key)) {
					if (newKeyPair.equals(keyPair)) {
						matched = true;
						break;
					}
				}

				if (!matched) {
					return true; // has a new key because we didn't find a match
				}
			}
		}

		return false;
	}

	@SuppressWarnings("PMD.CyclomaticComplexity")
	private JSONObject fetchKeyPairData(final CacheRegister cacheRegister) {
		if (!isDnssecEnabled()) {
			return null;
		}

		JSONObject keyPairs = null;

		try {
			final String keyUrl = trafficOpsUtils.getUrl("keystore.api.url", "https://${toHostname}/api/1.1/cdns/name/${cdnName}/dnsseckeys.json");
			final JSONObject config = cacheRegister.getConfig();
			final int timeout = config.optInt("keystore.fetch.timeout", 30 * 1000); // socket timeouts are in ms
			final int retries = config.optInt("keystore.fetch.retries", 5);
			final int wait = config.optInt("keystore.fetch.wait", 5 * 1000); // 5 seconds

			if (fetcher == null) {
				fetcher = new ProtectedFetcher(trafficOpsUtils.getAuthUrl(), trafficOpsUtils.getAuthJSON().toString(), timeout);
			}

			for (int i = 1; i <= retries; i++) {
				try {
					final String content = fetcher.fetch(keyUrl);

					if (content != null) {
						keyPairs = new JSONObject(content);
						break;
					}
				} catch (IOException ex) {
					LOGGER.fatal(ex, ex);
				}

				try {
					Thread.sleep(wait);
				} catch (InterruptedException ex) {
					LOGGER.fatal(ex, ex);
					// break if we're interrupted
					break;
				}
			}
		} catch (JSONException ex) {
			LOGGER.fatal(ex, ex);
		}

		return keyPairs;
	}

	private List<DNSKeyPairWrapper> getZoneSigningKSKPair(final Name name, final long maxTTL) throws IOException, NoSuchAlgorithmException {
		return getZoneSigningKeyPair(name, true, maxTTL);
	}

	private List<DNSKeyPairWrapper> getZoneSigningZSKPair(final Name name, final long maxTTL) throws IOException, NoSuchAlgorithmException {
		return getZoneSigningKeyPair(name, false, maxTTL);
	}

	private List<DNSKeyPairWrapper> getZoneSigningKeyPair(final Name name, final boolean wantKsk, final long maxTTL) throws IOException, NoSuchAlgorithmException {
		/*
		 * This method returns a list, but we will identify the correct key with which to sign the zone.
		 * We select one key (we call this method twice, for zsk and ksks respectively)
		 * to follow the pre-publish key roll methodology described in RFC 6781.
		 * https://tools.ietf.org/html/rfc6781#section-4.1.1.1
		 */

		return getKeyPairs(name, wantKsk, true, maxTTL);
	}

	private List<DNSKeyPairWrapper> getKSKPairs(final Name name, final long maxTTL) throws IOException, NoSuchAlgorithmException {
		return getKeyPairs(name, true, false, maxTTL);
	}

	private List<DNSKeyPairWrapper> getZSKPairs(final Name name, final long maxTTL) throws IOException, NoSuchAlgorithmException {
		return getKeyPairs(name, false, false, maxTTL);
	}

	@SuppressWarnings({"PMD.CyclomaticComplexity", "PMD.NPathComplexity"})
	private List<DNSKeyPairWrapper> getKeyPairs(final Name name, final boolean wantKsk, final boolean wantSigningKey, final long maxTTL) throws IOException, NoSuchAlgorithmException {
		final List<DNSKeyPairWrapper> keyPairs = keyMap.get(name.toString());
		DNSKeyPairWrapper signingKey = null;

		if (keyPairs == null) {
			return null;
		}

		final List<DNSKeyPairWrapper> keys = new ArrayList<DNSKeyPairWrapper>();

		for (final DNSKeyPairWrapper kpw : keyPairs) {
			final DnsKeyPair kp = (DnsKeyPair) kpw;
			final Name kn = kp.getDNSKEYRecord().getName();
			final boolean isKsk = kpw.isKeySigningKey();

			if (kn.equals(name)) {
				if ((isKsk && !wantKsk) || (!isKsk && wantKsk)) {
					LOGGER.debug("Skipping key: wantKsk = " + wantKsk + "; key: " + kpw.toString());
					continue;
				} else if (!wantSigningKey && (isExpiredKeyAllowed() || kpw.isKeyCached(maxTTL))) {
					LOGGER.debug("key selected: " + kpw.toString());
					keys.add(kpw);
				} else if (wantSigningKey) {
					if (!kpw.isUsable()) { // effective date in the future
						LOGGER.debug("Skipping unusable signing key: " + kpw.toString());
						continue;
					} else if (!isExpiredKeyAllowed() && kpw.isExpired()) {
						LOGGER.warn("Unable to use expired signing key: " + kpw.toString());
						continue;
					}

					// Locate the key with the earliest valid effective date accounting for expiration
					if ((isKsk && wantKsk) || (!isKsk && !wantKsk)) {
						if (signingKey == null) {
							signingKey = kpw;
						} else if (signingKey.isExpired() && !kpw.isExpired()) {
							signingKey = kpw;
						} else if (signingKey.isExpired() && kpw.isNewer(signingKey)) {
							signingKey = kpw; // if we have an expired key, try to find the most recent
						} else if (!signingKey.isExpired() && !kpw.isExpired() && kpw.isOlder(signingKey)) {
							signingKey = kpw; // otherwise use the oldest valid/non-expired key
						}
					}
				}
			} else {
				LOGGER.warn("Invalid key for " + name + "; it is intended for " + kpw.toString());
			}
		}

		if (wantSigningKey && signingKey != null) {
			if (signingKey.isExpired()) {
				LOGGER.warn("Using expired signing key: " + signingKey.toString());
			} else {
				LOGGER.debug("Signing key selected: " + signingKey.toString());
			}

			keys.clear(); // in case we have something in here for some reason (shouldn't happen)
			keys.add(signingKey);
		} else if (wantSigningKey && signingKey == null) {
			LOGGER.fatal("Unable to find signing key for " + name);
		}

		return keys;
	}

	private Calendar calculateKeyExpiration(final List<DNSKeyPairWrapper> keyPairs) {
		final Calendar expiration = Calendar.getInstance();
		Date earliest = null;

		for (final DNSKeyPairWrapper keyPair : keyPairs) {
			if (earliest == null) {
				earliest = keyPair.getExpiration();
			} else if (keyPair.getExpiration().before(earliest)) {
				earliest = keyPair.getExpiration();
			}
		}

		expiration.setTime(earliest);

		return expiration;
	}

	private Calendar calculateSignatureExpiration(final long baseTimeInMillis, final List<Record> records) {
		final Calendar expiration = Calendar.getInstance();
		final long maxTTL = ZoneUtils.getMaximumTTL(records) * 1000; // convert TTL to millis
		final long signatureExpiration = baseTimeInMillis + (maxTTL * getExpirationMultiplier());
		expiration.setTimeInMillis(signatureExpiration);

		return expiration;
	}

	public boolean needsRefresh(final ZoneCacheType type, final ZoneKey zoneKey, final int refreshInterval) {
		if (zoneKey instanceof SignedZoneKey) {
			final SignedZoneKey szk = (SignedZoneKey) zoneKey;
			final long now = System.currentTimeMillis();
			final long nextRefresh = now + (refreshInterval * 1000); // refreshInterval is in seconds, convert to millis

			if (nextRefresh >= szk.getRefreshHorizon()) {
				LOGGER.info(getRefreshMessage(type, szk, true, "refresh horizon approaching"));
				return true;
			} else if (!isExpiredKeyAllowed() && now >= szk.getEarliestSigningKeyExpiration()) {
				/*
				 * The earliest signing key has expired, so force a resigning 
				 * which will be done with new keys. This is because the keys themselves
				 * don't have expiry that's tied to DNSSEC; it's administrative, so
				 * we can be a little late on the swap.
				 */
				LOGGER.info(getRefreshMessage(type, szk, true, "signing key expiration"));
				return true;
			} else {
				LOGGER.debug(getRefreshMessage(type, szk));
				return false;
			}
		} else {
			LOGGER.debug(type + ": " + zoneKey.getName() + " is not a signed zone; no refresh needed");
			return false;
		}
	}

	private String getRefreshMessage(final ZoneCacheType type, final SignedZoneKey zoneKey) {
		return getRefreshMessage(type, zoneKey, false, null);
	}

	private String getRefreshMessage(final ZoneCacheType type, final SignedZoneKey zoneKey, final boolean needsRefresh, final String message) {
		final StringBuilder sb = new StringBuilder();
		sb.append(type);
		sb.append(": timestamp for ");
		sb.append(zoneKey.getName());
		sb.append(" is ");
		sb.append(zoneKey.getTimestampDate());
		sb.append("; expires ");
		sb.append(zoneKey.getSignatureExpiration().getTime());

		if (needsRefresh) {
			sb.append("; refresh needed");
		} else {
			sb.append("; no refresh needed");
		}

		if (message != null) {
			sb.append("; ");
			sb.append(message);
		}

		return sb.toString();
	}

	@SuppressWarnings("unchecked")
	protected List<Record> signZone(final Name name, final List<Record> records, final SignedZoneKey zoneKey) throws IOException, GeneralSecurityException {
		final long maxTTL = ZoneUtils.getMaximumTTL(records);
		final List<? extends DnsKeyPair> kskPairs = getZoneSigningKSKPair(name, maxTTL);
		final List<? extends DnsKeyPair> zskPairs = getZoneSigningZSKPair(name, maxTTL);

		// TODO: do we really need to fully sign the apex keyset? should the digest be config driven?
		if (kskPairs != null && zskPairs != null) {
			if (!kskPairs.isEmpty() && !zskPairs.isEmpty()) {
				final Calendar signatureExpiration = calculateSignatureExpiration(zoneKey.getTimestamp(), records);
				final Calendar kskExpiration = calculateKeyExpiration((List<DNSKeyPairWrapper>) kskPairs);
				final Calendar zskExpiration = calculateKeyExpiration((List<DNSKeyPairWrapper>) zskPairs);
				final JCEDnsSecSigner signer = new JCEDnsSecSigner(false);
				final long now = System.currentTimeMillis();
				final Calendar start = Calendar.getInstance();

				start.setTimeInMillis(now);
				start.add(Calendar.HOUR, -1);

				LOGGER.info("Signing zone " + name + " with start " + start.getTime() + " and expiration " + signatureExpiration.getTime());
				final List<Record> signedRecords = signer.signZone(name, records, (List<DnsKeyPair>) kskPairs, (List<DnsKeyPair>) zskPairs, start.getTime(), signatureExpiration.getTime(), true, DSRecord.SHA256_DIGEST_ID);
				zoneKey.setSignatureExpiration(signatureExpiration);
				zoneKey.setKSKExpiration(kskExpiration);
				zoneKey.setZSKExpiration(zskExpiration);

				return signedRecords;
			} else {
				LOGGER.warn("Unable to sign zone " + name + "; have " + kskPairs.size() + " KSKs and " + zskPairs.size() + " ZSKs");
			}
		} else {
			LOGGER.warn("Unable to sign zone " + name + "; ksks or zsks are null");
		}

		return records;
	}

	public List<Record> generateDSRecords(final Name name, final long maxTTL) throws NoSuchAlgorithmException, IOException {
		final List<Record> records = new ArrayList<Record>();

		if (isDnssecEnabled() && name.subdomain(ZoneManager.getTopLevelDomain())) {
			final JSONObject config = getCacheRegister().getConfig();
			final List<DNSKeyPairWrapper> kskPairs = getKSKPairs(name, maxTTL);
			final List<DNSKeyPairWrapper> zskPairs = getZSKPairs(name, maxTTL);

			if (kskPairs != null && zskPairs != null && !kskPairs.isEmpty() && !zskPairs.isEmpty()) {
				// these records go into the CDN TLD, so don't use the DS' TTLs; use the CDN's.
				final Long dsTtl = ZoneUtils.getLong(config.optJSONObject("ttls"), "DS", 60);

				for (final DnsKeyPair kp : kskPairs) {
					final DSRecord dsRecord = SignUtils.calculateDSRecord(kp.getDNSKEYRecord(), DSRecord.SHA256_DIGEST_ID, dsTtl);
					LOGGER.debug(name + ": adding DS record " + dsRecord);
					records.add(dsRecord);
				}
			}
		}

		return records;
	}

	public List<Record> generateDNSKEYRecords(final Name name, final long maxTTL) throws NoSuchAlgorithmException, IOException {
		final List<Record> list = new ArrayList<Record>();

		if (isDnssecEnabled() && name.subdomain(ZoneManager.getTopLevelDomain())) {
			final List<DNSKeyPairWrapper> kskPairs = getKSKPairs(name, maxTTL);
			final List<DNSKeyPairWrapper> zskPairs = getZSKPairs(name, maxTTL);

			if (kskPairs != null && zskPairs != null && !kskPairs.isEmpty() && !zskPairs.isEmpty()) {
				for (final DnsKeyPair kp : kskPairs) {
					LOGGER.debug(name + ": DNSKEY record " + kp.getDNSKEYRecord());
					list.add(kp.getDNSKEYRecord());
				}

				for (final DnsKeyPair kp : zskPairs) {
					// TODO: make adding zsk to parent zone configurable?
					LOGGER.debug(name + ": DNSKEY record " + kp.getDNSKEYRecord());
					list.add(kp.getDNSKEYRecord());
				}
			}
		}

		return list;
	}

	// this method is called during static zone generation
	public ZoneKey generateZoneKey(final Name name, final List<Record> list) {
		return generateZoneKey(name, list, false, false);
	}

	public ZoneKey generateDynamicZoneKey(final Name name, final List<Record> list, final boolean dnssecRequest) {
		return generateZoneKey(name, list, true, dnssecRequest);
	}

	private ZoneKey generateZoneKey(final Name name, final List<Record> list, final boolean dynamicRequest, final boolean dnssecRequest) {
		if (dynamicRequest && !dnssecRequest) {
			return new ZoneKey(name, list);
		} else if ((isDnssecEnabled(name) && name.subdomain(ZoneManager.getTopLevelDomain()))) {
			return new SignedZoneKey(name, list);
		} else {
			return new ZoneKey(name, list);
		}
	}

	protected boolean isDnssecEnabled() {
		return dnssecEnabled;
	}

	private boolean isDnssecEnabled(final Name name) {
		return dnssecEnabled && keyMap.containsKey(name.toString());
	}

	private void setDnssecEnabled(final boolean dnssecEnabled) {
		this.dnssecEnabled = dnssecEnabled;
	}

	protected CacheRegister getCacheRegister() {
		return cacheRegister;
	}

	private void setCacheRegister(final CacheRegister cacheRegister) {
		this.cacheRegister = cacheRegister;
	}

	public int getExpirationMultiplier() {
		return expirationMultiplier;
	}

	public void setExpirationMultiplier(final int expirationMultiplier) {
		this.expirationMultiplier = expirationMultiplier;
	}

	private ZoneManager getZoneManager() {
		return zoneManager;
	}

	private void setZoneManager(final ZoneManager zoneManager) {
		this.zoneManager = zoneManager;
	}

	private void setTrafficOpsUtils(final TrafficOpsUtils trafficOpsUtils) {
		this.trafficOpsUtils = trafficOpsUtils;
	}

	public boolean isExpiredKeyAllowed() {
		return expiredKeyAllowed;
	}

	public void setExpiredKeyAllowed(final boolean expiredKeyAllowed) {
		this.expiredKeyAllowed = expiredKeyAllowed;
	}
}