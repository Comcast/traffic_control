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

package com.comcast.cdn.traffic_control.traffic_router.core.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.nio.channels.FileLock;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.apache.wicket.ajax.json.JSONException;

import com.ning.http.client.AsyncCompletionHandler;
import com.ning.http.client.AsyncHttpClient;
import com.ning.http.client.AsyncHttpClientConfig;
import com.ning.http.client.Request;
import com.ning.http.client.Response;

/** 
 * 
 * @author jlaue
 *
 */
public class PeriodicResourceUpdater {
	private static final Logger LOGGER = Logger.getLogger(PeriodicResourceUpdater.class);

	private static final AsyncHttpClient asyncHttpClient = new AsyncHttpClient(
			new AsyncHttpClientConfig.Builder()
				.setConnectionTimeoutInMs(10000)
				.build());

	protected int urlSelectStrategy = 0; // 0 = ordered, 1 = random select
	protected int lastSuccessfulUrl = 0; 
	protected String databaseLocation;
	protected final ResourceUrl urls;
	protected ScheduledExecutorService executorService = Executors.newSingleThreadScheduledExecutor();
	protected long pollingInterval;
	protected boolean sourceCompressed = true;

	protected ScheduledFuture<?> scheduledService;

	public PeriodicResourceUpdater(final AbstractUpdatable listener, final ResourceUrl urls, 
			final String location, final long interval, final boolean pauseTilLoaded) {
		this.listener = listener;
		this.urls = urls;
		databaseLocation = location;
		pollingInterval = interval;
		this.pauseTilLoaded = pauseTilLoaded;
	}

	public PeriodicResourceUpdater(final AbstractUpdatable listener, final String[] urla,
			final String location, final int interval, final boolean pauseTilLoaded) {
		this.listener = listener;
		this.urls = new MyResourceUrl(urla);
		databaseLocation = location;
		pollingInterval = interval;
		this.pauseTilLoaded = pauseTilLoaded;
	}
	static class MyResourceUrl implements ResourceUrl{
		private final String[] urla;
		private int i = 0;
		public MyResourceUrl(final String[] urla) {
			this.urla = urla;
		}
		@Override
		public String nextUrl() {
			i++;
			i %= urla.length;
			return urla[i];
		}
	}

	public PeriodicResourceUpdater(final AbstractUpdatable listener,
			final ResourceUrl urls, final String location, 
			final int interval, final boolean pauseTilLoaded) {
		this.listener = listener;
		this.urls = urls;
		databaseLocation = location;
		pollingInterval = interval;
		this.pauseTilLoaded = pauseTilLoaded;
	}

	public void destroy() {
		executorService.shutdownNow();

		while (!asyncHttpClient.isClosed()) {
			LOGGER.warn("closing");
			asyncHttpClient.close();
		}
	}

	/**
	 * Gets pollingInterval.
	 * 
	 * @return the pollingInterval
	 */
	public long getPollingInterval() {
		if(pollingInterval == 0) { return 66000; }
		return pollingInterval;
	}

	final private Runnable updater = new Runnable() {
		@Override
		public void run() {
			updateDatabase();
		}
	};

	private boolean hasBeenLoaded = false;

	final private AbstractUpdatable listener;
	final private boolean pauseTilLoaded;

	public void init() {
		putCurrent();
		LOGGER.warn("Starting schedule with interval: "+getPollingInterval() + " : "+TimeUnit.MILLISECONDS);
		scheduledService = executorService.scheduleWithFixedDelay(updater, 0, getPollingInterval(), TimeUnit.MILLISECONDS);
		// wait here until something is loaded
		final File existingDB = new File(databaseLocation);
		if(pauseTilLoaded ) {
			while(!existingDB.exists()) {
				LOGGER.warn("Waiting for valid: "+databaseLocation );
				try {
					Thread.sleep(getPollingInterval());
				} catch (InterruptedException e) {
				}
			}
		}
	}

	private synchronized void putCurrent() {
		final File existingDB = new File(databaseLocation);
		if(existingDB.exists()) {
			try {
				listener.update(IOUtils.toString(new FileReader(existingDB)));
			} catch (Exception e) {
				LOGGER.warn(e,e);
			}
		}
	}

	public synchronized boolean updateDatabase() {
		final File existingDB = new File(databaseLocation);
		try {
			if (!hasBeenLoaded || needsUpdating(existingDB)) {
				asyncHttpClient.executeRequest(getRequest(urls.nextUrl()), new UpdateHandler()); // AsyncHandlers are NOT thread safe; one instance per request
				return true;
			} else {
				LOGGER.info("Database " + existingDB.getAbsolutePath() + " does not require updating.");
			}
		} catch (final Exception e) {
			LOGGER.warn(e.getMessage(), e);
		}
		return false;
	}

	public synchronized boolean updateDatabase(final String newDB) {
		final File existingDB = new File(databaseLocation);
		try {
			if (newDB != null && !filesEqual(existingDB, newDB)) {
				LOGGER.debug("updating " + listener);
				LOGGER.debug("existing db size: " + existingDB.length());
				LOGGER.debug("incoming db size: " + newDB.length());

				if (listener.update(newDB)) {
					copyDatabase(existingDB, newDB);
					LOGGER.info("updated " + existingDB.getAbsolutePath());
					listener.setLastUpdated(System.currentTimeMillis());
					listener.complete();
				} else {
					LOGGER.warn("File rejected: " + existingDB.getAbsolutePath());
				}
			} else {
				listener.noChange();
				LOGGER.debug("File unchanged: " + existingDB.getAbsolutePath());
			}
			hasBeenLoaded = true;
			return true;
		} catch (final Exception e) {
			LOGGER.warn(e.getMessage(), e);
		}
		return false;
	}

	public void setDatabaseLocation(final String databaseLocation) {
		this.databaseLocation = databaseLocation;
	}

//	public void setDataBaseURL(final Model<String> url, final long refresh) {
//		if(refresh !=0 && refresh != pollingInterval) {
//			scheduledService.cancel(false);
//			this.pollingInterval = refresh;
//			LOGGER.info("restarting schedule with interval: "+refresh);
//			init();
//		}
//		if ((url != null) && !url.equals(dataBaseURL)
//				|| (refresh!=0 && refresh!=pollingInterval)) {
//			this.dataBaseURL = url;
//			updateDatabase();
//		}
//	}

	/**
	 * Sets executorService.
	 * 
	 * @param executorService
	 *            the executorService to set
	 */
	public void setExecutorService(final ScheduledExecutorService es) {
		executorService = es;
	}

	/**
	 * Sets pollingInterval.
	 * 
	 * @param pollingInterval
	 *            the pollingInterval to set
	 */
	public void setPollingInterval(final long pollingInterval) {
		this.pollingInterval = pollingInterval;
	}

	boolean filesEqual(final File a, final String newDB) throws IOException {
		if(!a.exists() && newDB == null) { return true; }
		if(!a.exists() || newDB == null) { return false; }
		if(a.length() != newDB.length()) { return false; }
		final FileInputStream fis = new FileInputStream(a);
		final String md5a = org.apache.commons.codec.digest.DigestUtils.md5Hex(fis);
		fis.close();
		final InputStream is = IOUtils.toInputStream(newDB);
		final String md5b = org.apache.commons.codec.digest.DigestUtils.md5Hex(is);
		is.close();
		if(md5a.equals(md5b)) { return true; }
		return false;
	}
	protected synchronized void copyDatabase(final File existingDB, final String newDB) throws IOException {
		final StringReader in = new StringReader(newDB);
		final FileOutputStream out = new FileOutputStream(existingDB);
		final FileLock lock = out.getChannel().tryLock();
		if (lock != null) {
			LOGGER.debug("Updating database " + existingDB.getAbsolutePath());
			IOUtils.copy(in, out);
			existingDB.setReadable(true, false);
			existingDB.setWritable(true, true);
			lock.release();
		} else {
			LOGGER.info("Database " + existingDB.getAbsolutePath() + " locked by another process.");
		}
		IOUtils.closeQuietly(in);
		IOUtils.closeQuietly(out);
	}

	protected boolean needsUpdating(final File existingDB) {
		final long now = System.currentTimeMillis();
		final long fileTime = existingDB.lastModified();
		final long pollingIntervalInMS = getPollingInterval();
		return ((fileTime + pollingIntervalInMS) < now);
	}

	private class UpdateHandler extends AsyncCompletionHandler<Object> {

		public UpdateHandler() {
		}

		@Override
		public Integer onCompleted(final Response response) throws JSONException, IOException {
			// Do something with the Response
			final int code = response.getStatusCode();

			if (code != 200) {
				return code;
			}

			updateDatabase(response.getResponseBody());

			return code;
		}

		@Override
		public void onThrowable(final Throwable t){
			if (LOGGER.isDebugEnabled()) {
				LOGGER.warn(t,t);
			} else {
				LOGGER.warn(t);
			}
		}
	};

	private Request getRequest(final String url) {
		LOGGER.debug("Creating request for " + url);
		return asyncHttpClient.prepareGet(url).build();
	}
}