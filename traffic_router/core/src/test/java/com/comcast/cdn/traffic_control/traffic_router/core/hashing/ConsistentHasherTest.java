package com.comcast.cdn.traffic_control.traffic_router.core.hashing;

import com.comcast.cdn.traffic_control.traffic_router.core.hash.ConsistentHasher;
import com.comcast.cdn.traffic_control.traffic_router.core.hash.DefaultHashable;
import com.comcast.cdn.traffic_control.traffic_router.core.hash.Hashable;
import com.comcast.cdn.traffic_control.traffic_router.core.hash.MD5HashFunction;
import com.comcast.cdn.traffic_control.traffic_router.core.hash.NumberSearcher;
import org.junit.Before;
import org.junit.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.lessThan;
import static org.hamcrest.core.AnyOf.anyOf;
import static org.hamcrest.core.IsEqual.equalTo;
import static org.junit.Assert.assertThat;
import static org.mockito.MockitoAnnotations.initMocks;

public class ConsistentHasherTest {
	@Mock
	MD5HashFunction md5HashFunction = new MD5HashFunction();

	@Mock
	NumberSearcher numberSearcher = new NumberSearcher();

	@InjectMocks
	DefaultHashable hashable1 = new DefaultHashable();

	@InjectMocks
	DefaultHashable hashable2 = new DefaultHashable();

	@InjectMocks
	DefaultHashable hashable3 =  new DefaultHashable();

	List<DefaultHashable> hashables = new ArrayList<DefaultHashable>();

	@InjectMocks
	ConsistentHasher consistentHasher;

	@Before
	public void before() {
		hashable1.generateHashes("hashId1", 100);
		hashable2.generateHashes("hashId2", 100);
		hashable3.generateHashes("hashId3", 100);

		hashables.add(hashable1);
		hashables.add(hashable2);
		hashables.add(hashable3);

		initMocks(this);
	}

	@Test
	public void itHashes() throws Exception {
		DefaultHashable hashable = consistentHasher.selectHashable(hashables, "some-string", false);
		assertThat(hashable, anyOf(equalTo(hashable1), equalTo(hashable2), equalTo(hashable3)));
		DefaultHashable nextHashable = consistentHasher.selectHashable(hashables, "some-string", false);
		assertThat(nextHashable, equalTo(hashable));
	}

	@Test
	public void itHashesMoreThanOne() throws Exception {
		List<DefaultHashable> results = consistentHasher.selectHashables(hashables, 2, "some-string", false);
		assertThat(results.size(), equalTo(2));
		assertThat(results.get(0), anyOf(equalTo(hashable1), equalTo(hashable2), equalTo(hashable3)));
		assertThat(results.get(1), anyOf(equalTo(hashable1), equalTo(hashable2), equalTo(hashable3)));

		assertThat(consistentHasher.selectHashables(hashables, 2, "some-string", false), equalTo(results));
		assertThat(consistentHasher.selectHashables(hashables, 2000000000, "some-string", true), equalTo(hashables));
	}

	@Test
	public void itemsMigrateFromSmallerToLargerBucket() {
		List<String> randomPaths = new ArrayList<>();

		for (int i = 0; i < 10000; i++) {
			randomPaths.add(generateRandomPath());
		}

		Hashable smallerBucket = new DefaultHashable().generateHashes("Small One", 10000);
		Hashable largerBucket = new DefaultHashable().generateHashes("Larger bucket", 90000);

		List<Hashable> buckets = new ArrayList<>();
		buckets.add(smallerBucket);
		buckets.add(largerBucket);

		Map<Hashable, List<String>> hashedPaths = new HashMap<>();
		hashedPaths.put(smallerBucket, new ArrayList<String>());
		hashedPaths.put(largerBucket, new ArrayList<String>());

		for (String randomPath : randomPaths) {
			Hashable hashable = consistentHasher.selectHashable(buckets, randomPath, false);
			hashedPaths.get(hashable).add(randomPath);
		}

		Hashable grownBucket = new DefaultHashable().generateHashes("Small One", 20000);
		Hashable shrunkBucket = new DefaultHashable().generateHashes("Larger bucket", 80000);

		List<Hashable> changedBuckets = new ArrayList<>();
		changedBuckets.add(grownBucket);
		changedBuckets.add(shrunkBucket);

		Map<Hashable, List<String>> rehashedPaths = new HashMap<>();
		rehashedPaths.put(grownBucket, new ArrayList<String>());
		rehashedPaths.put(shrunkBucket, new ArrayList<String>());

		for (String randomPath : randomPaths) {
			Hashable hashable = consistentHasher.selectHashable(changedBuckets, randomPath, false);
			rehashedPaths.get(hashable).add(randomPath);
		}

		assertThat(rehashedPaths.get(grownBucket).size(), greaterThan(hashedPaths.get(smallerBucket).size()));
		assertThat(rehashedPaths.get(shrunkBucket).size(), lessThan(hashedPaths.get(largerBucket).size()));

		for (String path : hashedPaths.get(smallerBucket)) {
			assertThat(rehashedPaths.get(grownBucket).contains(path), equalTo(true));
		}

		for (String path : rehashedPaths.get(shrunkBucket)) {
			assertThat(hashedPaths.get(largerBucket).contains(path), equalTo(true));
		}
	}

	String alphanumericCharacters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWZYZ";
	String exampleValidPathCharacters = alphanumericCharacters + "/=;()-.";

	Random random = new Random(1462307930227L);
	String generateRandomPath() {
		int pathLength = 60 + random.nextInt(61);

		StringBuilder stringBuilder = new StringBuilder("/");
		for (int i = 0; i < 4; i++) {
			int index = random.nextInt(alphanumericCharacters.length());
			stringBuilder.append(alphanumericCharacters.charAt(index));
		}

		stringBuilder.append("/");

		for (int i = 0; i < pathLength; i++) {
			int index = random.nextInt(exampleValidPathCharacters.length());
			stringBuilder.append(exampleValidPathCharacters.charAt(index));
		}

		return stringBuilder.toString();
	}
}
