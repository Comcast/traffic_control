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

// Hardware returns a default HardwareResponse to be used for testing.
func Hardware() *client.HardwareResponse {
	return &client.HardwareResponse{
		Response: []client.Hardware{
			client.Hardware{
				ID:          "18",
				HostName:    "odol-atsmid-cen-09",
				LastUpdated: "2015-07-16 09:04:20",
				Value:       "1.00",
				Description: "BACKPLANE FIRMWARE",
			},
		},
	}
}
