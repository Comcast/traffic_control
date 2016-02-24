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

#no_transactions=>1 ==> keep fixtures after every execution, beware of duplicate data!
#no_transactions=>0 ==> delete fixtures after every execution

BEGIN { $ENV{MOJO_MODE} = "test" }

my $schema = Schema->connect_to_database;
my $dbh    = Schema->database_handle;
my $t      = Test::Mojo->new('TrafficOps');

Test::TestHelper->unload_core_data($schema);
Test::TestHelper->load_core_data($schema);

ok $t->post_ok( '/login', => form => { u => Test::TestHelper::ADMIN_USER, p => Test::TestHelper::ADMIN_USER_PASSWORD } )->status_is(302)
	->or( sub { diag $t->tx->res->content->asset->{content}; } ), 'Should login?';

ok $t->get_ok('/api/1.2/servers/details.json?hostName=atlanta-edge-01')->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/0/ipGateway", "127.0.0.1" )->json_is( "/response/0/deliveryservices/0", "1" ), 'Does the hostname details return?';

ok $t->get_ok('/api/1.2/servers/details.json?physLocationID=1')->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/0/ipGateway", "127.0.0.1" )->json_is( "/response/0/deliveryservices/0", "1" ), 'Does the physLocationID details return?';

ok $t->get_ok('/api/1.2/servers/details.json')->status_is(400)->or( sub { diag $t->tx->res->content->asset->{content}; } ),
	'Does the validation error occur?';
ok $t->get_ok('/api/1.2/servers/details.json?orderby=hostName')->status_is(400)->or( sub { diag $t->tx->res->content->asset->{content}; } ),
	'Does the orderby work?';

ok $t->get_ok('/logout')->status_is(302)->or( sub { diag $t->tx->res->content->asset->{content}; } );




ok $t->post_ok( '/login', => form => { u => Test::TestHelper::ADMIN_USER, p => Test::TestHelper::ADMIN_USER_PASSWORD } )->status_is(302)
  ->or( sub { diag $t->tx->res->content->asset->{content}; } ), 'Should login?';

ok $t->get_ok('/api/1.2/servers.json?type=mid')->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
  ->json_is( "/response/0/hostName", "atlanta-mid-01" )
  ->json_is( "/response/0/domainName", "ga.atlanta.kabletown.net" )
  ->json_is( "/response/0/type", "MID" )
  ->or( sub { diag $t->tx->res->content->asset->{content}; } );

ok $t->get_ok('/logout')->status_is(302)->or( sub { diag $t->tx->res->content->asset->{content}; } );
$dbh->disconnect();
done_testing();
