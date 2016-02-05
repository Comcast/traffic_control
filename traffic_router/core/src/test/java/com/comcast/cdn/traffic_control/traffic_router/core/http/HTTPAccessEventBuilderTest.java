package com.comcast.cdn.traffic_control.traffic_router.core.http;

import com.comcast.cdn.traffic_control.traffic_router.core.loc.Geolocation;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.ResultType;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.ResultDetails;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.powermock.core.classloader.annotations.PrepareForTest;
import org.powermock.modules.junit4.PowerMockRunner;

import javax.servlet.http.HttpServletRequest;
import java.net.URL;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.endsWith;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.startsWith;
import static org.mockito.Matchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.powermock.api.mockito.PowerMockito.mockStatic;
import static org.powermock.api.mockito.PowerMockito.whenNew;

@RunWith(PowerMockRunner.class)
@PrepareForTest({Date.class, HTTPAccessEventBuilder.class})
public class HTTPAccessEventBuilderTest {
    private HttpServletRequest request;

    @Before
    public void before() throws Exception {
        mockStatic(Date.class);
        Date startDate = mock(Date.class);
        when(startDate.getTime()).thenReturn(144140678000L);
        whenNew(Date.class).withArguments(anyLong()).thenReturn(startDate);

        Date finishDate = mock(Date.class);
        when(finishDate.getTime()).thenReturn(144140678125L);
        whenNew(Date.class).withNoArguments().thenReturn(finishDate);

        request = mock(HttpServletRequest.class);
        when(request.getRequestURL()).thenReturn(new StringBuffer("http://example.com/index.html?foo=bar"));
        when(request.getMethod()).thenReturn("GET");
        when(request.getProtocol()).thenReturn("HTTP/1.1");
        when(request.getRemoteAddr()).thenReturn("192.168.7.6");
    }

    @Test
    public void itGeneratesAccessEvents() throws Exception {
        HTTPAccessRecord.Builder builder = new HTTPAccessRecord.Builder(new Date(144140678000L), request);
        HTTPAccessRecord httpAccessRecord = builder.build();

        String httpAccessEvent = HTTPAccessEventBuilder.create(httpAccessRecord);

        assertThat(httpAccessEvent, equalTo("144140678.000 qtype=HTTP chi=192.168.7.6 url=\"http://example.com/index.html?foo=bar\" cqhm=GET cqhv=HTTP/1.1 rtype=- rloc=\"-\" rdtl=- rerr=\"-\" rgb=\"-\" rurl=\"-\" rh=\"-\""));
    }

    @Test
    public void itAddsResponseData() throws Exception {

        StatTracker.Track track = new StatTracker.Track();
        HTTPAccessRecord.Builder builder = new HTTPAccessRecord.Builder(new Date(144140633999L), request)
            .resultType(track.getResult())
            .resultLocation(new Geolocation(39.7528,-104.9997))
            .responseCode(302)
            .responseURL(new URL("http://example.com/hereitis/index.html?foo=bar"));

        HTTPAccessRecord httpAccessRecord = builder.resultType(ResultType.CZ).build();
        String httpAccessEvent = HTTPAccessEventBuilder.create(httpAccessRecord);

        assertThat(httpAccessEvent, equalTo("144140678.000 qtype=HTTP chi=192.168.7.6 url=\"http://example.com/index.html?foo=bar\" cqhm=GET cqhv=HTTP/1.1 rtype=CZ rloc=\"39.75,-104.99\" rdtl=- rerr=\"-\" rgb=\"-\" pssc=302 ttms=125 rurl=\"http://example.com/hereitis/index.html?foo=bar\" rh=\"-\""));
    }

    @Test
    public void itMarksTTMSLessThanMilliAsZero() throws Exception {
        Date fastFinishDate = mock(Date.class);
        when(fastFinishDate.getTime()).thenReturn(144140678000L);
        whenNew(Date.class).withNoArguments().thenReturn(fastFinishDate);

        StatTracker.Track track = new StatTracker.Track();
        HTTPAccessRecord.Builder builder = new HTTPAccessRecord.Builder(new Date(144140633999L), request)
                .resultType(track.getResult())
                .responseCode(302)
                .responseURL(new URL("http://example.com/hereitis/index.html?foo=bar"));

        HTTPAccessRecord httpAccessRecord = builder.build();
        String httpAccessEvent = HTTPAccessEventBuilder.create(httpAccessRecord);

        assertThat(httpAccessEvent, equalTo("144140678.000 qtype=HTTP chi=192.168.7.6 url=\"http://example.com/index.html?foo=bar\" cqhm=GET cqhv=HTTP/1.1 rtype=ERROR rloc=\"-\" rdtl=- rerr=\"-\" rgb=\"-\" pssc=302 ttms=0 rurl=\"http://example.com/hereitis/index.html?foo=bar\" rh=\"-\""));
    }


    @Test
    public void itRecordsTrafficRouterErrors() throws Exception {
        Date fastFinishDate = mock(Date.class);
        when(fastFinishDate.getTime()).thenReturn(144140678000L);
        whenNew(Date.class).withNoArguments().thenReturn(fastFinishDate);

        StatTracker.Track track = new StatTracker.Track();
        HTTPAccessRecord.Builder builder = new HTTPAccessRecord.Builder(new Date(144140633999L), request)
                .resultType(track.getResult())
                .responseCode(302)
                .rerr("RuntimeException: you're doing it wrong")
                .responseURL(new URL("http://example.com/hereitis/index.html?foo=bar"));

        HTTPAccessRecord httpAccessRecord = builder.build();
        String httpAccessEvent = HTTPAccessEventBuilder.create(httpAccessRecord);

        assertThat(httpAccessEvent, equalTo("144140678.000 qtype=HTTP chi=192.168.7.6 url=\"http://example.com/index.html?foo=bar\" cqhm=GET cqhv=HTTP/1.1 rtype=ERROR rloc=\"-\" rdtl=- rerr=\"RuntimeException: you're doing it wrong\" rgb=\"-\" pssc=302 ttms=0 rurl=\"http://example.com/hereitis/index.html?foo=bar\" rh=\"-\""));
    }
    
    @Test
    public void itRecordsMissResultDetails() throws Exception {
        Date fastFinishDate = mock(Date.class);
        when(fastFinishDate.getTime()).thenReturn(144140678000L);
        whenNew(Date.class).withNoArguments().thenReturn(fastFinishDate);

        HTTPAccessRecord.Builder builder = new HTTPAccessRecord.Builder(new Date(144140633999L), request)
                .resultType(ResultType.MISS)
                .resultDetails(ResultDetails.DS_NO_BYPASS)
                .responseCode(503);

        HTTPAccessRecord httpAccessRecord = builder.build();
        String httpAccessEvent = HTTPAccessEventBuilder.create(httpAccessRecord);

        assertThat(httpAccessEvent, equalTo("144140678.000 qtype=HTTP chi=192.168.7.6 url=\"http://example.com/index.html?foo=bar\" cqhm=GET cqhv=HTTP/1.1 rtype=MISS rloc=\"-\" rdtl=DS_NO_BYPASS rerr=\"-\" rgb=\"-\" pssc=503 ttms=0 rurl=\"-\" rh=\"-\""));
    }

    @Test
    public void itRecordsRequestHeaders() throws Exception {
        Map<String, String> httpAccessRequestHeaders = new HashMap<String, String>();
        httpAccessRequestHeaders.put("If-Modified-Since", "Thurs, 15 July 2010 12:00:00 UTC");
        httpAccessRequestHeaders.put("Accept", "text/*, text/html, text/html;level=1, */*");
        httpAccessRequestHeaders.put("Arbitrary", "The cow says \"moo\"");

        StatTracker.Track track = new StatTracker.Track();
        HTTPAccessRecord.Builder builder = new HTTPAccessRecord.Builder(new Date(144140633999L), request)
            .resultType(track.getResult())
            .resultLocation(new Geolocation(39.7528,-104.9997))
            .responseCode(302)
            .responseURL(new URL("http://example.com/hereitis/index.html?foo=bar"))
            .requestHeaders(httpAccessRequestHeaders);

        HTTPAccessRecord httpAccessRecord = builder.resultType(ResultType.CZ).build();
        String httpAccessEvent = HTTPAccessEventBuilder.create(httpAccessRecord);


        assertThat(httpAccessEvent, not(containsString(" rh=\"-\"")));
        assertThat(httpAccessEvent, containsString("rh=\"If-Modified-Since: Thurs, 15 July 2010 12:00:00 UTC\""));
        assertThat(httpAccessEvent, containsString("rh=\"Accept: text/*, text/html, text/html;level=1, */*\""));
        assertThat(httpAccessEvent, containsString("rh=\"Arbitrary: The cow says 'moo'"));
    }

    @Test
    public void itUsesXMmClientIpHeaderForChi() throws Exception {
        when(request.getHeader(TRServlet.X_MM_CLIENT_IP)).thenReturn("192.168.100.100");

        HTTPAccessRecord httpAccessRecord = new HTTPAccessRecord.Builder(new Date(144140678000L), request).build();
        String httpAccessEvent = HTTPAccessEventBuilder.create(httpAccessRecord);

        assertThat(httpAccessEvent, equalTo("144140678.000 qtype=HTTP chi=192.168.100.100 url=\"http://example.com/index.html?foo=bar\" cqhm=GET cqhv=HTTP/1.1 rtype=- rloc=\"-\" rdtl=- rerr=\"-\" rgb=\"-\" rurl=\"-\" rh=\"-\""));
    }

    @Test
    public void itUsesFakeIpParameterForChi() throws Exception {
        when(request.getParameter("fakeClientIpAddress")).thenReturn("192.168.123.123");

        HTTPAccessRecord httpAccessRecord = new HTTPAccessRecord.Builder(new Date(144140678000L), request).build();
        String httpAccessEvent = HTTPAccessEventBuilder.create(httpAccessRecord);

        assertThat(httpAccessEvent, equalTo("144140678.000 qtype=HTTP chi=192.168.123.123 url=\"http://example.com/index.html?foo=bar\" cqhm=GET cqhv=HTTP/1.1 rtype=- rloc=\"-\" rdtl=- rerr=\"-\" rgb=\"-\" rurl=\"-\" rh=\"-\""));
    }

    @Test
    public void itUsesXMmClientIpHeaderOverFakeIpParameterForChi() throws Exception {
        when(request.getParameter("fakeClientIpAddress")).thenReturn("192.168.123.123");
        when(request.getHeader(TRServlet.X_MM_CLIENT_IP)).thenReturn("192.168.100.100");

        HTTPAccessRecord httpAccessRecord = new HTTPAccessRecord.Builder(new Date(144140678000L), request).build();
        String httpAccessEvent = HTTPAccessEventBuilder.create(httpAccessRecord);

        assertThat(httpAccessEvent, equalTo("144140678.000 qtype=HTTP chi=192.168.100.100 url=\"http://example.com/index.html?foo=bar\" cqhm=GET cqhv=HTTP/1.1 rtype=- rloc=\"-\" rdtl=- rerr=\"-\" rgb=\"-\" rurl=\"-\" rh=\"-\""));
    }
}
