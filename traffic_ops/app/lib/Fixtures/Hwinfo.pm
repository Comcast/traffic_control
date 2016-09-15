package Fixtures::Hwinfo;
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
use Digest::SHA1 qw(sha1_hex);

my %definition_for = (
	hw1 => {
		new   => 'Hwinfo',
		using => {
			id          => 1,
			serverid    => 1,
			description => 'BACKPLANE FIRMWA',
			val         => '7.0.0.29',
		},
	},
	hw2 => {
		new   => 'Hwinfo',
		using => {
			id          => 2,
			serverid    => 2,
			description => 'DRAC FIRMWA',
			val         => '1.0.0.29',
		},
	},
	hw3 => {
		new   => 'Hwinfo',
		using => {
			id          => 3,
			serverid    => 2,
			description => 'ServiceTag',
			val         => 'XXX',
		},
	},
	hw4 => {
		new   => 'Hwinfo',
		using => {
			id          => 4,
			serverid    => 2,
			description => 'Manufacturer',
			val         => 'Dell Inc.',
		},
	},
	hw5 => {
		new   => 'Hwinfo',
		using => {
			id          => 5,
			serverid    => 2,
			description => 'Model',
			val         => 'Beetle',
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
