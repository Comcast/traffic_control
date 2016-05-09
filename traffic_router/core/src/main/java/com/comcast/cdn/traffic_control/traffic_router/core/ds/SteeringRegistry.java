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

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.log4j.Logger;

import java.io.IOException;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SteeringRegistry {
	private static final Logger LOGGER = Logger.getLogger(SteeringRegistry.class);

	private final Map<String, Steering> registry = new HashMap<String, Steering>();
	private final ObjectMapper objectMapper = new ObjectMapper(new JsonFactory());

	public void update(final String json) {
		Map<String, List<Steering>> m;
		try {
			m = objectMapper.readValue(json, new TypeReference<HashMap<String, List<Steering>>>() { });
		} catch (IOException e) {
			LOGGER.error("Failed consuming Json data to populate steering registry, keeping current data:" + e.getMessage());
			return;
		}

		final List<Steering> steerings = m.values().iterator().next();
		final Map<String, Steering> newSteerings = new HashMap<String, Steering>();

		for (Steering steering : steerings) {
			newSteerings.put(steering.getId(), steering);
		}

		registry.clear();
		registry.putAll(newSteerings);
	}

	public boolean has(final String steeringId) {
		return registry.containsKey(steeringId);
	}

	public Steering get(final String steeringId) {
		return registry.get(steeringId);
	}

	public Collection<Steering> getAll() {
		return registry.values();
	}
}
