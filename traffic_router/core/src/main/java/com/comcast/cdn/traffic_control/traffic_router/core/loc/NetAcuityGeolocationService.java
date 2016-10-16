package com.comcast.cdn.traffic_control.traffic_router.core.loc;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.Map;

import com.google.common.base.Preconditions;

import net.digitalenvoy.embedded.EmbeddedAccessor;

/**
 * {@link GeolocationService} implementation that reads a NetAcuity database. The {@link #setDirectory(File)} method
 * <em>must</em> be called before {@link #init()}. The {@link #setMemoryMapped(boolean)} method <em>may</em> be called
 * before {@link #init()}.
 */
public class NetAcuityGeolocationService implements GeolocationService {
    /** The feature code for the NetAcuity Edge database. */
    public static final int EDGE_FEATURE_CODE = 4;

    private File directory;
    private boolean memoryMapped = true;
    private EmbeddedAccessor accessor;
    private boolean initialized;

    /**
     * Set the path to the database files. This must be called exactly once on a given instance, before calling
     * {@link #init()}.
     * 
     * @param directory The directory that contains the database files.
     */
    public void setDirectory(File directory) {
        checkNotInitialized();
        Preconditions.checkNotNull(directory, "Directory is null");
        Preconditions.checkArgument(directory.isDirectory(), "Not a directory: %s", directory.getAbsolutePath());
        this.directory = directory;
    }

    /**
     * Set whether the database files should be memory mapped. If this is set to false then the files will be accessed
     * via {@link RandomAccessFile} instead. This flag is true by default.
     * 
     * @param memoryMapped Whether to memory-map the database files.
     */
    public void setMemoryMapped(boolean memoryMapped) {
        checkNotInitialized();
        this.memoryMapped = memoryMapped;
    }

    /** Throws {@link IllegalStateException} if the instance has not yet been initialized. */
    protected void checkInitialized() {
        if (!initialized) {
            throw new IllegalStateException("Service instance is not yet initialized");
        }
    }

    /** Throws {@link IllegalStateException} if the instance has already been initialized. */
    protected void checkNotInitialized() {
        if (initialized) {
            throw new IllegalStateException("Service instance has already been initialized");
        }
    }

    /**
     * Initialize the service instance.
     * 
     * @throws IOException if there is a problem reading the database files
     */
    public synchronized void init() throws IOException {
        Preconditions.checkNotNull(directory, "Directory is null");
        accessor = EmbeddedAccessor.getEmbeddedAccessor(EDGE_FEATURE_CODE, directory, memoryMapped);
        initialized = true;
    }

    /** Free resources associated with this instance. */
    public synchronized void destroy() {
        accessor = null;
    }

    @Override
    public synchronized boolean isInitialized() {
        return initialized;
    }

    /**
     * NetAcuity databases consist of multiple files stored in a single directory. Thus, the {@link File} instance
     * passed to this method must represent a directory in the filesystem.
     * 
     * @param directory The directory that contains the database files.
     */
    @Override
    public void verifyDatabase(File directory) throws IOException {
        Preconditions.checkNotNull(directory, "Database directory is null");
        Preconditions.checkArgument(directory.isDirectory(), "Not a directory: %s", directory);
        EmbeddedAccessor test = EmbeddedAccessor.getEmbeddedAccessor(EDGE_FEATURE_CODE, directory, false);
        Preconditions.checkArgument(EDGE_FEATURE_CODE == test.getFeatureCode(), "Wrong feature code");
        Preconditions.checkNotNull(test.query("0.0.0.0"), "Invalid response to test query");
    }

    @Override
    public synchronized void reloadDatabase() throws IOException {
        checkInitialized();

        // Clear the reference to the accessor
        final boolean mapped = accessor.isMemoryMapped();
        accessor = null;

        // Try to get the garbage collector to free the mapped files.
        // Otherwise, they could hang around for a while.
        // See http://bugs.java.com/view_bug.do?bug_id=4724038
        if (mapped) {
            System.gc();
        }

        // Reinitialize the accessor
        init();
    }

    @Override
    public Geolocation location(String ip) throws GeolocationException {
        checkInitialized();

        final Map<String, String> map;
        synchronized (this) {
            map = accessor.query(ip);
        }

        return new Geolocation(
                Double.parseDouble(map.get("edge-latitude")),
                Double.parseDouble(map.get("edge-longitude")),
                map.get("edge-city"),
                map.get("edge-country-code"),
                map.get("edge-country"),
                map.get("edge-postal-code"));
    }
}
