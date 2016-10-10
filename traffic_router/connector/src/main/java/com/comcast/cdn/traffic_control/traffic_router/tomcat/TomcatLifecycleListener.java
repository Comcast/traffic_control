/*
 * Copyright 2016 Comcast Cable Communications Management, LLC
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

package com.comcast.cdn.traffic_control.traffic_router.tomcat;

import com.comcast.cdn.traffic_control.traffic_router.secure.CertificateDataListener;
import com.comcast.cdn.traffic_control.traffic_router.shared.DeliveryServiceCertificates;
import com.comcast.cdn.traffic_control.traffic_router.shared.DeliveryServiceCertificatesMBean;
import org.apache.catalina.Lifecycle;
import org.apache.catalina.LifecycleEvent;
import org.apache.catalina.LifecycleListener;

import javax.management.MBeanServer;
import javax.management.ObjectName;
import java.lang.management.ManagementFactory;

public class TomcatLifecycleListener implements LifecycleListener {
	protected static org.apache.juli.logging.Log log = org.apache.juli.logging.LogFactory.getLog(TomcatLifecycleListener.class);
	private CertificateDataListener certificateDataListener = new CertificateDataListener();

	@Override
	@SuppressWarnings("PMD.AvoidThrowingRawExceptionTypes")
	public void lifecycleEvent(final LifecycleEvent event) {
		if (!Lifecycle.INIT_EVENT.equals(event.getType())) {
			return;
		}

		try {
			log.info("Registering delivery service certifcates mbean");
			final ObjectName objectName = new ObjectName(DeliveryServiceCertificatesMBean.OBJECT_NAME);

			final MBeanServer platformMBeanServer = ManagementFactory.getPlatformMBeanServer();
			platformMBeanServer.registerMBean(new DeliveryServiceCertificates(), objectName);
			platformMBeanServer.addNotificationListener(objectName, certificateDataListener, null, null);

		} catch (Exception e) {
			throw new RuntimeException("Failed to register MBean " + DeliveryServiceCertificatesMBean.OBJECT_NAME + " " + e.getClass().getSimpleName() + ": " + e.getMessage(), e);
		}
	}

	public CertificateDataListener getCertificateDataListener() {
		return certificateDataListener;
	}

	public void setCertificateDataListener(final CertificateDataListener certificateDataListener) {
		this.certificateDataListener = certificateDataListener;
	}
}
