package fixtures

import "github.com/Comcast/traffic_control/traffic_ops/client"

// TrafficRouterConfig returns a default TRConfigResponse to be used for testing.
func TrafficRouterConfig() *client.TRConfigResponse {
	return &client.TRConfigResponse{
		Response: client.TrafficRouterConfig{
			TrafficServers: []client.TrafficServer{
				client.TrafficServer{
					Profile:       "TR_CDN",
					IP:            "10.10.10.10",
					Status:        "OFFLINE",
					CacheGroup:    "tr-chicago",
					IP6:           "2001:123:abc12:64:22:::17/64",
					Port:          80,
					HostName:      "tr-chi-05",
					FQDN:          "tr-chi-05.kabletown.com",
					InterfaceName: "eth0",
					Type:          "TR",
					HashID:        "chi-tr-05",
				},
				client.TrafficServer{
					Profile:       "EDGE1_CDN",
					IP:            "3.3.3.3",
					Status:        "OFFLINE",
					CacheGroup:    "philadelphia",
					IP6:           "2009:123:456::2/64",
					Port:          80,
					HostName:      "edge-test-01",
					FQDN:          "edge-test-01.kabletown.com",
					InterfaceName: "bond0",
					Type:          "EDGE",
					HashID:        "edge-test-01",
				},
			},
			TrafficMonitors: []client.TrafficMonitor{
				client.TrafficMonitor{
					Port:     80,
					IP6:      "",
					IP:       "1.1.1.1",
					HostName: "traffic-monitor-01",
					FQDN:     "traffic-monitor-01@example.com",
					Profile:  "tr-123",
					Location: "philadelphia",
					Status:   "ONLINE",
				},
			},
			CacheGroups: []client.TMCacheGroup{
				client.TMCacheGroup{
					Name: "philadelphia",
					Coordinates: client.Coordinates{
						Longitude: 88,
						Latitude:  99,
					},
				},
				client.TMCacheGroup{
					Name: "tr-chicago",
					Coordinates: client.Coordinates{
						Longitude: 9,
						Latitude:  99,
					},
				},
			},
			Config: map[string]interface{}{
				"health.event-count":     200,
				"hack.ttl":               30,
				"health.threadPool":      4,
				"peers.polling.interval": 1000,
			},
			Stats: map[string]interface{}{
				"date":              1459371078,
				"cdnName":           "test-cdn",
				"trafficOpsHost":    "127.0.0.1:3000",
				"trafficOpsPath":    "/api/1.2/cdns/title-vi/configs/routing.json",
				"trafficOpsVersion": "__VERSION__",
				"trafficOpsUser":    "bob",
			},
			TrafficRouters: []client.TrafficRouter{
				client.TrafficRouter{
					Port:     6789,
					IP6:      "2345:1234:12:8::2/64",
					IP:       "127.0.0.1",
					FQDN:     "tr-01@ga.atlanta.kabletown.net",
					Profile:  "tr-123",
					Location: "tr-chicago",
					Status:   "ONLINE",
					APIPort:  3333,
				},
			},
			DeliveryServices: []client.TRDeliveryService{
				client.TRDeliveryService{
					XMLID: "ds-06",
					Domains: []string{
						"ga.atlanta.kabletown.net",
					},
					MissLocation: client.MissLocation{
						Latitude:  75,
						Longitude: 65,
					},
					CoverageZoneOnly: true,
					MatchSets: []client.MatchSet{
						client.MatchSet{
							Protocol: "HTTP",
							MatchList: []client.MatchList{
								client.MatchList{
									Regex:     ".*\\.ds-06\\..*",
									MatchType: "HOST",
								},
							},
						},
					},
					TTL: 3600,
					TTLs: client.TTLS{
						Arecord:    3600,
						SoaRecord:  86400,
						NsRecord:   3600,
						AaaaRecord: 3600,
					},
					BypassDestination: client.BypassDestination{
						Type: "HTTP",
					},
					StatcDNSEntries: []client.StaticDNS{
						client.StaticDNS{
							Value: "1.1.1.1",
							TTL:   30,
							Name:  "mm",
							Type:  "A",
						},
					},
					Soa: client.SOA{
						Admin:   "admin",
						Retry:   7200,
						Minimum: 30,
						Refresh: 7200,
						Expire:  604800,
					},
				},
			},
		},
	}
}
