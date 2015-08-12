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
	"fmt"
	"io/ioutil"
	"testing"
)

func TestHardware(t *testing.T) {
	fmt.Println("Running Hardware Tests")
	text, err := ioutil.ReadFile("testdata/hardware.json")
	if err != nil {
		t.Skip("Skipping parameters test, no hardware.json found.")
	}

	hardwareList, err := hardwareUnmarshall(text)
	if err != nil {
		t.Fatal(err)
	}
	for _, hardware := range hardwareList.Response {
		name := hardware.Id
		if len(name) == 0 {
			t.Fatal("hardware result does not contain 'ID'")
		}
		if len(hardware.HostName) == 0 {
			t.Error("hostname is null for hardware: " + name)
		}
		if len(hardware.LastUpdated) == 0 {
			t.Error("LastUpdated is null for hardware: " + name)
		}
		if len(hardware.Value) == 0 {
			t.Error("Value is null for hardware: " + name)
		}
		if len(hardware.Description) == 0 {
			t.Error("Description is null for hardware: " + name)
		}
	}
}
