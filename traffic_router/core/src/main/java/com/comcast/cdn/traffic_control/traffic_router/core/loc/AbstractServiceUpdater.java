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

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.Date;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.zip.GZIPInputStream;

import org.apache.commons.compress.archivers.tar.TarArchiveEntry;
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream;
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.apache.wicket.ajax.json.JSONException;

import com.comcast.cdn.traffic_control.traffic_router.core.router.TrafficRouterManager;

public abstract class AbstractServiceUpdater {
	private static final Logger LOGGER = Logger.getLogger(AbstractServiceUpdater.class);

	protected String dataBaseURL;
	protected String databaseLocation;
	protected ScheduledExecutorService executorService;
	private long pollingInterval;
	protected boolean loaded = false;
	protected ScheduledFuture<?> scheduledService;
	private TrafficRouterManager trafficRouterManager;

	public void destroy() {
		executorService.shutdownNow();
	}

	/**
	 * Gets dataBaseURL.
	 * 
	 * @return the dataBaseURL
	 */
	public String getDataBaseURL() {
		return dataBaseURL;
	}

	/**
	 * Gets pollingInterval.
	 * 
	 * @return the pollingInterval
	 */
	public long getPollingInterval() {
		if(pollingInterval == 0) { return 10000; }
		return pollingInterval;
	}

	final private Runnable updater = new Runnable() {
		@Override
		public void run() {
			updateDatabase();
		}
	};

	public void init() {
		final long pi = getPollingInterval();
		LOGGER.info(getClass().getSimpleName() + " Starting schedule with interval: " + pi + " : " + TimeUnit.MILLISECONDS);
		scheduledService = executorService.scheduleWithFixedDelay(updater, pi, pi, TimeUnit.MILLISECONDS);
	}

	@SuppressWarnings("PMD.CyclomaticComplexity")
	public boolean updateDatabase() {
		final File existingDB = new File(databaseLocation);
		File newDB = null;
		try {
			if (!isLoaded() || needsUpdating(existingDB)) {
				boolean isModified = true;

				try {
					newDB = downloadDatabase(getDataBaseURL(), existingDB);
					trafficRouterManager.trackEvent("last" + getClass().getSimpleName() + "Check");

					// if the remote db's timestamp is less than or equal to ours, the above returns existingDB
					if (newDB == existingDB) {
						isModified = false;
					}
				} catch (Exception e) {
					LOGGER.fatal("Caught exception while attempting to download: " + getDataBaseURL(), e);

					if (!isLoaded()) {
						newDB = existingDB;
					} else {
						throw e;
					}
				}

				if ((!isLoaded() || isModified) && newDB != null && newDB.exists()) {
					verifyDatabase(newDB);
					final boolean isDifferent = copyDatabaseIfDifferent(existingDB, newDB);

					if (!isLoaded() || isDifferent) {
						loadDatabase();
						setLoaded(true);
						trafficRouterManager.trackEvent("last" + getClass().getSimpleName() + "Update");
					} else if (isLoaded() && !isDifferent) {
						newDB.delete();
					}

					return true;
				} else {
					return false;
				}
			} else {
				LOGGER.info("Location database does not require updating.");
			}
		} catch (final Exception e) {
			LOGGER.error(e.getMessage(), e);
		}
		return false;
	}

	abstract public void verifyDatabase(final File dbFile) throws IOException;
	abstract public boolean loadDatabase() throws IOException, JSONException;

	public void setDatabaseLocation(final String databaseLocation) {
		this.databaseLocation = databaseLocation;
	}

	public void setDataBaseURL(final String url, final long refresh) {
		if(refresh !=0 && refresh != pollingInterval) {
			if (scheduledService != null) {
				scheduledService.cancel(false);
			}

			this.pollingInterval = refresh;
			LOGGER.info("Restarting schedule for " + url + " with interval: "+refresh);
			init();
		}
		if ((url != null) && !url.equals(dataBaseURL)
				|| (refresh!=0 && refresh!=pollingInterval)) {
			this.dataBaseURL = url;
			this.setLoaded(false);
			new Thread(updater).start();
		}
	}

	/**
	 * Sets executorService.
	 * 
	 * @param executorService
	 *            the executorService to set
	 */
	public void setExecutorService(final ScheduledExecutorService executorService) {
		this.executorService = executorService;
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

	boolean filesEqual(final File a, final File b) throws IOException {
		if(!a.exists() && !b.exists()) { return true; }
		if(!a.exists() || !b.exists()) { return false; }
		if (a.isDirectory() && b.isDirectory()) {
			return compareDirectories(a, b);
		} else {
			return compareFiles(a, b);
		}
	}
	
	private boolean compareDirectories(final File a, final File b)
			throws IOException {
		boolean equal = true;
		final File[] aFileList = a.listFiles();
		final File[] bFileList = b.listFiles();
		if (aFileList.length == bFileList.length) {
			Arrays.sort(aFileList);
			Arrays.sort(bFileList);
			for (int i = 0; i < aFileList.length; i++) {
				if (aFileList[i].length() != bFileList[i].length()) {
					equal = false;
				}
			}
		} else {
			equal = false;
		}
		return equal;
	}
	
	private boolean compareFiles(final File a, final File b) throws IOException {
		boolean equal = false;
		if (a.length() == b.length()) {
			FileInputStream fis = new FileInputStream(a);
			final String md5a = org.apache.commons.codec.digest.DigestUtils
					.md5Hex(fis);
			fis.close();
			fis = new FileInputStream(b);
			final String md5b = org.apache.commons.codec.digest.DigestUtils
					.md5Hex(fis);
			fis.close();
			if (md5a.equals(md5b)) {
				equal = true;
			}
		}
		return equal;
	}
	
	protected boolean copyDatabaseIfDifferent(final File existingDB,
			final File newDB) throws IOException {
		if (!filesEqual(existingDB, newDB)) {
			if (existingDB.isDirectory() && newDB.isDirectory()) {
				moveDirectory(existingDB, newDB);
				LOGGER.info("Successfully updated location database "
						+ existingDB);
				return true;
			} else {
				if (existingDB != null && existingDB.exists()) {
					existingDB.setReadable(true, true);
					existingDB.setWritable(true, false);
					if (existingDB.isDirectory()) {
						for (File file : existingDB.listFiles()) {
							file.delete();
						}
						LOGGER.debug("Successfully deleted location database under: "
								+ existingDB);
					} else {
						existingDB.delete();
					}
				}

				newDB.setReadable(true, true);
				newDB.setWritable(true, false);
				final boolean renamed = newDB.renameTo(existingDB);

				if (renamed) {
					LOGGER.info("Successfully updated location database "
							+ existingDB);
					return true;
				} else {
					LOGGER.fatal("Unable to rename " + newDB + " to "
							+ existingDB + "; current working directory is "
							+ System.getProperty("user.dir"));
					return false;
				}
			}
		} else {
			LOGGER.info("Location database unchanged.");
			return false;
		}
	}

	private void moveDirectory(final File existingDB, final File newDB)
			throws IOException {
		LOGGER.info("Moving Location database from: " + newDB + ", to: " + existingDB);
		for (File f : existingDB.listFiles()) {
			f.setReadable(true, true);
			f.setWritable(true, false);
			f.delete();
		}
		existingDB.delete();
		Files.move(newDB.toPath(), existingDB.toPath(), StandardCopyOption.ATOMIC_MOVE);
	}
	
	protected boolean sourceCompressed = true;
	protected String tmpPrefix = "loc";
	protected String tmpSuffix = ".dat";
	//TODO: Make this configurable
	protected boolean uncompressDataFile = true;
	protected File downloadDatabase(final String url, final File existingDb) throws IOException {
		LOGGER.info("[" + getClass().getSimpleName() + "] Downloading database: " + url);
		final URL dbURL = new URL(url);
		final HttpURLConnection conn = (HttpURLConnection) dbURL.openConnection();

		if (useModifiedTimestamp(existingDb)) {
			conn.setIfModifiedSince(existingDb.lastModified());
		}

		InputStream in = conn.getInputStream();

		if (conn.getResponseCode() == HttpURLConnection.HTTP_NOT_MODIFIED) {
			LOGGER.info(url + " not modified since our existing database's last update time of " + new Date(existingDb.lastModified()));
			return existingDb;
		}

		if (!uncompressDataFile && sourceCompressed) {
			in = new GZIPInputStream(in);
		}

		final File outputFile = File.createTempFile(tmpPrefix, tmpSuffix);
		final OutputStream out = new FileOutputStream(outputFile);

		IOUtils.copy(in, out);
		IOUtils.closeQuietly(in);
		IOUtils.closeQuietly(out);
		if(uncompressDataFile) {
			final File outputFolder = uncompressTarGZ(outputFile);
			return outputFolder;
		} else {
			return outputFile;
		}
	}

	private boolean useModifiedTimestamp(final File existingDb) {
		return existingDb != null
				&& existingDb.exists()
				&& existingDb.lastModified() > 0
				&& (!existingDb.isDirectory() || existingDb.listFiles().length > 0);
	}
	
	protected File uncompressTarGZ(final File tarFile) throws IOException {
		final String destFolder = tarFile.getParentFile() + File.separator
				+ "location_db";
		final File dest = new File(destFolder);
		dest.mkdir();
		LOGGER.info("Untar: " + tarFile + " to: " + destFolder);

		final TarArchiveInputStream tarIn = new TarArchiveInputStream(
				new GzipCompressorInputStream(new BufferedInputStream(
						new FileInputStream(tarFile))));
		TarArchiveEntry tarEntry = tarIn.getNextTarEntry();
		while (tarEntry != null) {
			final File destPath = new File(dest, tarEntry.getName());
			LOGGER.debug("extracting: " + destPath.getCanonicalPath());
			if (tarEntry.isDirectory()) {
				destPath.mkdirs();
			} else {
				destPath.createNewFile();
				byte[] btoRead = new byte[1024];
				final BufferedOutputStream bout = new BufferedOutputStream(
						new FileOutputStream(destPath));
				int len = 0;
				while ((len = tarIn.read(btoRead)) != -1) {
					bout.write(btoRead, 0, len);
				}
				bout.close();
				btoRead = null;
			}
			tarEntry = tarIn.getNextTarEntry();
		}
		tarIn.close();
		tarFile.delete();
		return dest;
	}
	
	protected boolean needsUpdating(final File existingDB) {
		final long now = System.currentTimeMillis();
		final long fileTime = existingDB.lastModified();
		final long pollingIntervalInMS = getPollingInterval();
		return ((fileTime + pollingIntervalInMS) < now);
	}

	public void setLoaded(final boolean loaded) {
		this.loaded = loaded;
	}

	public boolean isLoaded() {
		return loaded;
	}

	public void setTrafficRouterManager(final TrafficRouterManager trafficRouterManager) {
		this.trafficRouterManager = trafficRouterManager;
	}
}
