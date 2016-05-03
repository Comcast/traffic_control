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

import java.util.ArrayList;
import java.util.List;

public class Steering {
	private String id;
	private List<SteeredDeliveryService> steeredDeliveryServices;
	private List<Bypass> bypasses = new ArrayList<Bypass>();

	public List<SteeredDeliveryService> getSteeredDeliveryServices() {
		return steeredDeliveryServices;
	}

	public void setSteeredDeliveryServices(final List<SteeredDeliveryService> steeredDeliveryServices) {
		this.steeredDeliveryServices = steeredDeliveryServices;
	}

	public String getId() {
		return id;
	}

	public void setId(final String id) {
		this.id = id;
	}

	public List<Bypass> getBypasses() {
		return bypasses;
	}

	public void setBypasses(final List<Bypass> bypasses) {
		this.bypasses = bypasses;
	}

	public String getBypassDestination(final String requestPath) {
		for (Bypass bypass : bypasses) {
			if (bypass.matches(requestPath)) {
				return bypass.getDestination();
			}
		}

		return null;
	}

	@Override
	@SuppressWarnings("PMD")
	public boolean equals(Object o) {
		if (this == o) return true;
		if (o == null || getClass() != o.getClass()) return false;

		Steering steering = (Steering) o;

		if (id != null ? !id.equals(steering.id) : steering.id != null) return false;
		if (steeredDeliveryServices != null ? !steeredDeliveryServices.equals(steering.steeredDeliveryServices) : steering.steeredDeliveryServices != null)
			return false;
		return bypasses != null ? bypasses.equals(steering.bypasses) : steering.bypasses == null;

	}

	@Override
	@SuppressWarnings("PMD")
	public int hashCode() {
		int result = id != null ? id.hashCode() : 0;
		result = 31 * result + (steeredDeliveryServices != null ? steeredDeliveryServices.hashCode() : 0);
		result = 31 * result + (bypasses != null ? bypasses.hashCode() : 0);
		return result;
	}
}
