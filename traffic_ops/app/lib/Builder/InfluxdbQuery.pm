package Builder::InfluxdbQuery;
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

use utf8;
use Data::Dumper;
use JSON;
use File::Slurp;
use Math::Round;
use Carp qw(cluck confess);

my $args;

sub new {
	my $self  = {};
	my $class = shift;
	$args = shift;

	return ( bless( $self, $class ) );
}

sub now {
	my $self      = shift;
	my $now_param = shift;
	if ( defined($now_param) ) {
		return "now()";
	}

}

sub valid_keys {
	my $self       = shift;
	my $valid      = 1;
	my $valid_keys = { db_name => 1, start_date => 1, end_date => 1, series_name => 1, limit => 1 };
	foreach my $k ( keys $args ) {
		unless ( defined( $valid_keys->{$k} ) ) {
			confess("Key: '$k' is not valid");
			$valid = 0;
		}
	}
	return $valid;
}

sub summary_query {
	my $self = shift;
	if ( valid_keys() ) {

		#'summary' section
		#SELECT sum(value) FROM "bandwidth" WHERE $timeFilter AND cdn='cdn1' GROUP BY time(60s), cdn ORDER BY asc

		#'summary' section
		return sprintf(
			'%s "%s" %s LIMIT 10',
			"SELECT COUNT(VALUE) FROM ",
			$args->{series_name}, "WHERE TIME > '$args->{start_date}' AND TIME < '$args->{end_date}'"
		);

	}

	#	return sprintf( '%s "%s" %s',
	#		"select mean(value), percentile(value, 5), percentile(value, 95), percentile(value, 98), min(value), max(value), sum(value), count(value) from ",
	#		$series_name, "where time > '$start_date' and time < '$end_date'" );
}

sub series_query {
	my $self = shift;
	return sprintf( '%s "%s" %s', "SELECT VALUE FROM", $args->{series_name}, "WHERE TIME > '$args->{start_date}' AND TIME < '$args->{end_date}'" );
}

sub summary_response {
	my $self            = shift;
	my $summary_content = shift;    # in perl hash form

	my $results = $summary_content->{results}[0];
	my $values  = $results->{series}[0]{values}[0];

	my $values_size;
	if ( defined($values) ) {
		$values_size = keys $values;
	}
	my $summary      = ();
	my $series_count = 0;

	if ( defined($values_size) & ( $values_size > 0 ) ) {
		my $avg = $summary_content->{results}[0]{series}[0]{values}[0][1];

		my $average = nearest( .001, $avg );
		$average =~ /([\d\.]+)/;
		$summary->{average}                = $average;
		$summary->{fifthPercentile}        = $summary_content->{results}[0]{series}[0]{values}[0][2];
		$summary->{ninetyFifthPercentile}  = $summary_content->{results}[0]{series}[0]{values}[0][3];
		$summary->{ninetyEighthPercentile} = $summary_content->{results}[0]{series}[0]{values}[0][4];
		$summary->{min}                    = $summary_content->{results}[0]{series}[0]{values}[0][5];
		$summary->{max}                    = $summary_content->{results}[0]{series}[0]{values}[0][6];
		$summary->{total}                  = $summary_content->{results}[0]{series}[0]{values}[0][7];
		$series_count                      = $summary_content->{results}[0]{series}[0]{values}[0][8];
	}
	else {
		$summary->{average}     = 0;
		$summary->{ninetyFifth} = 0;
		$summary->{min}         = 0;
		$summary->{max}         = 0;
		$summary->{total}       = 0;
	}

	return ( $summary, $series_count );

}

sub series_response {
	my $self           = shift;
	my $series_content = shift;
	my $results        = $series_content->{results}[0];
	my $series         = $results->{series}[0];
	my $values         = $series->{values};
	my $values_size;

	if ( defined($values) ) {
		$values_size = keys $values;
	}

	if ( defined($values_size) & ( $values_size > 0 ) ) {
		$values_size = keys $values;
		return $series;
	}
	else {
		return [];
	}
}

1;
