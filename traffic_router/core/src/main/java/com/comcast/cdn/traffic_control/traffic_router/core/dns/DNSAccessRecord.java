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

package com.comcast.cdn.traffic_control.traffic_router.core.dns;

import com.comcast.cdn.traffic_control.traffic_router.geolocation.Geolocation;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.ResultDetails;
import com.comcast.cdn.traffic_control.traffic_router.core.router.StatTracker.Track.ResultType;
import org.xbill.DNS.Message;

import java.net.InetAddress;

// Using Josh Bloch Builder pattern so suppress these warnings.
@SuppressWarnings({"PMD.MissingStaticMethodInNonInstantiatableClass",
        "PMD.AccessorClassGeneration",
        "PMD.CyclomaticComplexity"})
public final class DNSAccessRecord {
    private final long queryInstant;
    private final InetAddress client;
    private final Message dnsMessage;
    private final ResultType resultType;
    private final ResultDetails resultDetails;
    private final Geolocation resultLocation;

    public long getQueryInstant() {
        return queryInstant;
    }

    public InetAddress getClient() {
        return client;
    }

    public Message getDnsMessage() {
        return dnsMessage;
    }

    public ResultType getResultType() {
        return resultType;
    }

    public ResultDetails getResultDetails() {
        return resultDetails;
    }

    public Geolocation getResultLocation() {
        return resultLocation;
    }

    public static class Builder {
        private final long queryInstant;
        private final InetAddress client;
        private Message dnsMessage;
        private ResultType resultType;
        private ResultDetails resultDetails;
        private Geolocation resultLocation;

        public Builder(final long queryInstant, final InetAddress client) {
            this.queryInstant = queryInstant;
            this.client = client;
        }

        public Builder dnsMessage(final Message query) {
            this.dnsMessage = query;
            return this;
        }

        public Builder resultType(final ResultType resultType) {
            this.resultType = resultType;
            return this;
        }

        public Builder resultDetails(final ResultDetails resultDetails) {
            this.resultDetails = resultDetails;
            return this;
        }

        public Builder resultLocation(final Geolocation resultLocation) {
            this.resultLocation = resultLocation;
            return this;
        }

        public DNSAccessRecord build() {
            return new DNSAccessRecord(this);
        }
    }

    private DNSAccessRecord(final Builder builder) {
        queryInstant = builder.queryInstant;
        client = builder.client;
        dnsMessage = builder.dnsMessage;
        resultType = builder.resultType;
        resultDetails = builder.resultDetails;
        resultLocation = builder.resultLocation;
    }

}
