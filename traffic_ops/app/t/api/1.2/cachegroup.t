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

ok $t->post_ok('/api/1.2/cachegroups' => {Accept => 'application/json'} => json => {
        "name" => "cache_group_mid",
        "short_name" => "cg_mid",
        "latitude" => "123",
        "longitude" => "456",
        "parent_cachegroup" => "",
        "secondary_parent_cachegroup" => "",
        "type_name" => "MID_LOC" })->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/name" => "cache_group_mid" )
    ->json_is( "/response/short_name" => "cg_mid")
    ->json_is( "/response/latitude" => "123")
    ->json_is( "/response/longitude" => "456")
    ->json_is( "/response/parent_cachegroup" => "")
    ->json_is( "/response/secondary_parent_cachegroup" => "")
            , 'Does the cache group details return?';

ok $t->post_ok('/api/1.2/cachegroups' => {Accept => 'application/json'} => json => {
        "name" => "cache_group_edge",
        "short_name" => "cg_edge",
        "latitude" => "123",
        "longitude" => "456",
        "parent_cachegroup" => "cache_group_mid",
        "secondary_parent_cachegroup" => "mid-northeast-group",
        "type_name" => "EDGE_LOC" })->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/name" => "cache_group_edge" )
    ->json_is( "/response/short_name" => "cg_edge")
    ->json_is( "/response/latitude" => "123")
    ->json_is( "/response/longitude" => "456")
    ->json_is( "/response/parent_cachegroup" => "cache_group_mid")
    ->json_is( "/response/secondary_parent_cachegroup" => "mid-northeast-group")
            , 'Does the cache group details return?';

ok $t->post_ok('/api/1.2/servers' => {Accept => 'application/json'} => json => {
        "host_name" => "tc1_ats2",
        "domain_name" => "my.cisco.com",
        "cachegroup" => "mid-northeast-group",
        "cdn_name" => "cdn1",
        "interface_name" => "eth0",
        "ip_address" => "10.74.27.184",
        "ip_netmask" => "255.255.255.0",
        "ip_gateway" => "10.74.27.1",
        "interface_mtu" => "1500",
        "phys_location" => "HotAtlanta",
        "type" => "MID",
        "profile" => "MID1" })
    ->status_is(200)->or( sub { diag $t->tx->res->content->asset->{content}; } )
    ->json_is( "/response/hostName" => "tc1_ats2")
            , 'Does the server details return?';

ok $t->get_ok('/logout')->status_is(302)->or( sub { diag $t->tx->res->content->asset->{content}; } );
$dbh->disconnect();
done_testing();
