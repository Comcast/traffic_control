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

// Profiles returns a default ProfileResponse to be used for testing.
func Profiles() *client.ProfileResponse {
	return &client.ProfileResponse{
		Response: []client.Profile{
			client.Profile{
				Name:        "TR_CDN2",
				Description: "kabletown Content Router",
				LastUpdated: "2012-10-08 13:34:45",
			},
		},
	}
}
