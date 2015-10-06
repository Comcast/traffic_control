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

type ProfileResponse struct {
	Version  string    `json:"version"`
	Response []Profile `json:"response"`
}

type Profile struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	CdnName     string `json:"cdnName"`
	LastUpdated string `json:"lastUpdated"`
}

// Profiles
// Get an array of Profiles
func (to *Session) Profiles() ([]Profile, error) {
	body, err := to.getBytes("/api/1.1/profiles.json")
	if err != nil {
		return nil, err
	}
	profileList, err := profileUnmarshall(body)
	return profileList.Response, err
}

func profileUnmarshall(body []byte) (ProfileResponse, error) {

	var data ProfileResponse
	err := json.Unmarshal(body, &data)
	return data, err
}
