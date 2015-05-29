package MojoPlugins::DeliveryService;
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

use Mojo::Base 'Mojolicious::Plugin';
use Carp qw(cluck confess);
use Data::Dumper;
use Utils::Helper::DateHelper;
use JSON;
use HTTP::Date;

sub register {
	my ( $self, $app, $conf ) = @_;

	$app->renderer->add_helper(
		hr_string_to_mbps => sub {
			my $self = shift;
			my $inp  = shift;

			if    ( !defined($inp) )     { return 0; }                  # default is 0
			elsif ( $inp =~ /^(\d+)T$/ ) { return $1 * 1000000; }
			elsif ( $inp =~ /^(\d+)G$/ ) { return $1 * 1000; }
			elsif ( $inp =~ /^(\d+)M$/ ) { return $1; }
			elsif ( $inp =~ /^(\d+)k$/ ) { return int( $1 / 1000 ); }
			elsif ( $inp =~ /^\d+$/ )    { return $1; }
			else                         { return -1; }

		}
	);

	$app->renderer->add_helper(
		get_daily_usage => sub {
			my $self            = shift;
			my $dsid            = shift;
			my $cachegroup_name = shift;
			my $peak_usage_type = shift;
			my $start           = shift;
			my $end             = shift;
			my $interval        = shift;

			my ( $cdn_name, $ds_name ) = $self->deliveryservice_lookup_cdn_name_and_ds_name($dsid);

			my $dh = new Utils::Helper::DateHelper();
			( $start, $end ) = $dh->translate_dates( $start, $end );

			my $j = $self->daily_summary( $cdn_name, $ds_name, $cachegroup_name );

			$self->success($j);
		}
	);

	$app->renderer->add_helper(
		deliveryservice_usage => sub {
			my $self            = shift;
			my $dsid            = shift;
			my $cachegroup_name = shift;
			my $metric_type     = shift;
			my $start           = shift;
			my $end             = shift;
			my $interval        = shift;

			my ( $cdn_name, $ds_name ) = $self->deliveryservice_lookup_cdn_name_and_ds_name($dsid);

			my $dh = new Utils::Helper::DateHelper();
			( $start, $end ) = $dh->translate_dates( $start, $end );
			my $match = $self->build_match( $cdn_name, $ds_name, $cachegroup_name, $metric_type );
			my ( $rc, $j ) = $self->v11_get_stats( $match, $start, $end, $interval );
			if ( $rc > 0 ) {
				return $self->alert($j);
			}
			else {
				if ( %{$j} ) {
					$j->{deliveryServiceId} = $dsid;    # add dsId to data structure
				}

				return $self->success($j);
			}
		}
	);

	$app->renderer->add_helper(
		build_match => sub {
			my $self            = shift;
			my $cdn_name        = shift;
			my $ds_name         = shift;
			my $cachegroup_name = shift;
			my $peak_usage_type = shift;
			return $cdn_name . ":" . $ds_name . ":" . $cachegroup_name . ":all:" . $peak_usage_type;
		}
	);

	$app->renderer->add_helper(
		deliveryservice_lookup_cdn_name_and_ds_name => sub {
			my $self = shift;
			my $dsid = shift || confess("Delivery Service id is required");

			my $cdn_name = "all";
			my $ds_name  = "all";
			if ( $dsid ne "all" ) {
				my $ds = $self->db->resultset('Deliveryservice')->search( { id => $dsid }, {} )->single();
				$ds_name = $ds->xml_id;
				my $param =
					$self->db->resultset('ProfileParameter')
					->search( { -and => [ profile => $ds->profile->id, 'parameter.name' => 'CDN_name' ] }, { prefetch => [ 'parameter', 'profile' ] } )
					->single();
				$cdn_name = $param->parameter->value;
			}
			return ( $cdn_name, $ds_name );
		}
	);

	$app->renderer->add_helper(
		is_delivery_service_assigned => sub {
			my $self = shift || confess("Call on an instance of Utils::Helper");
			my $id   = shift || confess("Please supply a delivery service ID");

			my $user_id =
				$self->db->resultset('TmUser')->search( { username => $self->current_user()->{username} } )->get_column('id')->single();
			my @ds_ids = ();

			if ( defined($user_id) ) {
				@ds_ids = $self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $user_id } )->get_column('deliveryservice')->all();
			}

			my %ds_hash = map { $_ => 1 } @ds_ids;

			# no external user ID = internal; assume authenticated due to route configuration
			if ( !defined($user_id) ) {
				return (1);
			}
			elsif ($user_id) {
				my $result = $self->db->resultset("Deliveryservice")->search( { id => $id } )->single();

				if ( exists( $ds_hash{ $result->id } ) ) {
					return (1);
				}
			}

			return (0);
		}
	);

	$app->renderer->add_helper(
		is_delivery_service_name_assigned => sub {
			my $self    = shift || confess("Call on an instance of Utils::Helper");
			my $ds_name = shift || confess("Please supply a delivery service name (xml_id)");

			my $user_id =
				$self->db->resultset('TmUser')->search( { username => $self->current_user()->{username} } )->get_column('id')->single();
			my @ds_ids = ();

			if ( defined($user_id) ) {
				@ds_ids = $self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $user_id } )->get_column('deliveryservice')->all();
			}

			my %ds_hash = map { $_ => 1 } @ds_ids;

			# no external user ID = internal; assume authenticated due to route configuration
			if ( !defined($user_id) ) {
				return (1);
			}
			elsif ($user_id) {
				my $result = $self->db->resultset("Deliveryservice")->search( { xml_id => $ds_name } )->single();

				if ( exists( $ds_hash{ $result->id } ) ) {
					return (1);
				}
			}

			return (0);
		}
	);

	$app->renderer->add_helper(
		is_valid_delivery_service => sub {
			my $self = shift || confess("Call on an instance of Utils::Helper");
			my $id   = shift || confess("Please supply a delivery service ID");

			my $result = $self->db->resultset("Deliveryservice")->find( { id => $id } );

			if ( defined($result) ) {
				return (1);
			}
			else {
				return (0);
			}
		}
	);

	$app->renderer->add_helper(
		is_valid_delivery_service_name => sub {
			my $self = shift || confess("Call on an instance of Utils::Helper");
			my $name = shift || confess("Please supply a delivery service 'name' (xml_id)");

			my $result = $self->db->resultset("Deliveryservice")->find( { xml_id => $name } );

			if ( defined($result) ) {
				return (1);
			}
			else {
				return (0);
			}
		}
	);

	$app->renderer->add_helper(
		get_delivery_service_name => sub {
			my $self = shift || confess("Call on an instance of Utils::Helper");
			my $id   = shift || confess("Please supply a delivery service ID");

			my $result = $self->db->resultset("Deliveryservice")->search( { id => $id } )->single();

			if ( defined($result) ) {
				return ( $result->xml_id );
			}
			else {
				return (0);
			}
		}
	);

}

1;
