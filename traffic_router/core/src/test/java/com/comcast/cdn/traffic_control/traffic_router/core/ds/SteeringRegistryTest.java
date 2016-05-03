/*
 * Copyright 2015 Comcast Cable Communications Management, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.comcast.cdn.traffic_control.traffic_router.core.ds;

import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.equalTo;

public class SteeringRegistryTest {
	@Test
	public void itConsumesValidJson() throws Exception {
		String json = "{ \"response\": [ " +
			"{ \"id\":\"steering-1\"," +
			"\"bypasses\":[" +
			"{\"filter\":\".*/important-stuff/.*\", \"destination\":\"ds-01\"}" +
			"]," +
			"  \"steeredDeliveryServices\" : [" +
			"        {\"id\": \"ds-01\", \"weight\": 90}," +
			"        {\"id\": \"ds-02\", \"weight\": 10}" +
			"      ]" +
			"}, " +
			"{ \"id\":\"steering-2\"," +
			"  \"steeredDeliveryServices\" : [" +
			"        {\"id\": \"ds-01\", \"weight\": 90}," +
			"        {\"id\": \"ds-02\", \"weight\": 10}" +
			"      ]" +
			"}" +
			"] }";

		SteeringRegistry steeringRegistry = new SteeringRegistry();
		steeringRegistry.update(json);
		assertThat(steeringRegistry.has("steering-1"), equalTo(true));
		assertThat(steeringRegistry.has("steering-2"), equalTo(true));

		SteeredDeliveryService steeredDeliveryService1 = new SteeredDeliveryService();
		steeredDeliveryService1.setId("ds-01");
		steeredDeliveryService1.setWeight(90);

		SteeredDeliveryService steeredDeliveryService2 = new SteeredDeliveryService();
		steeredDeliveryService2.setId("ds-02");
		steeredDeliveryService2.setWeight(10);

		assertThat(steeringRegistry.get("steering-1").getSteeredDeliveryServices(), containsInAnyOrder(steeredDeliveryService1, steeredDeliveryService2));
		assertThat(steeringRegistry.get("steering-1").getBypasses().get(0).getDestination(), equalTo("ds-01"));
		assertThat(steeringRegistry.get("steering-1").getBypasses().get(0).getFilter(), equalTo(".*/important-stuff/.*"));
	}
}
