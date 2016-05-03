package com.comcast.cdn.traffic_control.traffic_router.core.ds;

import java.util.regex.Pattern;

public class Bypass {
	private String filter;
	private String destination;
	private Pattern filterPattern;

	public String getFilter() {
		return filter;
	}

	public void setFilter(final String filter) {
		this.filter = filter;
		filterPattern = Pattern.compile(filter);
	}

	public String getDestination() {
		return destination;
	}

	public void setDestination(final String destination) {
		this.destination = destination;
	}

	public boolean matches(final String path) {
		return filterPattern.matcher(path).matches();
	}

	@Override
	@SuppressWarnings("PMD")
	public boolean equals(Object o) {
		if (this == o) return true;
		if (o == null || getClass() != o.getClass()) return false;

		Bypass bypass = (Bypass) o;

		if (filter != null ? !filter.equals(bypass.filter) : bypass.filter != null) return false;
		return destination != null ? destination.equals(bypass.destination) : bypass.destination == null;

	}

	@Override
	@SuppressWarnings("PMD")
	public int hashCode() {
		int result = filter != null ? filter.hashCode() : 0;
		result = 31 * result + (destination != null ? destination.hashCode() : 0);
		return result;
	}
}
