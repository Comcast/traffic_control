package API::Usage;
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

# JvD Note: you always want to put Utils as the first use. Sh*t don't work if it's after the Mojo lines.
use UI::Utils;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use JSON;
use Common::ReturnCodes qw(SUCCESS ERROR);
Utils::Helper::Datasource->load_extensions;

# TODO: drichardson - How is this different than API/Deliveryservice#peakusage
sub deliveryservice {
	my $self            = shift;
	my $dsid            = $self->param('ds');
	my $cachegroup_name = $self->param('name');
	my $metric          = $self->param('metric');
	my $start_date      = $self->param('start_date');
	my $end_date        = $self->param('end_date');
	my $interval        = $self->param('interval');

	if ( $self->is_valid_delivery_service($dsid) ) {
		if ( $self->is_delivery_service_assigned($dsid) ) {

			my $stats = new Extensions::Delegate::Statistics(
				{
					dsId           => $dsid,
					cacheGroupName => $cachegroup_name,
					metricType     => $metric,
					startDate      => $start_date,
					endDate        => $end_date,
					interval       => $interval,
				}
			);
			my ( $rc, $result ) = $stats->v11_get_stats($self);
			$self->app->log->debug( "top.rc #-> " . Dumper($rc) );
			$self->app->log->debug( "top.result #-> " . Dumper($result) );

			if ( $rc == SUCCESS ) {
				return $self->success($result);
			}
			else {
				return $self->alert($result);
			}
		}
		else {
			return $self->forbidden();
		}
	}
	else {
		$self->success( {} );
	}

}

sub deliveryservice2 {
	my $self            = shift;
	my $dsid            = $self->param('ds');
	my $cachegroup_name = $self->param('name');
	my $metric          = $self->param('metric');
	my $start           = $self->param('start_date');
	my $end             = $self->param('end_date');
	my $interval        = $self->param('interval');

	if ( $self->is_valid_delivery_service($dsid) ) {

		if ( $self->is_delivery_service_assigned($dsid) ) {
			return $self->deliveryservice_usage( $dsid, $cachegroup_name, $metric, $start, $end, $interval );
		}
		else {
			return $self->forbidden();
		}
	}
	else {
		$self->success( {} );
	}

}

1;
