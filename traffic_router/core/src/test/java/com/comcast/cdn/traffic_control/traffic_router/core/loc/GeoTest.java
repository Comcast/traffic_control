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

package com.comcast.cdn.traffic_control.traffic_router.core.loc;

import static org.junit.Assert.assertNotNull;

import org.apache.log4j.Logger;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import org.springframework.context.ApplicationContext;

import com.comcast.cdn.traffic_control.traffic_router.core.TestBase;

public class GeoTest {
	private static final Logger LOGGER = Logger.getLogger(GeoTest.class);

	private GeolocationDatabaseUpdater geolocationDatabaseUpdater;
	private GeolocationService geolocationService;
	private NetworkUpdater networkUpdater;
	private static ApplicationContext context;

	@BeforeClass
	public static void setUpBeforeClass() throws Exception {
		try {
			context = TestBase.getContext();
		} catch(Exception e) {
			e.printStackTrace();
		}
	}

	@Before
	public void setUp() throws Exception {
		geolocationDatabaseUpdater = (GeolocationDatabaseUpdater) context.getBean("geolocationDatabaseUpdater");
		networkUpdater = (NetworkUpdater) context.getBean("networkUpdater");
		geolocationService = (GeolocationService) context.getBean("GeolocationService");

		while (!networkUpdater.isLoaded()) {
			LOGGER.info("Waiting for a valid location database before proceeding");
			Thread.sleep(1000);
		}

		while (!geolocationDatabaseUpdater.isLoaded()) {
			LOGGER.info("Waiting for a valid location database before proceeding");
			Thread.sleep(1000);
		}
	}

	@Test
	public void testIps() {
		try {
			final String testips[][] = {
					{"40.40.40.40","cache-group-1"},
					{"2607:fcc8:a9c0:1e00:8dcd:82a8:169f:bb03", "cache-group-2"}
			};
			for(int i = 0; i < testips.length; i++) {
				Geolocation location = geolocationService.location(testips[i][0]);
				assertNotNull(location);
				String loc = location.toString();
				LOGGER.info(String.format("result for ip=%s: %s\n",testips[i][0], loc));
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
