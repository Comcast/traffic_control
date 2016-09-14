package Fixtures::Integration::Status;

# Do not edit! Generated code.
# See https://github.com/Comcast/traffic_control/wiki/The%20Kabletown%20example

use Moose;
extends 'DBIx::Class::EasyFixture';
use namespace::autoclean;

my %definition_for = (
	## id => 1
	'0' => {
		new => 'Status',
		using => {
			name => 'ADMIN_DOWN',
			description => 'Temporary down. Edge: XMPP client will send status OFFLINE to CCR, otherwise similar to REPORTED. Mid: Server will not be included in parent.config files for its edge caches',
			last_updated => '2015-12-10 15:43:45',
		},
	},
	## id => 2
	'1' => {
		new => 'Status',
		using => {
			name => 'CCR_IGNORE',
			description => 'Edge: 12M will not include caches in this state in CCR config files. Mid: N/A for now',
			last_updated => '2015-12-10 15:43:45',
		},
	},
	## id => 3
	'2' => {
		new => 'Status',
		using => {
			name => 'OFFLINE',
			last_updated => '2015-12-10 15:43:45',
			description => 'Edge: Puts server in CCR config file in this state, but CCR will never route traffic to it. Mid: Server will not be included in parent.config files for its edge caches',
		},
	},
	## id => 4
	'3' => {
		new => 'Status',
		using => {
			name => 'ONLINE',
			description => 'Edge: Puts server in CCR config file in this state, and CCR will always route traffic to it. Mid: Server will be included in parent.config files for its edges',
			last_updated => '2015-12-10 15:43:45',
		},
	},
	## id => 5
	'4' => {
		new => 'Status',
		using => {
			name => 'PRE_PROD',
			description => 'Pre Production. Not active in any configuration.',
			last_updated => '2015-12-10 15:43:45',
		},
	},
	## id => 6
	'5' => {
		new => 'Status',
		using => {
			name => 'REPORTED',
			description => 'Edge: Puts server in CCR config file in this state, and CCR will adhere to the health protocol. Mid: N/A for now',
			last_updated => '2015-12-10 15:43:45',
		},
	},
);

sub name {
		return "Status";
}

sub get_definition {
		my ( $self,
			$name ) = @_;
		return $definition_for{$name};
}

sub all_fixture_names {
	# sort by db name to guarantee insertion order
	return (sort { $definition_for{$a}{using}{name} cmp $definition_for{$b}{using}{name} } keys %definition_for);
}

__PACKAGE__->meta->make_immutable;
1;
