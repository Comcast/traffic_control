package com.comcast.cdn.traffic_control.traffic_router.core.router;

import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheLocation;
import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheRegister;
import com.comcast.cdn.traffic_control.traffic_router.core.ds.DeliveryService;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.FederationRegistry;
import com.comcast.cdn.traffic_control.traffic_router.core.loc.RegionalGeoResult;
import com.comcast.cdn.traffic_control.traffic_router.core.request.DNSRequest;
import com.comcast.cdn.traffic_control.traffic_router.core.request.Request;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.ResultType;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.ResultDetails;

import com.comcast.cdn.traffic_control.traffic_router.core.util.CidrAddress;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.powermock.core.classloader.annotations.PrepareForTest;
import org.powermock.modules.junit4.PowerMockRunner;
import org.powermock.reflect.Whitebox;
import org.xbill.DNS.Name;
import org.xbill.DNS.Type;

import static org.mockito.Mockito.*;
import static org.powermock.api.mockito.PowerMockito.doCallRealMethod;
import static org.powermock.api.mockito.PowerMockito.spy;
import static org.powermock.reflect.Whitebox.setInternalState;

@RunWith(PowerMockRunner.class)
@PrepareForTest({DeliveryService.class, TrafficRouter.class})
public class DNSRoutingMissesTest {

    private DNSRequest request;
    private TrafficRouter trafficRouter;
    private Track track;

    @Before
    public void before() throws Exception {
        request = new DNSRequest();

        request.setClientIP("192.168.34.56");
        request.setHostname(Name.fromString("edge.foo-img.kabletown.com").relativize(Name.root).toString());
        request.setQtype(Type.A);

        FederationRegistry federationRegistry = mock(FederationRegistry.class);
        when(federationRegistry.findInetRecords(anyString(), any(CidrAddress.class))).thenReturn(null);

        trafficRouter = mock(TrafficRouter.class);
        when(trafficRouter.getCacheRegister()).thenReturn(mock(CacheRegister.class));
        Whitebox.setInternalState(trafficRouter, "federationRegistry", federationRegistry);
        when(trafficRouter.selectCachesByGeo(any(Request.class), any(DeliveryService.class), any(CacheLocation.class), any(Track.class), any(RegionalGeoResult.class))).thenCallRealMethod();

        track = spy(StatTracker.getTrack());
        doCallRealMethod().when(trafficRouter).route(request, track);
    }

    @Test
    public void itSetsDetailsWhenNoDeliveryService() throws Exception {
        trafficRouter.route(request, track);

        verify(track).setResult(ResultType.STATIC_ROUTE);
        verify(track).setResultDetails(ResultDetails.DS_NOT_FOUND);
    }

    // When the delivery service is unavailable ...
    @Test
    public void itSetsDetailsWhenNoBypass() throws Exception {
        DeliveryService deliveryService = mock(DeliveryService.class);
        when(deliveryService.isAvailable()).thenReturn(false);
        when(deliveryService.getFailureDnsResponse(request, track)).thenCallRealMethod();

        doReturn(deliveryService).when(trafficRouter).selectDeliveryService(request, false);

        trafficRouter.route(request, track);

        verify(track).setResult(ResultType.MISS);
        verify(track).setResultDetails(ResultDetails.DS_NO_BYPASS);
    }

    @Test
    public void itSetsDetailsWhenBypassDestination() throws Exception {
        DeliveryService deliveryService = mock(DeliveryService.class);
        when(deliveryService.isAvailable()).thenReturn(false);
        when(deliveryService.getFailureDnsResponse(request, track)).thenCallRealMethod();

        doReturn(deliveryService).when(trafficRouter).selectDeliveryService(request, false);

        JSONObject bypassDestination = mock(JSONObject.class);
        when(bypassDestination.optJSONObject("DNS")).thenReturn(null);

        setInternalState(deliveryService, "bypassDestination", bypassDestination);

        trafficRouter.route(request, track);

        verify(track).setResult(ResultType.DS_REDIRECT);
        verify(track).setResultDetails(ResultDetails.DS_BYPASS);
    }

    // The Delivery Service is available but we don't find the cache in the coverage zone map

    // - and DS doesn't support other lookups
    @Test
    public void itSetsDetailsAboutMissesWhenOnlyCoverageZoneSupported() throws Exception {
        DeliveryService deliveryService = mock(DeliveryService.class);
        doReturn(true).when(deliveryService).isAvailable();

        when(deliveryService.isCoverageZoneOnly()).thenReturn(true);

        doReturn(deliveryService).when(trafficRouter).selectDeliveryService(any(Request.class), anyBoolean());
        trafficRouter.route(request, track);

        verify(track).setResult(ResultType.MISS);
        verify(track).setResultDetails(ResultDetails.DS_CZ_ONLY);
    }

    // 1. We got an unsupported cache location from the coverage zone map
    // 2. we looked up the client location from maxmind
    // 3. delivery service says the client location is unsupported
    @Test
    public void itSetsDetailsWhenClientGeolocationNotSupported() throws Exception {
        DeliveryService deliveryService = mock(DeliveryService.class);
        doReturn(true).when(deliveryService).isAvailable();

        when(deliveryService.isCoverageZoneOnly()).thenReturn(false);

        doReturn(deliveryService).when(trafficRouter).selectDeliveryService(request, false);

        trafficRouter.route(request, track);

        verify(track).setResult(ResultType.MISS);
        verify(track).setResultDetails(ResultDetails.DS_CLIENT_GEO_UNSUPPORTED);

    }

    @Test
    public void itSetsDetailsWhenCacheNotFoundByGeolocation() throws Exception {
        doCallRealMethod().when(trafficRouter).selectCachesByGeo(any(Request.class), any(DeliveryService.class), any(CacheLocation.class), any(Track.class), any(RegionalGeoResult.class));
        CacheLocation cacheLocation = mock(CacheLocation.class);
        CacheRegister cacheRegister = mock(CacheRegister.class);

        DeliveryService deliveryService = mock(DeliveryService.class);
        doReturn(true).when(deliveryService).isAvailable();
        when(deliveryService.isLocationAvailable(cacheLocation)).thenReturn(false);
        when(deliveryService.isCoverageZoneOnly()).thenReturn(false);

        doReturn(deliveryService).when(trafficRouter).selectDeliveryService(request, false);
        doReturn(cacheLocation).when(trafficRouter).getCoverageZoneCache("192.168.34.56");
        doReturn(cacheRegister).when(trafficRouter).getCacheRegister();

        trafficRouter.route(request, track);

        verify(track).setResult(ResultType.MISS);
        verify(track).setResultDetails(ResultDetails.DS_CLIENT_GEO_UNSUPPORTED);
    }
}
