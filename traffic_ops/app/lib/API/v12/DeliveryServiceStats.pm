package API::v12::DeliveryServiceStats;
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
use Utils::Helper;
use Helper::Stats;
use Helper::DeliveryServiceStats;
use JSON;
my $iq;

sub index {
	my $self            = shift;
	my $cdn_name        = $self->param('cdnName');
	my $ds_name         = $self->param('deliveryServiceName');
	my $cachegroup_name = $self->param('cacheGroupName');
	my $metric_type     = $self->param('metricType');
	my $server_type     = $self->param('serverType');
	my $start_date      = $self->param('startDate');
	my $end_date        = $self->param('endDate');
	my $interval        = $self->param('interval') || "1m";      # Valid interval examples 10m (minutes), 10s (seconds), 1h (hour)
	my $exclude         = $self->param('exclude');
	my $limit           = $self->param('limit');
	my $offset          = $self->param('offset');

	if ( $self->is_valid_delivery_service_name($ds_name) ) {
		if ( $self->is_delivery_service_name_assigned($ds_name) ) {

			# Build the summary section
			$iq = new Builder::InfluxdbQuery(
				{
					cdn_name        => $cdn_name,
					series_name     => $metric_type,
					ds_name         => $ds_name,
					cachegroup_name => $cachegroup_name,
					start_date      => $start_date,
					end_date        => $end_date,
					interval        => $interval
				}
			);
			my $summary_query = $iq->summary_query();
			$self->app->log->debug( "summary_query #-> " . $summary_query );

			my $db_name            = $self->get_db_name();
			my $response_container = $self->influxdb_query( $db_name, $summary_query );
			my $response           = $response_container->{'response'};
			my $content            = $response->{_content};

			my $summary;
			my $summary_content;
			my $series_count = 0;
			if ( $response->is_success() ) {
				$summary_content = decode_json($content);
				$self->app->log->debug( "summary_content #-> " . Dumper($summary_content) );
				( $summary, $series_count ) = $iq->summary_response($summary_content);
			}
			else {
				return $self->alert( { error_message => $content } );
			}

			# Build the series section
			#$iq = new Builder::InfluxdbQuery(
			#	{ series_name => $metric_type, cdn_name => $cdn_name, ds_name => $ds_name, start_date => $start_date, end_date => $end_date } );
			my $series_query = $iq->series_query();
			$self->app->log->debug( "series_query #-> " . $series_query );
			$response_container = $self->influxdb_query( $db_name, $series_query );
			$response           = $response_container->{'response'};
			$content            = $response->{_content};

			my $series;
			if ( $response->is_success() ) {
				my $series_content = decode_json($content);
				$series = $iq->series_response($series_content);
			}
			else {
				return $self->alert( { error_message => $content } );
			}

			if ( defined($summary) && defined($series) ) {

				my $parent_node = "parameters";
				my $result      = ();

				#$result->{$parent_node} = $summary_content->{results}[0];

				#$result->{$parent_node}{series}               = $series;
				#$result->{$parent_node}{seriesCount}          = $series_count;
				$result->{$parent_node}{cdnName}              = $cdn_name;
				$result->{$parent_node}{deliveryServiceName}  = $ds_name;
				$result->{$parent_node}{cacheGroupName}       = $cachegroup_name;
				$result->{$parent_node}{startDate}            = $start_date;
				$result->{$parent_node}{endDate}              = $end_date;
				$result->{$parent_node}{interval}             = $interval;
				$result->{$parent_node}{metricType}           = $metric_type;
				$result->{$parent_node}{influxdbDatabaseName} = $self->get_db_name();
				$result->{$parent_node}{influxdbSeriesQuery}  = $series_query;
				$result->{$parent_node}{influxdbSummaryQuery} = $summary_query;
				$result->{series}{data}                       = $series;
				$result->{series}{count}                      = $series_count;

				#$result->{$parent_node}{summary}              = $summary;
				return $self->success($result);
			}
			else {
				return $self->alert("Could not retrieve the summary or the series");
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

sub index_query {
	my $self            = shift;
	my $cdn_name        = $self->param('cdnName');
	my $ds_name         = $self->param('deliveryServiceName');
	my $cachegroup_name = $self->param('cacheGroupName');
	my $metric_type     = $self->param('metricType');
	my $server_type     = $self->param('serverType');
	my $start_date      = $self->param('startDate');
	my $end_date        = $self->param('endDate');
	my $interval        = $self->param('interval') || "1m";      # Valid interval examples 10m (minutes), 10s (seconds), 1h (hour)
	my $exclude         = $self->param('exclude');
	my $limit           = $self->param('limit');
	my $offset          = $self->param('offset');

	my $helper = new Utils::Helper( { mojo => $self } );
	if ( $helper->is_valid_delivery_service($dsid) ) {

		if ( $helper->is_delivery_service_assigned($dsid) ) {
			my ( $cdn_name, $ds_name ) = $self->deliveryservice_lookup_cdn_name_and_ds_name($dsid);

			$stats_helper = new Helper::DeliveryServiceStats();
			my $series_name = $stats_helper->series_name( $cdn_name, $ds_name, $cachegroup_name, $metric_type );

			# Build the summary section

			my $summary_query = $stats_helper->build_summary_query( $series_name, $start_date, $end_date, $interval, $limit );
			$self->app->log->debug( "summary_query #-> " . $summary_query );

			my $db_name            = $self->get_db_name();
			my $response_container = $self->influxdb_query( $db_name, $query );
			my $response           = $response_container->{'response'};
			my $content            = $response->{_content};

			my $response_content;
			if ( $response->is_success() ) {
				$response_content = decode_json($content);

				#$self->app->log->debug( "response_content #-> " . Dumper($response_content) );
				$response = $iq->response($response_content);
			}
			else {
				return $self->alert( { error_message => $content } );
			}

			if ( defined($response) ) {

				my $parent_node = "parameters";
				my $result      = ();

				#$result->{$parent_node}{series}               = $series;
				$result->{$parent_node}{cdnName}              = $cdn_name;
				$result->{$parent_node}{deliveryServiceName}  = $ds_name;
				$result->{$parent_node}{cacheGroupName}       = $cachegroup_name;
				$result->{$parent_node}{startDate}            = $start_date;
				$result->{$parent_node}{endDate}              = $end_date;
				$result->{$parent_node}{interval}             = $interval;
				$result->{$parent_node}{metricType}           = $metric_type;
				$result->{$parent_node}{influxdbDatabaseName} = $self->get_db_name();
				$result->{$parent_node}{influxdbQuery}        = $query;

				$self->app->log->debug( "response_content #-> " . Dumper($response_content) );
				my $series       = $response_content->{results}[0]{series};
				my $series_count = @$series;
				$result->{seriesCount} = $series_count;

				#my $series = $response_content->{results}[0]{series}[0]->{name};

				foreach my $entry (@$series) {
					print "entry #-> (" . Dumper($entry) . ")\n";

					if ( ref($entry) eq "HASH" ) {
						$self->app->log->debug( "___ #-> " . Dumper($entry) );

						#delete $_->{name};
						delete $entry->{tags};
					}
				}
				$result->{series}      = $series;
				$result->{seriesCount} = $series_count;

				return $self->success($result);
			}
			else {
				return $self->alert("Could not retrieve the summary or the series");
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

sub get_db_name {
	my $self      = shift;
	my $mode      = $self->app->mode;
	my $conf_file = MojoPlugins::InfluxDB->INFLUXDB_CONF_FILE_NAME;
	my $conf      = Utils::JsonConfig->load_conf( $mode, $conf_file );
	return $conf->{deliveryservice_stats_db_name};
}

1;
