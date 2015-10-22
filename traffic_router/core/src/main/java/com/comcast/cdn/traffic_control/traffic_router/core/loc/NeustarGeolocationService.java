package com.comcast.cdn.traffic_control.traffic_router.core.loc;

import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.util.Date;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import org.apache.log4j.Logger;

import com.quova.bff.reader.exception.AddressNotFoundException;
import com.quova.bff.reader.io.GPDatabaseReader;
import com.quova.bff.reader.model.GeoPointResponse;

public class NeustarGeolocationService implements GeolocationService {
	private static final Logger LOGGER = Logger
			.getLogger(NeustarGeolocationService.class);
	private final ReadWriteLock lock = new ReentrantReadWriteLock();
	private String databaseName;
	private GPDatabaseReader databaseReader;
	private boolean initialized = false;

	@Override
	@SuppressWarnings("PMD.EmptyCatchBlock")
	public Geolocation location(final String ip) throws GeolocationException {
		Geolocation location = null;
		lock.readLock().lock();
		try {
			if (databaseReader != null) {
				final String[] parts = ip.split("/");
				final InetAddress address = InetAddress.getByName(parts[0]);
				final GeoPointResponse response = databaseReader
						.ipInfo(address);
				if (isResponseValid(response)) {
					location = new Geolocation(response.getLatitude(),
							response.getLongitude(), response.getCity(),
							response.getCountryCode(), response.getCountry(),
							response.getPostalCode());
				}
			}
		} catch (AddressNotFoundException ex) {
			// this is fine; we'll just return null below and send them to
			// Chicago
		} catch (Exception ex) {
			LOGGER.error(ex, ex);
			throw new GeolocationException(
					"Caught exception while attempting to determine location: "
							+ ex.getMessage(), ex);
		} finally {
			lock.readLock().unlock();
		}
		return location;
	}

	private boolean isResponseValid(final GeoPointResponse response) {
		if (response == null) {
			return false;
		} else if (response.getCity() == null || response.getCity().isEmpty()) {
			return false;
		}
		return true;
	}

	protected GPDatabaseReader createDatabaseReader() throws IOException {
		final File database = new File(getDatabaseName());
		if (database.exists()) {
			LOGGER.info("Loading Neustar db: " + database);
			final GPDatabaseReader reader = new GPDatabaseReader.Builder(
					database).build();
			setInitialized(true);
			return reader;
		} else {
			LOGGER.warn(database + " does not exist yet!");
			return null;
		}
	}

	public void init() {
		lock.writeLock().lock();

		try {
			databaseReader = createDatabaseReader();
		} catch (final IOException ex) {
			LOGGER.fatal(
					"Caught exception while trying to open geolocation database "
							+ getDatabaseName() + ": " + ex.getMessage(), ex);
		} finally {
			lock.writeLock().unlock();
		}
	}

	public void destroy() {
		lock.writeLock().lock();

		try {
			if (databaseReader != null) {
				databaseReader.close();
				databaseReader = null;
			}
		} catch (IOException ex) {
			LOGGER.warn(
					"Caught exception while trying to close geolocation database reader: "
							+ ex.getMessage(), ex);
		} finally {
			lock.writeLock().unlock();
		}
	}

	@Override
	public void reloadDatabase() throws IOException {
		lock.writeLock().lock();
		final long t1 = new Date().getTime();
		try {
			if (databaseReader != null) {
				databaseReader.close();
			}
			databaseReader = createDatabaseReader();
			final long t2 = new Date().getTime();
			LOGGER.info("Time taken to reload the database: " + (t2 - t1));
		} finally {
			lock.writeLock().unlock();
		}
	}

	@Override
	public void verifyDatabase(final File dbFile) throws IOException {
		LOGGER.info("Attempting to verify " + dbFile.getAbsolutePath());
		final GPDatabaseReader dbr = new GPDatabaseReader.Builder(dbFile)
				.build();
		dbr.close();
	}

	public String getDatabaseName() {
		return databaseName;
	}

	public void setDatabaseName(final String databaseName) {
		this.databaseName = databaseName;
	}

	@Override
	public boolean isInitialized() {
		return initialized;
	}

	private void setInitialized(final boolean initialized) {
		this.initialized = initialized;
	}
}
