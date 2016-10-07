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

package com.comcast.cdn.traffic_control.traffic_router.secure;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.spec.KeySpec;

@SuppressWarnings("PMD.AbstractNaming")
public abstract class Pkcs {
	private final String data;
	private final PrivateKey privateKey;
	private KeySpec keySpec;

	public Pkcs(final String data) throws IOException, GeneralSecurityException {
		this.data = data;
		keySpec = toKeySpec(data);
		privateKey = KeyFactory.getInstance("RSA").generatePrivate(keySpec);
	}

	public String getData() {
		return data;
	}

	public KeySpec getKeySpec() {
		return keySpec;
	}

	public void setKeySpec(final KeySpec keySpec) {
		this.keySpec = keySpec;
	}

	public PrivateKey getPrivateKey() {
		return privateKey;
	}

	public abstract String getHeader();

	public abstract String getFooter();

	private String stripHeaderAndFooter(final String data) {
		return data.replaceAll(getHeader(), "").replaceAll(getFooter(), "").replaceAll("\\s", "");
	}

	protected abstract KeySpec decodeKeySpec(final String data) throws IOException, GeneralSecurityException;

	private KeySpec toKeySpec(final String data) throws IOException, GeneralSecurityException {
		return decodeKeySpec(stripHeaderAndFooter(data));
	}
}
