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
	->or( sub { diag $t->tx->res->content->asset->{content}; } );

$t->get_ok('/api/1.1/servers.json?orderby=id')->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/1/status", "ONLINE" )->json_is( "/response/1/ipGateway", "127.0.0.7" )->json_is( "/response/1/ip6Gateway", "2345:1234:12:d::1" )
	->json_is( "/response/1/tcpPort", "80" )->json_is( "/response/1/cachegroup", "cg5-edge_atl_group" )
	->json_is( "/response/1/hostName", "atlanta-edge-02" )->json_is( "/response/1/domainName", "ga.atlanta.kabletown.net" )
	->json_is( "/response/1/ipAddress", "127.0.0.7" )->json_is( "/response/1/profile", "EDGE1" )->json_is( "/response/1/type", "EDGE" )
	->json_is( "/response/1/physLocation", "Boulder" )->json_is( "/response/1/interfaceName", "bond0" )->json_is( "/response/1/interfaceMtu", "9000" )

	->json_is( "/response/2/status", "ONLINE" )->json_is( "/response/2/ipGateway", "127.0.0.1" )->json_is( "/response/2/ip6Gateway", "2345:1234:12:8::1" )
	->json_is( "/response/2/tcpPort", "80" )->json_is( "/response/2/cachegroup", "cg5-edge_atl_group" )->json_is( "/response/2/hostName", "atlanta-edge-03" )
	->json_is( "/response/2/domainName", "ga.atlanta.kabletown.net" )->json_is( "/response/2/ipAddress", "127.0.0.13" )->json_is( "/response/2/profile", "EDGE1" )
	->json_is( "/response/2/type", "EDGE" )->json_is( "/response/2/physLocation", "Boulder" )->json_is( "/response/2/interfaceName", "bond0" )
	->json_is( "/response/2/interfaceMtu", "9000" )

	->json_is( "/response/4/status", "ONLINE" )->json_is( "/response/4/ipGateway", "127.0.0.8" )->json_is( "/response/4/ip6Gateway", "2345:1234:12:e::1" )
	->json_is( "/response/4/tcpPort", "80" )->json_is( "/response/4/cachegroup", "cg2-mid-northwest" )->json_is( "/response/4/hostName", "atlanta-mid-02" )
	->json_is( "/response/4/domainName", "ga.atlanta.kabletown.net" )->json_is( "/response/4/ipAddress", "127.0.0.8" )->json_is( "/response/4/profile", "MID1" )
	->json_is( "/response/4/type", "MID" )->json_is( "/response/4/physLocation", "Denver" )->json_is( "/response/4/interfaceName", "bond0" )
	->json_is( "/response/4/interfaceMtu", "9000" )

	->json_is( "/response/7/status", "ONLINE" )->json_is( "/response/7/ipGateway", "127.0.0.11" )->json_is( "/response/7/ip6Gateway", "127.0.0.11" )
	->json_is( "/response/7/tcpPort", "8086" )->json_is( "/response/7/cachegroup", "cg1-mid-northeast" )->json_is( "/response/7/hostName", "influxdb02" )
	->json_is( "/response/7/domainName", "kabletown.net" )->json_is( "/response/7/ipAddress", "127.0.0.11" )->json_is( "/response/7/profile", "RASCAL1" )
	->json_is( "/response/7/type", "INFLUXDB" )->json_is( "/response/7/physLocation", "HotAtlanta" )->json_is( "/response/7/interfaceName", "eth1" )
	->json_is( "/response/7/interfaceMtu", "1500" );

$t->get_ok('/api/1.1/servers/hostname/atlanta-edge-01/details.json')->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/ipGateway", "127.0.0.1" )->json_is( "/response/deliveryservices/0", "8" );

ok $t->get_ok('/logout')->status_is(302)->or( sub { diag $t->tx->res->content->asset->{content}; } );
$dbh->disconnect();
done_testing();
