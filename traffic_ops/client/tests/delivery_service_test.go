/*
   Copyright 2015 Comcast Cable Communications Management, LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

package test

import (
	"net/http"
	"testing"

	"github.com/Comcast/traffic_control/traffic_ops/client"
	"github.com/Comcast/traffic_control/traffic_ops/client/fixtures"
	"github.com/jheitz200/test_helper"
)

func TestDeliveryServices(t *testing.T) {
	resp := fixtures.DeliveryServices()
	server := testHelper.ValidHTTPServer(resp)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a successful Traffic Ops request for DeliveryServices")

	ds, err := to.DeliveryServices()
	if err != nil {
		testHelper.Error(t, "Should be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should be able to make a request to Traffic Ops")
	}

	if len(ds) != 1 {
		testHelper.Error(t, "Should get back \"1\" DeliveryService, got: %d", len(ds))
	} else {
		testHelper.Success(t, "Should get back \"1\" DeliveryService")
	}

	for _, s := range ds {
		if s.XMLID != "ds-test" {
			testHelper.Error(t, "Should get back \"ds-test\" for \"XMLID\", got: %s", s.XMLID)
		} else {
			testHelper.Success(t, "Should get back \"ds-test\" for \"XMLID\"")
		}

		if s.MissLong != "-99.123456" {
			testHelper.Error(t, "Should get back \"-99.123456\" for \"MissLong\", got: %s", s.MissLong)
		} else {
			testHelper.Success(t, "Should get back \"-99.123456\" for \"MissLong\"")
		}
	}
}

func TestDeliveryServicesUnauthorized(t *testing.T) {
	server := testHelper.InvalidHTTPServer(http.StatusUnauthorized)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a failed Traffic Ops request for DeliveryServices")

	_, err := to.DeliveryServices()
	if err == nil {
		testHelper.Error(t, "Should not be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should not be able to make a request to Traffic Ops")
	}
}

func TestDeliveryService(t *testing.T) {
	resp := fixtures.DeliveryServices()
	server := testHelper.ValidHTTPServer(resp)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a successful Traffic Ops request for a DeliveryService")

	ds, err := to.DeliveryService("123")
	if err != nil {
		testHelper.Error(t, "Should be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should be able to make a request to Traffic Ops")
	}

	if ds.XMLID != "ds-test" {
		testHelper.Error(t, "Should get back \"ds-test\" for \"XMLID\", got: %s", ds.XMLID)
	} else {
		testHelper.Success(t, "Should get back \"ds-test\" for \"XMLID\"")
	}

	if ds.MissLong != "-99.123456" {
		testHelper.Error(t, "Should get back \"-99.123456\" for \"MissLong\", got: %s", ds.MissLong)
	} else {
		testHelper.Success(t, "Should get back \"-99.123456\" for \"MissLong\"")
	}
}

func TestDeliveryServiceUnauthorized(t *testing.T) {
	server := testHelper.InvalidHTTPServer(http.StatusUnauthorized)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a failed Traffic Ops request for a DeliveryService")

	_, err := to.DeliveryService("123")
	if err == nil {
		testHelper.Error(t, "Should not be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should not be able to make a request to Traffic Ops")
	}
}

func TestDeliveryServiceState(t *testing.T) {
	resp := fixtures.DeliveryServiceState()
	server := testHelper.ValidHTTPServer(resp)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a successful Traffic Ops request for a DeliveryServiceState")

	state, err := to.DeliveryServiceState("123")
	if err != nil {
		testHelper.Error(t, "Should be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should be able to make a request to Traffic Ops")
	}

	if state.Failover.Destination.Location != "someLocation" {
		testHelper.Error(t, "Should get back \"someLocation\" for \"Failover.Destination.Location\", got: %s", state.Failover.Destination.Location)
	} else {
		testHelper.Success(t, "Should get back \"someLocation\" for \"Failover.Destination.Location\"")
	}

	if state.Enabled != true {
		testHelper.Error(t, "Should get back \"true\" for \"Enabled\", got: %s", state.Enabled)
	} else {
		testHelper.Success(t, "Should get back \"true\" for \"Enabled\"")
	}
}

func TestDeliveryServiceStateUnauthorized(t *testing.T) {
	server := testHelper.InvalidHTTPServer(http.StatusUnauthorized)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a failed Traffic Ops request for a DeliveryServiceState")

	_, err := to.DeliveryServiceState("123")
	if err == nil {
		testHelper.Error(t, "Should not be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should not be able to make a request to Traffic Ops")
	}
}

func TestDeliveryServiceHealth(t *testing.T) {
	resp := fixtures.DeliveryServiceHealth()
	server := testHelper.ValidHTTPServer(resp)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a successful Traffic Ops request for a DeliveryServiceHealth")

	health, err := to.DeliveryServiceHealth("123")
	if err != nil {
		testHelper.Error(t, "Should be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should be able to make a request to Traffic Ops")
	}

	if health.TotalOnline != 2 {
		testHelper.Error(t, "Should get back \"2\" for \"TotalOnline\", got: %s", health.TotalOnline)
	} else {
		testHelper.Success(t, "Should get back \"2\" for \"TotalOnline\"")
	}

	if health.TotalOffline != 3 {
		testHelper.Error(t, "Should get back \"3\" for \"TotalOffline\", got: %s", health.TotalOffline)
	} else {
		testHelper.Success(t, "Should get back \"2\" for \"TotalOffline\"")
	}

	if health.CacheGroups[0].Name != "someCacheGroup" {
		testHelper.Error(t, "Should get back \"someCacheGroup\" for \"CacheGroups[0].Name\", got: %s", health.CacheGroups[0].Name)
	} else {
		testHelper.Success(t, "Should get back \"someCacheGroup\" for \"CacheGroups[0].Name\"")
	}
}

func TestDeliveryServiceHealthUnauthorized(t *testing.T) {
	server := testHelper.InvalidHTTPServer(http.StatusUnauthorized)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a failed Traffic Ops request for a DeliveryServiceHealth")

	_, err := to.DeliveryServiceHealth("123")
	if err == nil {
		testHelper.Error(t, "Should not be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should not be able to make a request to Traffic Ops")
	}
}

func TestDeliveryServiceCapacity(t *testing.T) {
	resp := fixtures.DeliveryServiceCapacity()
	server := testHelper.ValidHTTPServer(resp)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a successful Traffic Ops request for a DeliveryServiceCapacity")

	capacity, err := to.DeliveryServiceCapacity("123")
	if err != nil {
		testHelper.Error(t, "Should be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should be able to make a request to Traffic Ops")
	}

	if capacity.AvailablePercent != 90.12345 {
		testHelper.Error(t, "Should get back \"90.12345\" for \"AvailablePercent\", got: %s", capacity.AvailablePercent)
	} else {
		testHelper.Success(t, "Should get back \"90.12345\" for \"AvailablePercent\"")
	}

	if capacity.UnavailablePercent != 90.12345 {
		testHelper.Error(t, "Should get back \"90.12345\" for \"UnavailablePercent\", got: %s", capacity.UnavailablePercent)
	} else {
		testHelper.Success(t, "Should get back \"90.12345\" for \"UnavailablePercent\"")
	}

	if capacity.UtilizedPercent != 90.12345 {
		testHelper.Error(t, "Should get back \"90.12345\" for \"UtilizedPercent\", got: %s", capacity.UtilizedPercent)
	} else {
		testHelper.Success(t, "Should get back \"90.12345\" for \"UtilizedPercent\"")
	}
}

func TestDeliveryServiceCapacityUnauthorized(t *testing.T) {
	server := testHelper.InvalidHTTPServer(http.StatusUnauthorized)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a failed Traffic Ops request for a DeliveryServiceCapacity")

	_, err := to.DeliveryServiceCapacity("123")
	if err == nil {
		testHelper.Error(t, "Should not be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should not be able to make a request to Traffic Ops")
	}
}

func TestDeliveryServiceRouting(t *testing.T) {
	resp := fixtures.DeliveryServiceRouting()
	server := testHelper.ValidHTTPServer(resp)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a successful Traffic Ops request for a DeliveryServiceRouting")

	routing, err := to.DeliveryServiceRouting("123")
	if err != nil {
		testHelper.Error(t, "Should be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should be able to make a request to Traffic Ops")
	}

	if routing.StaticRoute != 1 {
		testHelper.Error(t, "Should get back \"1\" for \"StaticRoute\", got: %s", routing.StaticRoute)
	} else {
		testHelper.Success(t, "Should get back \"1\" for \"StaticRoute\"")
	}
}

func TestDeliveryServiceRoutingUnauthorized(t *testing.T) {
	server := testHelper.InvalidHTTPServer(http.StatusUnauthorized)
	defer server.Close()

	var httpClient http.Client
	to := client.Session{
		URL:       server.URL,
		UserAgent: &httpClient,
	}

	testHelper.Context(t, "Given the need to test a failed Traffic Ops request for a DeliveryServiceRouting")

	_, err := to.DeliveryServiceRouting("123")
	if err == nil {
		testHelper.Error(t, "Should not be able to make a request to Traffic Ops")
	} else {
		testHelper.Success(t, "Should not be able to make a request to Traffic Ops")
	}
}
