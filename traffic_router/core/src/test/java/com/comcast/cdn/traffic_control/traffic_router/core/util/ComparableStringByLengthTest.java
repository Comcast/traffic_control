package com.comcast.cdn.traffic_control.traffic_router.core.util;

import org.junit.Test;

import java.util.Iterator;
import java.util.Set;
import java.util.TreeSet;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.junit.Assert.fail;

public class ComparableStringByLengthTest {

	@Test
	public void itDoesNotAllowNullOrEmptyString() {
		try {
			new ComparableStringByLength(null);
			fail("Should have caught IllegalArugmentException");
		} catch (IllegalArgumentException e) {
			assertThat(e.getMessage(), equalTo("String parameter must be non-null and non-empty"));
		}

		try {
			new ComparableStringByLength("");
			fail("Should have caught IllegalArgumentException");
		} catch (IllegalArgumentException e) {
			assertThat(e.getMessage(), equalTo("String parameter must be non-null and non-empty"));
		}
	}

	@Test
	public void itSortsAscendingToShorterStrings() {
		String[] strings = new String[] {
			"a", "ba", "b", "bac", "ab", "abc"
		};

		Set set = new TreeSet();
		for (String string : strings) {
			set.add(new ComparableStringByLength(string));
		}

		Iterator<ComparableStringByLength> iterator = set.iterator();

		assertThat(iterator.next().toString(), equalTo("abc"));
		assertThat(iterator.next().toString(), equalTo("bac"));
		assertThat(iterator.next().toString(), equalTo("ab"));
		assertThat(iterator.next().toString(), equalTo("ba"));
		assertThat(iterator.next().toString(), equalTo("a"));
		assertThat(iterator.next().toString(), equalTo("b"));
	}

	@Test
	public void itProperlySupportsEquals() {
		ComparableStringByLength abc = new ComparableStringByLength("abc");
		ComparableStringByLength def = abc;

		assertThat(abc.equals(def), equalTo(true));
		assertThat(abc.equals(new ComparableStringByLength("abc")), equalTo(true));
		assertThat(abc.equals(null), equalTo(false));
		assertThat(abc.equals(""), equalTo(false));
		assertThat(abc.equals(new Long(1L)), equalTo(false));
	}

	@Test
	public void itUsesStringFieldForHashcode() {
		assertThat(new ComparableStringByLength("abc").hashCode(), equalTo("abc".hashCode()));
	}
}
