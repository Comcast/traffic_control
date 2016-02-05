package Fixtures::Deliveryservice;
#
# Copyright 2015 Comcast Cable Communications Management, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
use Moose;
extends 'DBIx::Class::EasyFixture';
use namespace::autoclean;

my %definition_for = (
	ds_cdn1 => {
		new   => 'Deliveryservice',
		using => {
			id                   => 1,
			xml_id               => 'test-ds1',
			active               => 1,
			dscp                 => 40,
			signed               => 0,
			qstring_ignore       => 0,
			geo_limit            => 0,
			http_bypass_fqdn     => '',
			dns_bypass_ip        => '',
			dns_bypass_ttl       => undef,
			ccr_dns_ttl          => 3600,
			global_max_mbps      => 0,
			global_max_tps       => 0,
			long_desc            => 'test-ds1 long_desc',
			long_desc_1          => 'test-ds1 long_desc_1',
			long_desc_2          => 'test-ds1 long_desc_2',
			max_dns_answers      => 0,
			protocol             => 0,
			org_server_fqdn      => 'http://test-ds1.edge',
			info_url             => 'http://test-ds1.edge/info_url.html',
			miss_lat             => '41.881944',
			miss_long            => '-87.627778',
			check_path           => '/crossdomain.xml',
			type                 => 8,
			profile              => 3,
			cdn_id               => 1,
			ipv6_routing_enabled => 1,
			protocol             => 1,
			display_name         => 'test-ds1-displayname',
			initial_dispersion   => 1,
			regional_geo_blocking => 1,
		},
	},
	ds_cdn2 => {
		new   => 'Deliveryservice',
		using => {
			id                 => 2,
			xml_id             => 'test-ds2',
			active             => 1,
			dscp               => 40,
			signed             => 0,
			qstring_ignore     => 0,
			geo_limit          => 0,
			http_bypass_fqdn   => '',
			dns_bypass_ip      => '',
			dns_bypass_ttl     => undef,
			ccr_dns_ttl        => 3600,
			global_max_mbps    => 0,
			global_max_tps     => 0,
			long_desc          => 'test-ds2 long_desc',
			long_desc_1        => 'test-ds2 long_desc_1',
			long_desc_2        => 'test-ds2 long_desc_2',
			max_dns_answers    => 0,
			protocol           => 0,
			org_server_fqdn    => 'http://test-ds2.edge',
			info_url           => 'http://test-ds2.edge/info_url.html',
			miss_lat           => '41.881944',
			miss_long          => '-87.627778',
			check_path         => '/crossdomain.xml',
			type               => 1,
			profile            => 3,
			cdn_id             => 1,
			display_name       => 'test-ds2-displayname',
			initial_dispersion => 1,
			regional_geo_blocking => 0,
		},
	},
	ds_cdn3 => {
		new   => 'Deliveryservice',
		using => {
			id                 => 3,
			xml_id             => 'test-ds3',
			active             => 1,
			dscp               => 40,
			signed             => 0,
			qstring_ignore     => 0,
			geo_limit          => 0,
			http_bypass_fqdn   => '',
			dns_bypass_ip      => '',
			dns_bypass_ttl     => undef,
			ccr_dns_ttl        => 3600,
			global_max_mbps    => 0,
			global_max_tps     => 0,
			long_desc          => 'test-ds3 long_desc',
			long_desc_1        => 'test-ds3 long_desc_1',
			long_desc_2        => 'test-ds3 long_desc_2',
			max_dns_answers    => 0,
			protocol           => 0,
			org_server_fqdn    => 'http://test-ds3.edge',
			info_url           => 'http://test-ds3.edge/info_url.html',
			miss_lat           => '41.881944',
			miss_long          => '-87.627778',
			check_path         => '/crossdomain.xml',
			type               => 1,
			profile            => 3,
			cdn_id             => 1,
			display_name       => 'test-ds3-displayname',
			initial_dispersion => 1,
			regional_geo_blocking => 0,
		},
	},
	ds_cdn4 => {
		new   => 'Deliveryservice',
		using => {
			id                 => 4,
			xml_id             => 'test-ds4',
			active             => 1,
			dscp               => 40,
			signed             => 0,
			qstring_ignore     => 0,
			geo_limit          => 0,
			http_bypass_fqdn   => '',
			dns_bypass_ip      => '',
			dns_bypass_ttl     => undef,
			ccr_dns_ttl        => 3600,
			global_max_mbps    => 0,
			global_max_tps     => 0,
			long_desc          => 'test-ds4 long_desc',
			long_desc_1        => 'test-ds4 long_desc_1',
			long_desc_2        => 'test-ds4 long_desc_2',
			max_dns_answers    => 0,
			protocol           => 0,
			org_server_fqdn    => 'http://test-ds4.edge',
			info_url           => 'http://test-ds4.edge/info_url.html',
			miss_lat           => '41.881944',
			miss_long          => '-87.627778',
			check_path         => '/crossdomain.xml',
			type               => 1,
			profile            => 3,
			cdn_id             => 1,
			display_name       => 'test-ds4-displayname',
			initial_dispersion => 1,
			regional_geo_blocking => 0,
		},
	},
);

sub get_definition {
	my ( $self, $name ) = @_;
	return $definition_for{$name};
}

sub all_fixture_names {
	return keys %definition_for;
}

__PACKAGE__->meta->make_immutable;

1;
