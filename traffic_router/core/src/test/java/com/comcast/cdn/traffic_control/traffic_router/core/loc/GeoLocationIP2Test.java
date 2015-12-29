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

import com.comcast.cdn.traffic_control.traffic_router.core.TestBase;
import org.apache.log4j.Logger;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import org.springframework.context.ApplicationContext;

public class GeoLocationIP2Test {
	private static final Logger LOGGER = Logger.getLogger(GeoLocationIP2Test.class);

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
			LOGGER.info("Network Updater is not loaded, waiting for a valid location database before proceeding");
			Thread.sleep(1000);
		}

		while (!geolocationDatabaseUpdater.isLoaded()) {
			LOGGER.info("GeoLocationDatabaseUpdater is not loaded, waiting for a valid location database before proceeding");
			Thread.sleep(1000);
		}
	}

	@Test
	public void testGeoLookupPerformance() throws GeolocationException {
		long start = System.currentTimeMillis();
		int total = 100000;

		for (int i = 0; i <= total; i++) {
			geolocationService.location("10.0.0.1");
		}

		long duration = System.currentTimeMillis() - start;
		double tps = (double) total / ((double) duration / 1000);

		System.out.println(geolocationService.getClass().getName() + " lookup duration: " + duration + "ms, " + tps + " tps");
	}
}
