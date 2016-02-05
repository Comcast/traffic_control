/*
 * Copyright 2015 Cisco Systems, Inc.
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

package com.comcast.cdn.traffic_control.traffic_router.core.loc;

import java.io.File;
import java.io.FileReader;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;
import java.util.HashSet;
import java.util.regex.Pattern;
import java.net.MalformedURLException;
import java.net.URL;

import org.apache.log4j.Logger;
import org.apache.wicket.ajax.json.JSONArray;
import org.apache.wicket.ajax.json.JSONException;
import org.apache.wicket.ajax.json.JSONObject;
import org.apache.wicket.ajax.json.JSONTokener;

import com.comcast.cdn.traffic_control.traffic_router.core.cache.Cache;
import com.comcast.cdn.traffic_control.traffic_router.core.ds.DeliveryService;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.RegionalGeoResult.RegionalGeoResultType;
import com.comcast.cdn.traffic_control.traffic_router.core.request.HTTPRequest;
import com.comcast.cdn.traffic_control.traffic_router.core.request.Request;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.ResultType;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.ResultDetails;
import com.comcast.cdn.traffic_control.traffic_router.core.router.TrafficRouter;
import com.comcast.cdn.traffic_control.traffic_router.core.router.HTTPRouteResult;

import static com.comcast.cdn.traffic_control.traffic_router.core.loc.RegionalGeoResult.RegionalGeoResultType.*;


public final class RegionalGeo {
    private static final Logger LOGGER = Logger.getLogger(RegionalGeo.class);
    public static final String HTTP_SCHEME = "http://";
    private boolean fallback = false;
    private final Map<String, RegionalGeoDsvc> regionalGeoDsvcs = new HashMap<String, RegionalGeoDsvc>();

    private static RegionalGeo currentConfig = new RegionalGeo();

    private RegionalGeo() {

    }

    public void setFallback(final boolean fallback) {
        this.fallback = fallback;
    }

    public boolean isFallback() {
        return fallback;
    }

    private RegionalGeoRule matchRule(final String dsvcId, final String url) {

        final RegionalGeoDsvc regionalGeoDsvc = regionalGeoDsvcs.get(dsvcId);
        if (regionalGeoDsvc == null) {
            LOGGER.debug("RegionalGeo: dsvc not found: " + dsvcId);
            return null;
        }

        final RegionalGeoRule rule = regionalGeoDsvc.matchRule(url);
        if (rule == null) {
            LOGGER.debug("RegionalGeo: no rule match for dsvc "
                         + dsvcId + " with url " + url);
            return null;
        }

        return rule;
    }

    private boolean addRule(final String dsvcId, final String urlRegex,
            final RegionalGeoRule.PostalsType postalsType, final Set<String> postals,
            final NetworkNode networkRoot, final String alternateUrl) {

        // Loop check for alternateUrl with fqdn against the regex before adding
        Pattern urlRegexPattern;

        try {
            LOGGER.info("RegionalGeo: compile regex for url " + urlRegex);
            urlRegexPattern = Pattern.compile(urlRegex, Pattern.CASE_INSENSITIVE);
        } catch (Exception e) {
            LOGGER.error("RegionalGeo ERR: Pattern.compile exception", e);
            return false;
        }

        if (alternateUrl.toLowerCase().startsWith(HTTP_SCHEME)
            && urlRegexPattern.matcher(alternateUrl).matches()) {
            LOGGER.error("RegionalGeo ERR: possible LOOP detected, alternate fqdn url " + alternateUrl
                         + " matches regex " + urlRegex + " in dsvc " +  dsvcId);
            return false;
        }

        RegionalGeoDsvc regionalGeoDsvc = regionalGeoDsvcs.get(dsvcId);
        if (regionalGeoDsvc == null) {
            regionalGeoDsvc = new RegionalGeoDsvc(dsvcId);
            regionalGeoDsvcs.put(dsvcId, regionalGeoDsvc);
        }

        final RegionalGeoRule urlRule = new RegionalGeoRule(regionalGeoDsvc,
                urlRegex, urlRegexPattern,
                postalsType, postals,
                networkRoot, alternateUrl);

        LOGGER.info("RegionalGeo: adding " + urlRule);
        regionalGeoDsvc.addRule(urlRule);
        return true;
    }

    /// static methods
    private static NetworkNode parseWhiteListJson(final JSONArray json)
        throws JSONException, NetworkNodeException {

        final NetworkNode.SuperNode root = new NetworkNode.SuperNode();

        for (int j = 0; j < json.length(); j++) {
            final String subnet = json.getString(j);
            final NetworkNode node = new NetworkNode(subnet, RegionalGeoRule.WHITE_LIST_NODE_LOCATION);

            if (subnet.indexOf(':') == -1) { // ipv4 or ipv6
                root.add(node);
            } else {
                root.add6(node);
            }
        }

        return root;
    }

    private static RegionalGeoRule.PostalsType parseLocationJson(final JSONObject locationJson,
        final Set<String> postals) throws JSONException {

        RegionalGeoRule.PostalsType postalsType = RegionalGeoRule.PostalsType.UNDEFINED;
        JSONArray postalsJson = locationJson.optJSONArray("includePostalCode");
        
        if (postalsJson != null) {
            postalsType = RegionalGeoRule.PostalsType.INCLUDE;
        } else {
            postalsJson = locationJson.optJSONArray("excludePostalCode");
            if (postalsJson == null) {
                LOGGER.error("RegionalGeo ERR: no include/exclude in geolocation");
                return RegionalGeoRule.PostalsType.UNDEFINED;
            }
        
            postalsType = RegionalGeoRule.PostalsType.EXCLUDE;
        }

        for (int j = 0; j < postalsJson.length(); j++) {
            postals.add(postalsJson.getString(j));
        }
        return postalsType;

    }

    private static RegionalGeo parseConfigJson(final JSONObject json) {

        final RegionalGeo regionalGeo = new RegionalGeo();
        regionalGeo.setFallback(true);
        try {
            final JSONArray dsvcsJson = json.getJSONArray("deliveryServices");
            LOGGER.info("RegionalGeo: parse json with rule count " + dsvcsJson.length());

            for (int i = 0; i < dsvcsJson.length(); i++) {
                final JSONObject ruleJson = dsvcsJson.getJSONObject(i);

                final String dsvcId = ruleJson.getString("deliveryServiceId");
                if (dsvcId.trim().isEmpty()) {
                    LOGGER.error("RegionalGeo ERR: deliveryServiceId empty");
                    return null;
                }

                final String urlRegex = ruleJson.getString("urlRegex");
                if (urlRegex.trim().isEmpty()) {
                    LOGGER.error("RegionalGeo ERR: urlRegex empty");
                    return null;
                }

                final String redirectUrl = ruleJson.getString("redirectUrl");
                if (redirectUrl.trim().isEmpty()) {
                    LOGGER.error("RegionalGeo ERR: redirectUrl empty");
                    return null;
                }

                // FSAs (postal codes)
                final JSONObject locationJson = ruleJson.getJSONObject("geoLocation");
                final Set<String> postals = new HashSet<String>();
                final RegionalGeoRule.PostalsType postalsType = parseLocationJson(locationJson, postals);
                if (postalsType == RegionalGeoRule.PostalsType.UNDEFINED) {
                    LOGGER.error("RegionalGeo ERR: geoLocation empty");
                    return null;
                }

                // white list
                NetworkNode whiteListRoot = null;
                final JSONArray whiteListJson = ruleJson.optJSONArray("ipWhiteList");
                if (whiteListJson != null) {
                    whiteListRoot = parseWhiteListJson(whiteListJson);
                }

                // add the rule
                if (!regionalGeo.addRule(dsvcId, urlRegex, postalsType, postals, whiteListRoot, redirectUrl)) {
                    LOGGER.error("RegionalGeo ERR: add rule failed on parsing json file");
                    return null;
                }
            }

            regionalGeo.setFallback(false);
            return regionalGeo;
        } catch (Exception e) {
            LOGGER.error("RegionalGeo ERR: parse json file with exception", e);
        }

        return null;
    }

    public static boolean parseConfigFile(final File f) {
        JSONObject json = null;
        try {
            json = new JSONObject(new JSONTokener(new FileReader(f)));
        } catch (Exception e) {
            LOGGER.error("RegionalGeo ERR: json file exception " + f, e);
            currentConfig.setFallback(true);
            return false;
        }

        final RegionalGeo regionalGeo = parseConfigJson(json);
        if (regionalGeo== null) {
            currentConfig.setFallback(true);
            return false;
        }
        
        currentConfig = regionalGeo; // point to the new parsed object
        currentConfig.setFallback(false);
        LOGGER.debug("RegionalGeo: create instance from new json");
        return true;
    }

    public static RegionalGeoResult enforce(final String dsvcId, final String url,
        final String ip, final String postalCode) {

        final RegionalGeoResult result = new RegionalGeoResult();
        boolean allowed = false;
        RegionalGeoRule rule = null;

        result.setPostal(postalCode);
        result.setUsingFallbackConfig(currentConfig.isFallback());
        result.setAllowedByWhiteList(false);

        rule = currentConfig.matchRule(dsvcId, url);
        if (rule == null) {
            result.setHttpResponseCode(RegionalGeoResult.REGIONAL_GEO_DENIED_HTTP_CODE);
            result.setType(DENIED);
            LOGGER.debug("RegionalGeo: denied for dsvc " + dsvcId
                         + ", url " + url + ", postal " + postalCode);
            return result;
        }

        // first match whitelist, then FSA (postal)
        if (rule.isIpInWhiteList(ip)) {
            LOGGER.debug("RegionalGeo: allowing ip in whitelist");
            allowed = true;
            result.setAllowedByWhiteList(true);
        } else {
            if (postalCode == null || postalCode.isEmpty()) {
                LOGGER.warn("RegionalGeo: alternate a request with null or empty postal");
                allowed = false;
            } else {
                allowed = rule.isAllowedPostal(postalCode);
            }
        }

        final String alternateUrl = rule.getAlternateUrl();
        result.setRuleType(rule.getPostalsType());

        if (allowed) {
            result.setUrl(url);
            result.setType(ALLOWED);
        } else {
            // For a disallowed client, if alternateUrl starts with "http://"
            // just redirect the client to this url without any cache selection;
            // if alternateUrl only has path and file name like "/path/abc.html",
            // then cache selection process will be needed, and hostname will be
            // added to make it like "http://cache01.example.com/path/abc.html" later.
            if (alternateUrl.toLowerCase().startsWith(HTTP_SCHEME)) {
                result.setUrl(alternateUrl);
                result.setType(ALTERNATE_WITHOUT_CACHE);
            } else {
                String redirectUrl;
                if (alternateUrl.startsWith("/")) { // add a '/' prefix if necessary for url path
                    redirectUrl = alternateUrl;
                } else {
                    redirectUrl = "/" + alternateUrl;
                }

                LOGGER.debug("RegionalGeo: alternate with cache url " + redirectUrl);
                result.setUrl(redirectUrl);
                result.setType(ALTERNATE_WITH_CACHE);
            }
        }

        LOGGER.debug("RegionalGeo: result " + result + " for dsvc " + dsvcId + ", url " + url + ", ip " + ip);

        return result;
    }

    public static void enforce(final TrafficRouter trafficRouter, final Request request,
        final DeliveryService deliveryService, final Cache cache,
        final HTTPRouteResult routeResult, final Track track) throws MalformedURLException {

        LOGGER.debug("RegionalGeo: enforcing");

        Geolocation clientGeolocation = null;
        try {
            clientGeolocation = trafficRouter.getClientGeolocation(request, track);
        } catch (GeolocationException e) {
            LOGGER.warn("RegionalGeo: failed looking up Client GeoLocation: " + e.getMessage());
        }

        String postalCode = null;
        if (clientGeolocation != null) {
            postalCode = clientGeolocation.getPostalCode();

            // Get the first 3 chars in the postal code. These 3 chars are called FSA in Canadian postal codes.
            if (postalCode != null && postalCode.length() > 3) {
                postalCode = postalCode.substring(0, 3);
            }
        }

        final HTTPRequest httpRequest = HTTPRequest.class.cast(request);
        final RegionalGeoResult result = enforce(deliveryService.getId(), httpRequest.getRequestedUrl(), 
                                                 httpRequest.getClientIP(), postalCode);

        updateTrack(track, result);

        if (result.getType() == DENIED) {
            routeResult.setResponseCode(result.getHttpResponseCode());
        } else {
            routeResult.setUrl(new URL(createRedirectURIString(httpRequest, deliveryService, cache, result)));
        }
    }


    private static void updateTrack(final Track track, final RegionalGeoResult regionalGeoResult) {
        track.setRegionalGeoResult(regionalGeoResult);

        final RegionalGeoResultType resultType = regionalGeoResult.getType();

        if (resultType == DENIED) {
            track.setResult(ResultType.RGDENY);
            track.setResultDetails(ResultDetails.REGIONAL_GEO_NO_RULE);
            return;
        }

        if (resultType == ALTERNATE_WITH_CACHE) {
            track.setResult(ResultType.RGALT);
            track.setResultDetails(ResultDetails.REGIONAL_GEO_ALTERNATE_WITH_CACHE);
            return;
        }

        if (resultType == ALTERNATE_WITHOUT_CACHE) {
            track.setResult(ResultType.RGALT);
            track.setResultDetails(ResultDetails.REGIONAL_GEO_ALTERNATE_WITHOUT_CACHE);
            return;
        }

        // else ALLOWED, result & resultDetail shall be normal case, do not modify
    }   

    private static String createRedirectURIString(final HTTPRequest request, final DeliveryService deliveryService, 
        final Cache cache, final RegionalGeoResult regionalGeoResult) {

        if (regionalGeoResult.getType() == ALLOWED) {
            return deliveryService.createURIString(request, cache);
        }

        if (regionalGeoResult.getType() == ALTERNATE_WITH_CACHE) {
            return deliveryService.createURIString(request, regionalGeoResult.getUrl(), cache);
        }

        if (regionalGeoResult.getType() == ALTERNATE_WITHOUT_CACHE) {
            return regionalGeoResult.getUrl();
        }

        return null; // DENIED
    }
}

