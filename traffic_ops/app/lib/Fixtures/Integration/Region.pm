package Fixtures::Integration::Region;

# Do not edit! Generated code.
# See https://github.com/Comcast/traffic_control/wiki/The%20Kabletown%20example

use Moose;
extends 'DBIx::Class::EasyFixture';
use namespace::autoclean;

my %definition_for = (
	'0' => {
		new => 'Region',
		using => {
			division => '2',
			last_updated => '2015-12-10 15:43:45',
			name => 'Central',
		},
	},
	'1' => {
		new => 'Region',
		using => {
		division => '1',
			last_updated => '2015-12-10 15:43:45',
			name => 'East',
		},
	},
	'2' => {
		new => 'Region',
		using => {
			last_updated => '2015-12-10 15:43:45',
			name => 'West',
			division => '2',
		},
	},
);

sub name {
		return "Region";
}

sub get_definition {
		my ( $self,
			$name ) = @_;
		return $definition_for{$name};
}

sub all_fixture_names {
	# sort by db name to guarantee insertion order
	return (sort {
		$definition_for{$a}{using}{name} cmp $definition_for{$b}{using}{name} } keys %definition_for);
}

__PACKAGE__->meta->make_immutable;
1;
