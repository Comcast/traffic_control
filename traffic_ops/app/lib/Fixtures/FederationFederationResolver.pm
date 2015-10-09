package Fixtures::FederationFederationResolver;
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
	federation1 => {
		new   => 'FederationFederationResolver',
		using => {
			federation          => 1,
			federation_resolver => 1,
		},
	},
	federation2 => {
		new   => 'FederationFederationResolver',
		using => {
			federation          => 1,
			federation_resolver => 2,
		},
	},
	federation3 => {
		new   => 'FederationFederationResolver',
		using => {
			federation          => 1,
			federation_resolver => 3,
		},
	},
	federation4 => {
		new   => 'FederationFederationResolver',
		using => {
			federation          => 1,
			federation_resolver => 4,
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
