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

package com.comcast.cdn.traffic_control.traffic_monitor.wicket.components;

import com.comcast.cdn.traffic_control.traffic_monitor.health.DeliveryServiceStateRegistry;
import org.apache.wicket.request.mapper.parameter.PageParameters;

public class DsDetailsPage extends StateDetailsPage {
	private static final long serialVersionUID = 1L;

	public DsDetailsPage(final PageParameters pars) {
		this(pars.get("id").toString());
	}

	public DsDetailsPage(final String idStr) {
		super(idStr, "id", DeliveryServiceStateRegistry.getInstance());
	}
}
