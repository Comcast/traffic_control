package main;
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
use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use DBI;
use strict;
use warnings;
no warnings 'once';
use warnings 'all';
use Test::TestHelper;
use Test::MockModule;
use Connection::InfluxDBAdapter;
use Data::Dumper;
use Builder::InfluxdbQuery;

BEGIN {
	use_ok('Test::Exception');
}

my $iq = Builder::InfluxdbQuery->new(
	{ db_name => "ds_stats", series_name => "kbps", start_date => "2015-01-01T00:00:00-07:00", end_date => "2015-01-30T00:00:00-07:00", limit => 10 } );

my $summary_q = $iq->summary_query();
is( "SELECT COUNT(VALUE) FROM  \"kbps\" WHERE TIME > '2015-01-01T00:00:00-07:00' AND TIME < '2015-01-30T00:00:00-07:00' LIMIT 10", $summary_q );
print "summary_q #-> (" . $summary_q . ")\n";

my $series_q = $iq->series_query();
print "series_q #-> (" . $series_q . ")\n";
is( "SELECT VALUE FROM \"kbps\" WHERE TIME > '2015-01-01T00:00:00-07:00' AND TIME < '2015-01-30T00:00:00-07:00'", $series_q );

$iq = Builder::InfluxdbQuery->new( { XXX => 'XXX' } );
throws_ok {
	$iq->summary_query()
}
qr/Key: 'XXX' is not valid/, 'Check invalid parameter key';

done_testing();
