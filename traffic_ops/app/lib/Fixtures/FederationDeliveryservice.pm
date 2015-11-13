package Fixtures::FederationDeliveryservice;
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
#
#
use Moose;
extends 'DBIx::Class::EasyFixture';
use namespace::autoclean;
use Digest::SHA1 qw(sha1_hex);

my %definition_for = (
	federation_deliveryservice1 => {
		new   => 'FederationDeliveryservice',
		using => {
			federation      => 1,
			deliveryservice => 1,
		},
	},
	federation_deliveryservice2 => {
		new   => 'FederationDeliveryservice',
		using => {
			federation      => 2,
			deliveryservice => 2,
		},
	},
	federation_deliveryservice3 => {
		new   => 'FederationDeliveryservice',
		using => {
			federation      => 3,
			deliveryservice => 3,
		},
	},
	federation_deliveryservice4 => {
		new   => 'FederationDeliveryservice',
		using => {
			federation      => 4,
			deliveryservice => 4,
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
