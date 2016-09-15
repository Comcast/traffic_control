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

import "encoding/json"

// DeliveryServiceResponse ...
type DeliveryServiceResponse struct {
	Version  string            `json:"version"`
	Response []DeliveryService `json:"response"`
}

// DeliveryService ...
type DeliveryService struct {
	ID                   string `json:"id"`
	XMLID                string `json:"xmlId"`
	Active               bool   `json:"active"`
	DSCP                 string `json:"dscp"`
	Signed               bool   `json:"signed"`
	QStringIgnore        string `json:"qstringIgnore"`
	GeoLimit             string `json:"geoLimit"`
	GeoProvider          string `json:"geoProvider"`
	HTTPBypassFQDN       string `json:"httpBypassFqdn"`
	DNSBypassIP          string `json:"dnsBypassIp"`
	DNSBypassIP6         string `json:"dnsBypassIp6"`
	DNSBypassCname       string `json:"dnsBypassCname"`
	DNSBypassTTL         string `json:"dnsBypassTtl"`
	OrgServerFQDN        string `json:"orgServerFqdn"`
	Type                 string `json:"type"`
	ProfileName          string `json:"profileName"`
	ProfileDesc          string `json:"profileDescription"`
	CDNName              string `json:"cdnName"`
	CCRDNSTTL            string `json:"ccrDnsTtl"`
	GlobalMaxMBPS        string `json:"globalMaxMbps"`
	GlobalMaxTPS         string `json:"globalMaxTps"`
	LongDesc             string `json:"longDesc"`
	LongDesc1            string `json:"longDesc1"`
	LongDesc2            string `json:"longDesc2"`
	MaxDNSAnswers        string `json:"maxDnsAnswers"`
	InfoURL              string `json:"infoUrl"`
	MissLat              string `json:"missLat"`
	MissLong             string `json:"missLong"`
	CheckPath            string `json:"checkPath"`
	LastUpdated          string `json:"lastUpdated"`
	Protocol             string `json:"protocol"`
	IPV6RoutingEnabled   bool   `json:"ipv6RoutingEnabled"`
	RangeRequestHandling string `json:"rangeRequestHandling"`
	HeaderRewrite        string `json:"headerRewrite"`
	EdgeHeaderRewrite    string `json:"edgeHeaderRewrite"`
	MidHeaderRewrite     string `json:"midHeaderRewrite"`
	TRResponseHeaders    string `json:"trResponseHeaders"`
	RegexRemap           string `json:"regexRemap"`
	CacheURL             string `json:"cacheurl"`
	RemapText            string `json:"remapText"`
	MultiSiteOrigin      string `json:"multiSiteOrigin"`
	DisplayName          string `json:"displayName"`
	InitialDispersion    string `json:"initialDispersion"`
}

// DeliveryServiceStateResponse ...
type DeliveryServiceStateResponse struct {
	Response DeliveryServiceState `json:"response"`
}

// DeliveryServiceState ...
type DeliveryServiceState struct {
	Enabled  bool                    `json:"enabled"`
	Failover DeliveryServiceFailover `json:"failover"`
}

// DeliveryServiceFailover ...
type DeliveryServiceFailover struct {
	Locations   []string                   `json:"locations"`
	Destination DeliveryServiceDestination `json:"destination"`
	Configured  bool                       `json:"configured"`
	Enabled     bool                       `json:"enabled"`
}

// DeliveryServiceDestination ...
type DeliveryServiceDestination struct {
	Location string `json:"location"`
	Type     string `json:"type"`
}

// DeliveryServiceHealthResponse ...
type DeliveryServiceHealthResponse struct {
	Response DeliveryServiceHealth `json:"response"`
}

// DeliveryServiceHealth ...
type DeliveryServiceHealth struct {
	TotalOnline  int                         `json:"totalOnline"`
	TotalOffline int                         `json:"totalOffline"`
	CacheGroups  []DeliveryServiceCacheGroup `json:"cacheGroups"`
}

// DeliveryServiceCacheGroup ...
type DeliveryServiceCacheGroup struct {
	Online  int    `json:"online"`
	Offline int    `json:"offline"`
	Name    string `json:"name"`
}

// DeliveryServiceCapacityResponse ...
type DeliveryServiceCapacityResponse struct {
	Response DeliveryServiceCapacity `json:"response"`
}

// DeliveryServiceCapacity ...
type DeliveryServiceCapacity struct {
	AvailablePercent   float64 `json:"availablePercent"`
	UnavailablePercent float64 `json:"unavailablePercent"`
	UtilizedPercent    float64 `json:"utilizedPercent"`
	MaintenancePercent float64 `json:"maintenancePercent"`
}

// DeliveryServices gets an array of DeliveryServices
func (to *Session) DeliveryServices() ([]DeliveryService, error) {
	url := "/api/1.2/deliveryservices.json"
	resp, err := to.request(url, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var data DeliveryServiceResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	return data.Response, nil
}

// DeliveryService gets the DeliveryService for the ID it's passed
func (to *Session) DeliveryService(id string) (*DeliveryService, error) {
	url := "/api/1.2/deliveryservices/" + id + ".json"
	resp, err := to.request(url, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var data DeliveryServiceResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	return &data.Response[0], nil
}

// DeliveryServiceState gets the DeliveryServiceState for the ID it's passed
func (to *Session) DeliveryServiceState(id string) (*DeliveryServiceState, error) {
	url := "/api/1.2/deliveryservices/" + id + "/state.json"
	resp, err := to.request(url, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var data DeliveryServiceStateResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	return &data.Response, nil
}

// DeliveryServiceHealth gets the DeliveryServiceHealth for the ID it's passed
func (to *Session) DeliveryServiceHealth(id string) (*DeliveryServiceHealth, error) {
	url := "/api/1.2/deliveryservices/" + id + "/health.json"
	resp, err := to.request(url, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var data DeliveryServiceHealthResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	return &data.Response, nil
}

// DeliveryServiceCapacity gets the DeliveryServiceCapacity for the ID it's passed
func (to *Session) DeliveryServiceCapacity(id string) (*DeliveryServiceCapacity, error) {
	url := "/api/1.2/deliveryservices/" + id + "/capacity.json"
	resp, err := to.request(url, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var data DeliveryServiceCapacityResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	return &data.Response, nil
}
