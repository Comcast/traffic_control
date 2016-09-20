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

package fixtures

import "github.com/Comcast/traffic_control/traffic_ops/client"

// DeliveryServices returns a default DeliveryServiceResponse to be used for testing.
func DeliveryServices() *client.DeliveryServiceResponse {
	return &client.DeliveryServiceResponse{
		Response: []client.DeliveryService{
			client.DeliveryService{
				ID:                   "001",
				XMLID:                "ds-test",
				Active:               true,
				DSCP:                 "40",
				Signed:               false,
				QStringIgnore:        "1",
				GeoLimit:             "0",
				GeoProvider:          "0",
				DNSBypassTTL:         "30",
				Type:                 "HTTP",
				ProfileName:          "ds-123",
				CDNName:              "test-cdn",
				CCRDNSTTL:            "3600",
				GlobalMaxTPS:         "0",
				MaxDNSAnswers:        "0",
				MissLat:              "44.654321",
				MissLong:             "-99.123456",
				Protocol:             "0",
				IPV6RoutingEnabled:   true,
				RangeRequestHandling: "0",
				TRResponseHeaders:    "Access-Control-Allow-Origin: *",
				MultiSiteOrigin:      "0",
				DisplayName:          "Testing",
				InitialDispersion:    "1",
			},
		},
	}
}

// DeliveryServiceState returns a default DeliveryServiceStateResponse to be used for testing.
func DeliveryServiceState() *client.DeliveryServiceStateResponse {
	dest := client.DeliveryServiceDestination{
		Location: "someLocation",
		Type:     "DNS",
	}

	failover := client.DeliveryServiceFailover{
		Locations:   []string{"one", "two"},
		Destination: dest,
		Configured:  true,
		Enabled:     true,
	}

	ds := client.DeliveryServiceState{
		Enabled:  true,
		Failover: failover,
	}

	return &client.DeliveryServiceStateResponse{
		Response: ds,
	}
}

// DeliveryServiceHealth returns a default DeliveryServiceHealthResponse to be used for testing.
func DeliveryServiceHealth() *client.DeliveryServiceHealthResponse {
	cacheGroup := client.DeliveryServiceCacheGroup{
		Name:    "someCacheGroup",
		Online:  2,
		Offline: 3,
	}

	dsh := client.DeliveryServiceHealth{
		TotalOnline:  2,
		TotalOffline: 3,
		CacheGroups:  []client.DeliveryServiceCacheGroup{cacheGroup},
	}

	return &client.DeliveryServiceHealthResponse{
		Response: dsh,
	}
}

// DeliveryServiceCapacity returns a default DeliveryServiceCapacityResponse to be used for testing.
func DeliveryServiceCapacity() *client.DeliveryServiceCapacityResponse {
	dsc := client.DeliveryServiceCapacity{
		AvailablePercent:   90.12345,
		UnavailablePercent: 90.12345,
		UtilizedPercent:    90.12345,
		MaintenancePercent: 90.12345,
	}

	return &client.DeliveryServiceCapacityResponse{
		Response: dsc,
	}
}

// DeliveryServiceRouting returns a default DeliveryServiceRoutingResponse to be used for testing.
func DeliveryServiceRouting() *client.DeliveryServiceRoutingResponse {
	dsc := client.DeliveryServiceRouting{
		StaticRoute:       1,
		Miss:              2,
		Geo:               3.33,
		Err:               4,
		CZ:                5.55,
		DSR:               6.66,
		Fed:               1,
		RegionalAlternate: 1,
		RegionalDenied:    1,
	}

	return &client.DeliveryServiceRoutingResponse{
		Response: dsc,
	}
}
