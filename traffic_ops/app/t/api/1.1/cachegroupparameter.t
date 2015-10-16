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
use Test::TestHelper;
use Fixtures::CachegroupParameter;

#no_transactions=>1 ==> keep fixtures after every execution, beware of duplicate data!
#no_transactions=>0 ==> delete fixtures after every execution

BEGIN { $ENV{MOJO_MODE} = "test" }

my $t      = Test::Mojo->new('TrafficOps');
my $dbh    = Schema->database_handle;
my $schema = Schema->connect_to_database;

#unload data for a clean test
Test::TestHelper->unload_core_data($schema);
Test::TestHelper->teardown( $schema, 'CachegroupParameter' );

#load core test data
Test::TestHelper->load_core_data($schema);
Test::TestHelper->load_all_fixtures( Fixtures::CachegroupParameter->new( { schema => $schema, no_transactions => 1 } ) );

ok $t->post_ok( '/login', => form => { u => 'portal', p => Test::TestHelper::ADMIN_USER_PASSWORD } )->status_is(302)
  ->or( sub { diag $t->tx->res->content->asset->{content}; } );

$t->get_ok("/api/1.1/cachegroupparameters.json")->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
  ->json_is( '/response/cachegroupParameters/0/cachegroup', 'mid-northeast-group' )->json_is( '/response/cachegroupParameters/0/parameter', "60" )
  ->json_is( '/response/cachegroupParameters/1/cachegroup', 'mid-northeast-group' )->json_is( '/response/cachegroupParameters/0/parameter', "60" )
  ->json_is( '/response/cachegroupParameters/1/cachegroup', 'mid-northeast-group' )->json_is( '/response/cachegroupParameters/1/parameter', "61" )
  ->json_is( '/response/cachegroupParameters/2/cachegroup', 'mid-northwest-group' )->json_is( '/response/cachegroupParameters/2/parameter', "60" );

ok $t->get_ok('/logout')->status_is(302)->or( sub { diag $t->tx->res->content->asset->{content}; } );
$dbh->disconnect();
done_testing();