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

import java.util.HashMap;
import java.util.Map;

import com.comcast.cdn.traffic_control.traffic_router.core.request.HTTPRequest;
import org.junit.Before;
import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.mockito.Matchers.anyBoolean;
import static org.mockito.Matchers.anyString;
import static org.mockito.Matchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.doAnswer;

import org.mockito.invocation.InvocationOnMock;
import org.mockito.stubbing.Answer;
import org.powermock.api.mockito.PowerMockito;


import com.comcast.cdn.traffic_control.traffic_router.core.cache.CacheRegister;
import com.comcast.cdn.traffic_control.traffic_router.core.ds.DeliveryService;
import org.powermock.reflect.Whitebox;


public class ConfigHandlerTest {
    private ConfigHandler handler;

    @Before
    public void before() throws Exception {
        handler = mock(ConfigHandler.class);
    }

    @Test
    public void itTestRelativeUrl() throws Exception {
        final String redirectUrl = "relative/url";
        final String dsId = "relative-url";
        final String[] urlType = {""};
        final String[] typeUrl = {""};

        Map<String, DeliveryService> dsMap = new HashMap<String, DeliveryService>();

        DeliveryService ds = mock(DeliveryService.class);
        when(ds.getId()).thenReturn(dsId);
        when(ds.getGeoRedirectUrl()).thenReturn(redirectUrl);
        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                typeUrl[0] = (String)(args[0]);
                return null;
            }
        }).when(ds).setGeoRedirectFile(anyString());
        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                urlType[0] = (String)args[0];
                return null;
            }
        }).when(ds).setGeoRedirectUrlType(anyString());

        dsMap.put(dsId, ds);
        
        CacheRegister register = PowerMockito.mock(CacheRegister.class);

        Whitebox.invokeMethod(handler, "initGeoFailedRedirect", dsMap, register);
        assertThat(urlType[0], equalTo("DS_URL"));
        assertThat(typeUrl[0], equalTo(""));
    }

    @Test
    public void itTestRelativeUrlNegative() throws Exception {
        final String redirectUrl = "://invalid";
        final String dsId = "relative-url";
        final String[] urlType = {""};
        final String[] typeUrl = {""};

        Map<String, DeliveryService> dsMap = new HashMap<String, DeliveryService>();

        DeliveryService ds = mock(DeliveryService.class);
        when(ds.getId()).thenReturn(dsId);
        when(ds.getGeoRedirectUrl()).thenReturn(redirectUrl);

        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                typeUrl[0] = (String)(args[0]);
                return null;
            }
        }).when(ds).setGeoRedirectFile(anyString());
        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                urlType[0] = (String)args[0];
                return null;
            }
        }).when(ds).setGeoRedirectUrlType(anyString());

        dsMap.put(dsId, ds);

        CacheRegister register = PowerMockito.mock(CacheRegister.class);

        Whitebox.invokeMethod(handler, "initGeoFailedRedirect", dsMap, register);
        assertThat(urlType[0], equalTo(""));
        assertThat(typeUrl[0], equalTo(""));
    }

    @Test
    public void itTestNoSuchDsUrl() throws Exception {
        final String path = "/ds/url";
        final String redirectUrl = "http://test.com" + path;
        final String dsId = "relative-url";
        final String[] urlType = {""};
        final String[] typeUrl = {""};

        Map<String, DeliveryService> dsMap = new HashMap<String, DeliveryService>();

        DeliveryService ds = mock(DeliveryService.class);
        when(ds.getId()).thenReturn(dsId);
        when(ds.getGeoRedirectUrl()).thenReturn(redirectUrl);
        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                typeUrl[0] = (String)(args[0]);
                return null;
            }
        }).when(ds).setGeoRedirectFile(anyString());
        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                urlType[0] = (String)args[0];
                return null;
            }
        }).when(ds).setGeoRedirectUrlType(anyString());

        dsMap.put(dsId, ds);

        CacheRegister register = PowerMockito.mock(CacheRegister.class);

        when(register.getDeliveryService(any(HTTPRequest.class), anyBoolean())).thenReturn(null);

        Whitebox.invokeMethod(handler, "initGeoFailedRedirect", dsMap, register);
        assertThat(urlType[0], equalTo("NOT_DS_URL"));
        assertThat(typeUrl[0], equalTo(path));
    }

    @Test
    public void itTestNotThisDsUrl() throws Exception {
        final String path = "/ds/url";
        final String redirectUrl = "http://test.com" + path;
        final String dsId = "relative-ds";
        final String anotherId = "another-ds";
        final String[] urlType = {""};
        final String[] typeUrl = {""};

        Map<String, DeliveryService> dsMap = new HashMap<String, DeliveryService>();

        DeliveryService ds = mock(DeliveryService.class);
        when(ds.getId()).thenReturn(dsId);
        when(ds.getGeoRedirectUrl()).thenReturn(redirectUrl);
        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                typeUrl[0] = (String)(args[0]);
                return null;
            }
        }).when(ds).setGeoRedirectFile(anyString());
        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                urlType[0] = (String)args[0];
                return null;
            }
        }).when(ds).setGeoRedirectUrlType(anyString());

        dsMap.put(dsId, ds);

        DeliveryService anotherDs = mock(DeliveryService.class);
        when(ds.getId()).thenReturn(anotherId);
        CacheRegister register = PowerMockito.mock(CacheRegister.class);

        when(register.getDeliveryService(any(HTTPRequest.class), anyBoolean())).thenReturn(anotherDs);

        Whitebox.invokeMethod(handler, "initGeoFailedRedirect", dsMap, register);
        assertThat(urlType[0], equalTo("NOT_DS_URL"));
        assertThat(typeUrl[0], equalTo(path));
    }

    @Test
    public void itTestThisDsUrl() throws Exception {
        final String path = "/ds/url";
        final String redirectUrl = "http://test.com" + path;
        final String dsId = "relative-ds";
        final String[] urlType = {""};
        final String[] typeUrl = {""};

        Map<String, DeliveryService> dsMap = new HashMap<String, DeliveryService>();

        DeliveryService ds = mock(DeliveryService.class);
        when(ds.getId()).thenReturn(dsId);
        when(ds.getGeoRedirectUrl()).thenReturn(redirectUrl);
        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                typeUrl[0] = (String)(args[0]);
                return null;
            }
        }).when(ds).setGeoRedirectFile(anyString());
        doAnswer(new Answer<Void>() {
            public Void answer(InvocationOnMock invocation) {
                Object[] args = invocation.getArguments();
                urlType[0] = (String)args[0];
                return null;
            }
        }).when(ds).setGeoRedirectUrlType(anyString());

        dsMap.put(dsId, ds);

        CacheRegister register = PowerMockito.mock(CacheRegister.class);

        when(register.getDeliveryService(any(HTTPRequest.class), anyBoolean())).thenReturn(ds);

        Whitebox.invokeMethod(handler, "initGeoFailedRedirect", dsMap, register);
        assertThat(urlType[0], equalTo("DS_URL"));
        assertThat(typeUrl[0], equalTo(path));
    }
}
