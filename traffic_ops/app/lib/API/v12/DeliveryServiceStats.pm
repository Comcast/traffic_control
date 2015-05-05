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
use Builder::InfluxdbQuery;
use JSON;
my $iq;
my $result;
my $summary_query;
my $series_query;

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
	$self->app->log->debug( "exclude #-> " . $exclude );

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

			$result = ();
			$self->build_parameters();

			my $include_summary = ( defined($exclude) && $exclude =~ /summary/ ) ? 0 : 1;
			$self->app->log->debug( "include_summary #-> " . $include_summary );
			if ($include_summary) {
				$self->build_summary();
			}

			my $include_series = ( defined($exclude) && $exclude =~ /series/ ) ? 0 : 1;
			$self->app->log->debug( "include_series #-> " . $include_series );
			if ($include_series) {
				$self->build_series();
			}
			return $self->success($result);
		}
		else {
			return $self->forbidden();
		}
	}
	else {
		$self->success( {} );
	}

}

sub build_series {
	my $self = shift;

	$series_query = $iq->series_query();
	$self->app->log->debug( "series_query #-> " . $series_query );
	my $response_container = $self->influxdb_query( $self->get_db_name(), $series_query );
	my $response           = $response_container->{'response'};
	my $content            = $response->{_content};

	my $series;
	if ( $response->is_success() ) {
		my $series_content = decode_json($content);
		$series = $iq->series_response($series_content);
	}
	else {
		return $self->alert( { error_message => $content } );
	}
	$self->app->log->debug( "series #-> " . Dumper($series) );
	my $series_node = "series";
	$result->{$series_node}{data} = $series;
	if ( defined($series) && (@$series) ) {
		my @series_values = $series->{values};
		my $series_count  = $#{ $series_values[0] };
		$result->{$series_node}{count} = $series_count;
	}

}

sub build_summary {
	my $self = shift;

	$summary_query = $iq->summary_query();
	$self->app->log->debug( "summary_query #-> " . $summary_query );

	my $response_container = $self->influxdb_query( $self->get_db_name(), $summary_query );
	my $response           = $response_container->{'response'};
	my $content            = $response->{_content};

	my $summary;
	my $summary_content;
	my $series_count = 0;
	if ( $response->is_success() ) {
		$summary_content   = decode_json($content);
		$summary           = $iq->summary_response($summary_content);
		$result->{summary} = $summary;
	}
	else {
		return $self->alert( { error_message => $content } );
	}
}

sub build_parameters {
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

	my $parameters_node = "parameters";

	$result->{$parameters_node}{cdnName}              = $cdn_name;
	$result->{$parameters_node}{deliveryServiceName}  = $ds_name;
	$result->{$parameters_node}{cacheGroupName}       = $cachegroup_name;
	$result->{$parameters_node}{startDate}            = $start_date;
	$result->{$parameters_node}{endDate}              = $end_date;
	$result->{$parameters_node}{interval}             = $interval;
	$result->{$parameters_node}{metricType}           = $metric_type;
	$result->{$parameters_node}{influxdbDatabaseName} = $self->get_db_name();
	$result->{$parameters_node}{influxdbSeriesQuery}  = $series_query;
	$result->{$parameters_node}{influxdbSummaryQuery} = $summary_query;

}

sub get_db_name {
	my $self      = shift;
	my $mode      = $self->app->mode;
	my $conf_file = MojoPlugins::InfluxDB->INFLUXDB_CONF_FILE_NAME;
	my $conf      = Utils::JsonConfig->load_conf( $mode, $conf_file );
	return $conf->{deliveryservice_stats_db_name};
}

1;
