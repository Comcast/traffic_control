use utf8;
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

# Test Helper to allow for simpler Test Cases.
package Test::TestHelper;

use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Moose;
use Schema;
use Fixtures::Cdn;
use Fixtures::Deliveryservice;
use Fixtures::DeliveryserviceTmuser;
use Fixtures::Asn;
use Fixtures::Cachegroup;
use Fixtures::EdgeCachegroup;
use Fixtures::Profile;
use Fixtures::Parameter;
use Fixtures::ProfileParameter;
use Fixtures::Role;
use Fixtures::Server;
use Fixtures::Status;
use Fixtures::TmUser;
use Fixtures::Type;
use Fixtures::Division;
use Fixtures::Region;
use Fixtures::PhysLocation;
use Fixtures::Regex;
use Fixtures::DeliveryserviceRegex;
use Fixtures::DeliveryserviceServer;

use constant ADMIN_USER          => 'admin';
use constant ADMIN_USER_PASSWORD => 'password';

use constant PORTAL_USER          => 'portal';
use constant PORTAL_USER_PASSWORD => 'password';

use constant FEDERATION_USER          => 'federation';
use constant FEDERATION_USER_PASSWORD => 'password';

use constant CODEBIG_USER     => 'codebig';
use constant CODEBIG_PASSWORD => 'password';

use constant STEERING_USER_1 => 'steering1';
use constant STEERING_PASSWORD_1 => 'password';

use constant STEERING_USER_2 => 'steering2';
use constant STEERING_PASSWORD_2 => 'password';

sub load_all_fixtures {
	my $self    = shift;
	my $fixture = shift;

	my @fixture_names = $fixture->all_fixture_names;
	foreach my $fixture_name (@fixture_names) {
		$fixture->load($fixture_name);

		#ok $fixture->load($fixture_name), 'Does the ' . $fixture_name . ' load?';
	}
}

sub reset_sequence_id {
	my $self   = shift;
	my $dbh    = Schema->database_handle;

	my @table_names = qw(
		asn
		cachegroup
		cdn
		deliveryservice
		division
		federation
		federation_resolver
		hwinfo
		job_agent
		job_status
		log
		parameter
		phys_location
		profile
		regex
		region
		role
		server
		staticdnsentry
		status
		tm_user
		type );
	foreach my $name (@table_names) {
		my $p = $dbh->prepare("ALTER SEQUENCE " . $name . "_id_seq RESTART WITH 1");
		$p->execute();
	}
}

sub load_core_data {
	my $self          = shift;
	my $schema        = shift;
	my $schema_values = { schema => $schema, no_transactions => 1 };

	$self->reset_sequence_id();

	$self->load_all_fixtures( Fixtures::Cdn->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Role->new($schema_values) );
	$self->load_all_fixtures( Fixtures::TmUser->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Status->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Parameter->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Profile->new($schema_values) );
	$self->load_all_fixtures( Fixtures::ProfileParameter->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Type->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Cachegroup->new($schema_values) );
	$self->load_all_fixtures( Fixtures::EdgeCachegroup->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Division->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Region->new($schema_values) );
	$self->load_all_fixtures( Fixtures::PhysLocation->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Server->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Asn->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Deliveryservice->new($schema_values) );
	$self->load_all_fixtures( Fixtures::Regex->new($schema_values) );
	$self->load_all_fixtures( Fixtures::DeliveryserviceRegex->new($schema_values) );
	$self->load_all_fixtures( Fixtures::DeliveryserviceTmuser->new($schema_values) );
	$self->load_all_fixtures( Fixtures::DeliveryserviceServer->new($schema_values) );
}

sub unload_core_data {
	my $self   = shift;
	my $schema = shift;

	$schema->resultset('ToExtension')->delete_all();
	$schema->resultset('Staticdnsentry')->delete_all();
	$schema->resultset('Job')->delete_all();
	$schema->resultset('Log')->delete_all();
	$schema->resultset('Asn')->delete_all();
	$schema->resultset('DeliveryserviceTmuser')->delete_all();
	$schema->resultset('TmUser')->delete_all();
	$schema->resultset('Role')->delete_all();
	$schema->resultset('DeliveryserviceRegex')->delete_all();
	$schema->resultset('Regex')->delete_all();
	$schema->resultset('DeliveryserviceServer')->delete_all();
	$schema->resultset('Deliveryservice')->delete_all();
	$schema->resultset('Server')->delete_all();
	$schema->resultset('PhysLocation')->delete_all();
	$schema->resultset('Region')->delete_all();
	$schema->resultset('Division')->delete_all();

	$self->teardown_cachegroup($schema);

	$schema->resultset('Profile')->delete_all();
	$schema->resultset('Parameter')->delete_all();
	$schema->resultset('ProfileParameter')->delete_all();
	$schema->resultset('Type')->delete_all();
	$schema->resultset('Status')->delete_all();
	$schema->resultset('Cdn')->delete_all();
}

# Tearing down the Cachegroup table requires deleting them in a specific order, because
# of the 'parent_cachegroup_id' and nested references.
sub teardown_cachegroup {
	my $self   = shift;
	my $schema = shift;

	my $cachegroups;
	do {
		$cachegroups = $schema->resultset("Cachegroup");
		while ( my $row = $cachegroups->next ) {
			if ( $schema->resultset("Cachegroup")->count({parent_cachegroup_id => $row->id}) > 0 ) {
				next;
			}

			if ( $schema->resultset("Cachegroup")->count({secondary_parent_cachegroup_id => $row->id}) > 0 ) {
				next;
			}

			$row->delete();
		}

	} while ( $cachegroups->count() > 0 );
}

1;
