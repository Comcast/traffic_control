package Fixtures::Profile;
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
	## id => 1
	EDGE1 => {
		new   => 'Profile',
		using => {
			name        => 'EDGE1',
			description => 'edge description',
		},
	},
	## id => 2
	CCR1 => {
		new   => 'Profile',
		using => {
			name        => 'CCR1',
			description => 'ccr description',
		},
	},
	## id => 3
	MID1 => {
		new   => 'Profile',
		using => {
			name        => 'MID1',
			description => 'mid description',
		},
	},
	## id => 4
	RASCAL1 => {
		new   => 'Profile',
		using => {
			name        => 'RASCAL1',
			description => 'rascal description',
		},
	},
	## id => 5
	RASCAL2 => {
		new   => 'Profile',
		using => {
			name        => 'RASCAL2',
			description => 'rascal2 description',
		},
	},
	## id => 6
	RIAK1 => {
		new   => 'Profile',
		using => {
			name        => 'RIAK1',
			description => 'riak description',
		},
	},
);

sub get_definition {
	my ( $self, $name ) = @_;
	return $definition_for{$name};
}

sub all_fixture_names {
	return (sort { $definition_for{$a}{using}{name} cmp $definition_for{$b}{using}{name} } keys %definition_for);
}

__PACKAGE__->meta->make_immutable;

1;
