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

// HardwareResponse ...
type HardwareResponse struct {
	Version  string     `json:"version"`
	Response []Hardware `json:"response"`
}

// Hardware ...
type Hardware struct {
	ID          string `json:"serverId"`
	HostName    string `json:"serverHostName"`
	LastUpdated string `json:"lastUpdated"`
	Value       string `json:"val"`
	Description string `json:"description"`
}

// Hardware gets an array of Hardware
func (to *Session) Hardware() ([]Hardware, error) {
	url := "/api/1.2/hwinfo.json"
	resp, err := to.request(url, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var data HardwareResponse
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return nil, err
	}

	return data.Response, nil
}
