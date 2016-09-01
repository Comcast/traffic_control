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

import com.comcast.cdn.traffic_control.traffic_router.core.cache.Cache;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheLocation;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheRegister;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.InetRecord;
import com.comcast.cdn.traffic_control.traffic_router.core.ds.DeliveryService;
import com.comcast.cdn.traffic_control.traffic_router.core.ds.Dispersion;
import com.comcast.cdn.traffic_control.traffic_router.core.ds.SteeringRegistry;
import com.comcast.cdn.traffic_control.traffic_router.core.hash.ConsistentHasher;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.FederationRegistry;
import com.comcast.cdn.traffic_control.traffic_router.geolocation.Geolocation;
import com.comcast.cdn.traffic_control.traffic_router.core.request.DNSRequest;
import com.comcast.cdn.traffic_control.traffic_router.core.request.HTTPRequest;
import com.comcast.cdn.traffic_control.traffic_router.core.request.Request;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track;
import com.comcast.cdn.traffic_control.traffic_router.core.util.CidrAddress;
import com.comcast.cdn.traffic_control.traffic_router.keystore.KeyStoreHelper;
import org.junit.Before;
import org.junit.Test;
import org.xbill.DNS.Type;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.Vector;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.equalTo;
import static org.mockito.Matchers.any;
import static org.mockito.Matchers.anyBoolean;
import static org.mockito.Matchers.anyString;
import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.powermock.reflect.Whitebox.setInternalState;

public class TrafficRouterTest {
    private ConsistentHasher consistentHasher;
    private TrafficRouter trafficRouter;

    private DeliveryService deliveryService;
    private FederationRegistry federationRegistry;

    @Before
    public void before() throws Exception {
        deliveryService = mock(DeliveryService.class);
        when(deliveryService.isAvailable()).thenReturn(true);
        when(deliveryService.isCoverageZoneOnly()).thenReturn(false);
        when(deliveryService.getDispersion()).thenReturn(mock(Dispersion.class));
        when(deliveryService.isAcceptHttp()).thenReturn(true);

        consistentHasher = mock(ConsistentHasher.class);

        when(deliveryService.createURIString(any(HTTPRequest.class), any(Cache.class))).thenReturn("http://atscache.kabletown.net/index.html");

        List<InetRecord> inetRecords = new ArrayList<InetRecord>();
        InetRecord inetRecord = new InetRecord("cname1", 12345);
        inetRecords.add(inetRecord);

        federationRegistry = mock(FederationRegistry.class);
        when(federationRegistry.findInetRecords(anyString(), any(CidrAddress.class))).thenReturn(inetRecords);

        trafficRouter = mock(TrafficRouter.class);

        CacheRegister cacheRegister = mock(CacheRegister.class);
        when(cacheRegister.getDeliveryService(any(HTTPRequest.class), eq(true))).thenReturn(deliveryService);

        setInternalState(trafficRouter, "cacheRegister", cacheRegister);
        setInternalState(trafficRouter, "federationRegistry", federationRegistry);
        setInternalState(trafficRouter, "consistentHasher", consistentHasher);
        setInternalState(trafficRouter, "steeringRegistry", mock(SteeringRegistry.class));
        KeyStoreHelper keyStoreHelper = mock(KeyStoreHelper.class);
        when(keyStoreHelper.getAliases()).thenReturn(new Vector<String>().elements());
        setInternalState(trafficRouter, "keyStoreHelper", keyStoreHelper);


        when(trafficRouter.route(any(DNSRequest.class), any(Track.class))).thenCallRealMethod();
        when(trafficRouter.route(any(HTTPRequest.class), any(Track.class))).thenCallRealMethod();
        when(trafficRouter.selectDeliveryService(any(Request.class), anyBoolean())).thenReturn(deliveryService);
        when(trafficRouter.consistentHashDeliveryService(any(DeliveryService.class), anyString(), anyString())).thenCallRealMethod();
    }

    @Test
    public void itCreatesDnsResultsFromFederationMappingHit() throws Exception {
        DNSRequest request = new DNSRequest();
        request.setClientIP("192.168.10.11");
        request.setHostname("edge.example.com");

        Track track = spy(StatTracker.getTrack());

        DNSRouteResult result = trafficRouter.route(request, track);

        assertThat(result.getAddresses(), containsInAnyOrder(new InetRecord("cname1", 12345)));
        verify(track).setRouteType(Track.RouteType.DNS, "edge.example.com");
    }

    @Test
    public void itCreatesHttpResults() throws Exception {
        HTTPRequest httpRequest = new HTTPRequest();
        httpRequest.setClientIP("192.168.10.11");
        httpRequest.setHostname("ccr.example.com");

        Track track = spy(StatTracker.getTrack());

        Cache cache = mock(Cache.class);
        when(cache.hasDeliveryService(anyString())).thenReturn(true);
        CacheLocation cacheLocation = new CacheLocation("", new Geolocation(50,50));

        cacheLocation.addCache(cache);

        Set<CacheLocation> cacheLocationCollection = new HashSet<CacheLocation>();
        cacheLocationCollection.add(cacheLocation);

        CacheRegister cacheRegister = mock(CacheRegister.class);
        when(cacheRegister.getCacheLocations()).thenReturn(cacheLocationCollection);

        when(deliveryService.filterAvailableLocations(any(Collection.class))).thenCallRealMethod();
        when(deliveryService.isLocationAvailable(cacheLocation)).thenReturn(true);

        List<Cache> caches = new ArrayList<Cache>();
        caches.add(cache);
        when(trafficRouter.selectCaches(any(Request.class), any(DeliveryService.class), any(Track.class))).thenReturn(caches);
        when(trafficRouter.selectCachesByGeo(anyString(), any(DeliveryService.class), any(CacheLocation.class), any(Track.class))).thenCallRealMethod();
        when(trafficRouter.getClientLocation(anyString(), any(DeliveryService.class), any(CacheLocation.class), any(Track.class))).thenReturn(new Geolocation(40, -100));
        when(trafficRouter.getCachesByGeo(any(DeliveryService.class), any(Geolocation.class), any(Track.class))).thenCallRealMethod();
        when(trafficRouter.getCacheRegister()).thenReturn(cacheRegister);
        when(trafficRouter.orderCacheLocations(any(List.class), any(Geolocation.class))).thenCallRealMethod();

        HTTPRouteResult httpRouteResult = trafficRouter.route(httpRequest, track);

        assertThat(httpRouteResult.getUrl().toString(), equalTo("http://atscache.kabletown.net/index.html"));
    }

    @Test
    public void itSetsResultToGeo() throws Exception {
        Cache cache = mock(Cache.class);
        when(cache.hasDeliveryService(anyString())).thenReturn(true);
        CacheLocation cacheLocation = new CacheLocation("", new Geolocation(50,50));

        cacheLocation.addCache(cache);

        Set<CacheLocation> cacheLocationCollection = new HashSet<CacheLocation>();
        cacheLocationCollection.add(cacheLocation);

        CacheRegister cacheRegister = mock(CacheRegister.class);
        when(cacheRegister.getCacheLocations()).thenReturn(cacheLocationCollection);

        when(trafficRouter.getCacheRegister()).thenReturn(cacheRegister);
        when(deliveryService.isLocationAvailable(cacheLocation)).thenReturn(true);
        when(deliveryService.filterAvailableLocations(any(Collection.class))).thenCallRealMethod();

        when(trafficRouter.selectCaches(any(Request.class), any(DeliveryService.class), any(Track.class))).thenCallRealMethod();
        when(trafficRouter.selectCachesByGeo(anyString(), any(DeliveryService.class), any(CacheLocation.class), any(Track.class))).thenCallRealMethod();

        Geolocation clientLocation = new Geolocation(40, -100);
        when(trafficRouter.getClientLocation(anyString(), any(DeliveryService.class), any(CacheLocation.class), any(Track.class))).thenReturn(clientLocation);

        when(trafficRouter.getCachesByGeo(any(DeliveryService.class), any(Geolocation.class), any(Track.class))).thenCallRealMethod();
        when(trafficRouter.orderCacheLocations(any(List.class), any(Geolocation.class))).thenCallRealMethod();
        when(trafficRouter.getSupportingCaches(any(List.class), any(DeliveryService.class))).thenCallRealMethod();

        HTTPRequest httpRequest = new HTTPRequest();
        httpRequest.setClientIP("192.168.10.11");
        httpRequest.setHostname("ccr.example.com");
        httpRequest.setPath("/some/path");

        Track track = spy(StatTracker.getTrack());

        trafficRouter.route(httpRequest, track);

        assertThat(track.getResult(), equalTo(Track.ResultType.GEO));
        assertThat(track.getResultLocation(), equalTo(new Geolocation(50, 50)));

        when(federationRegistry.findInetRecords(anyString(), any(CidrAddress.class))).thenReturn(null);

        DNSRequest dnsRequest = new DNSRequest();
        dnsRequest.setClientIP("192.168.1.2");
        dnsRequest.setClientIP("10.10.10.10");
        dnsRequest.setQtype(Type.A);

        track = StatTracker.getTrack();
        trafficRouter.route(dnsRequest, track);

        assertThat(track.getResult(), equalTo(Track.ResultType.GEO));
        assertThat(track.getResultLocation(), equalTo(new Geolocation(50, 50)));
    }

    @Test
    public void itRetainsPathElementsInURI() throws Exception {
        Cache cache = mock(Cache.class);
        when(cache.getFqdn()).thenReturn("atscache-01.kabletown.net");
        when(cache.getPort()).thenReturn(80);

        when(deliveryService.createURIString(any(HTTPRequest.class), any(Cache.class))).thenCallRealMethod();

        HTTPRequest httpRequest = new HTTPRequest();
        httpRequest.setClientIP("192.168.10.11");
        httpRequest.setHostname("tr.ds.kabletown.net");
        httpRequest.setPath("/782-93d215fcd88b/6b6ce2889-ae4c20a1584.ism/manifest(format=m3u8-aapl).m3u8");
        httpRequest.setUri("/782-93d215fcd88b/6b6ce2889-ae4c20a1584.ism;urlsig=O0U9MTQ1Ojhx74tjchm8yzfdanshdafHMNhv8vNA/manifest(format=m3u8-aapl).m3u8");

        StringBuilder dest = new StringBuilder();
        dest.append("http://");
        dest.append(cache.getFqdn().split("\\.", 2)[0]);
        dest.append(".");
        dest.append(httpRequest.getHostname().split("\\.", 2)[1]);
        dest.append(httpRequest.getUri());

        assertThat(deliveryService.createURIString(httpRequest, cache), equalTo(dest.toString()));
    }
}
