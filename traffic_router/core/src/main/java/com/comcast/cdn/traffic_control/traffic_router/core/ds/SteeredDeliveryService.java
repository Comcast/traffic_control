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

import com.comcast.cdn.traffic_control.traffic_router.core.hash.DefaultHashable;

public class SteeredDeliveryService extends DefaultHashable {
	private String id;
	private int weight;

	public DefaultHashable generateHashes() {
		return generateHashes(id, weight);
	}

	public void setId(final String id) {
		this.id = id;
	}

	public String getId() {
		return id;
	}

	public void setWeight(final int weight) {
		this.weight = weight;
	}

	public int getWeight() {
		return weight;
	}

	@Override
	@SuppressWarnings("PMD")
	public boolean equals(Object o) {
		if (this == o) return true;
		if (o == null || getClass() != o.getClass()) return false;

		SteeredDeliveryService that = (SteeredDeliveryService) o;

		if (weight != that.weight) return false;
		return id != null ? id.equals(that.id) : that.id == null;

	}

	@Override
	public int hashCode() {
		int result = id != null ? id.hashCode() : 0;
		result = 31 * result + weight;
		return result;
	}
}
