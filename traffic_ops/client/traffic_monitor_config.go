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

package client

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
)

type TmConfigResponse struct {
	Version  string               `json:"version"`
	Response TrafficMonitorConfig `json:"response"`
}

type TrafficMonitorConfig struct {
	TrafficServers   []trafficServer                 `json:"trafficServers"`
	CacheGroups      []cacheGroup                    `json:"cacheGroups"`
	Config           map[string]interface{}          `json:"config"`
	TrafficMonitors  []trafficMonitor                `json:"trafficMonitors"`
	DeliveryServices []trafficMonitorDeliveryService `json:"deliveryServices"`
	Profiles         []profile                       `json:"profiles"`
}

type TrafficMonitorConfigMap struct {
	TrafficServer   map[string]trafficServer
	CacheGroup      map[string]cacheGroup
	Config          map[string]interface{}
	TrafficMonitor  map[string]trafficMonitor
	DeliveryService map[string]trafficMonitorDeliveryService
	Profile         map[string]profile
}

type trafficMonitorDeliveryService struct {
	XmlId              string `json:"xmlId"`
	TotalTpsThreshold  int64  `json:"TotalTpsThreshold"`
	Status             string `json:"status"`
	TotalKbpsThreshold int64  `json:"TotalKbpsThreshold"`
}

type profile struct {
	Parameters parameters `json:"parameters"`
	Name       string     `json:"name"`
	Type       string     `json:"type"`
}

type parameters struct {
	HealthConnectionTimeout                 int     `json:"health.connection.timeout"`
	HealthPollingUrl                        string  `json:"health.polling.url"`
	HealthThresholdQueryTime                int     `json:"health.threshold.queryTime"`
	HistoryCount                            int     `json:"history.count"`
	HealthThresholdAvailableBandwidthInKbps string  `json:"health.threshold.availableBandwidthInKbps"`
	HealthThresholdLoadAvg                  float64 `json:"health.threshold.loadavg,string"`
	MinFreeKbps                             int64
}

func (to *Session) TrafficMonitorConfigMap(cdn string) (TrafficMonitorConfigMap, error) {
	trafficMonitorConfig, err := to.TrafficMonitorConfig(cdn)
	trafficMonitorConfigMap := trafficMonitorTransformToMap(trafficMonitorConfig)
	return trafficMonitorConfigMap, err
}

func (to *Session) TrafficMonitorConfig(cdn string) (TrafficMonitorConfig, error) {
	body, err := to.getBytes("/api/1.2/cdns/" + cdn + "/configs/monitoring.json")
	trafficMonitorConfig, err := trafficMonitorConfigUnmarshall(body)
	return trafficMonitorConfig, err
}

func trafficMonitorConfigUnmarshall(body []byte) (TrafficMonitorConfig, error) {
	var tmConfigResponse TmConfigResponse
	err := json.Unmarshal(body, &tmConfigResponse)
	return tmConfigResponse.Response, err
}

func trafficMonitorTransformToMap(trafficMonitorConfig TrafficMonitorConfig) TrafficMonitorConfigMap {
	var trafficMonitorConfigMap TrafficMonitorConfigMap

	trafficMonitorConfigMap.TrafficServer = make(map[string]trafficServer)
	trafficMonitorConfigMap.CacheGroup = make(map[string]cacheGroup)
	trafficMonitorConfigMap.Config = make(map[string]interface{})
	trafficMonitorConfigMap.TrafficMonitor = make(map[string]trafficMonitor)
	trafficMonitorConfigMap.DeliveryService = make(map[string]trafficMonitorDeliveryService)
	trafficMonitorConfigMap.Profile = make(map[string]profile)

	for _, trafficServer := range trafficMonitorConfig.TrafficServers {
		trafficMonitorConfigMap.TrafficServer[trafficServer.HostName] = trafficServer
	}
	for _, cacheGroup := range trafficMonitorConfig.CacheGroups {
		trafficMonitorConfigMap.CacheGroup[cacheGroup.Name] = cacheGroup
	}
	for parameterKey, parameterVal := range trafficMonitorConfig.Config {
		trafficMonitorConfigMap.Config[parameterKey] = parameterVal
	}
	for _, trafficMonitor := range trafficMonitorConfig.TrafficMonitors {
		trafficMonitorConfigMap.TrafficMonitor[trafficMonitor.HostName] = trafficMonitor
	}
	for _, deliveryService := range trafficMonitorConfig.DeliveryServices {
		trafficMonitorConfigMap.DeliveryService[deliveryService.XmlId] = deliveryService
	}
	for _, profile := range trafficMonitorConfig.Profiles {
		bwThresholdString := profile.Parameters.HealthThresholdAvailableBandwidthInKbps
		if strings.HasPrefix(bwThresholdString, ">") {
			var err error
			profile.Parameters.MinFreeKbps, err = strconv.ParseInt(bwThresholdString[1:len(bwThresholdString)], 10, 64)
			if err != nil {
				fmt.Println("ERROR:", err)
			}
		}
		trafficMonitorConfigMap.Profile[profile.Name] = profile
	}

	return trafficMonitorConfigMap
}
