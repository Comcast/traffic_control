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

ok $t->post_ok('/api/1.2/profiles' => {Accept => 'application/json'} => json => {
	"name" => "CCR_CREATE", "description" => "CCR_CREATE description" })->status_is(200)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/name" => "CCR_CREATE" )
	->json_is( "/response/description" => "CCR_CREATE description" )
		, 'Does the profile details return?';

ok $t->post_ok('/api/1.2/profiles/name/CCR_CREATE/copy/CCR1' => {Accept => 'application/json'}) ->status_is(200)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/name" => "CCR_CREATE" )
		, 'Does the profile details return?';

ok $t->post_ok('/api/1.2/profiles/name/CCR_COPY/copy/CCR1' => {Accept => 'application/json'})->status_is(400);
ok $t->post_ok('/api/1.2/profiles/name/CCR_NEW/copy/not_exist' => {Accept => 'application/json'})->status_is(400);

ok $t->post_ok('/api/1.2/profiles' => {Accept => 'application/json'} => json => {
	"name" => "", "description" => "description" })->status_is(400);

ok $t->post_ok('/api/1.2/profiles' => {Accept => 'application/json'} => json => {
	"name" => "EDGE1", "description" => "description"})->status_is(400);

ok $t->post_ok('/api/1.2/profiles' => {Accept => 'application/json'} => json => {
	"name" => "CCR_COPY"})->status_is(400);

ok $t->post_ok('/api/1.2/profiles' => {Accept => 'application/json'} => json => {
	"name" => "CCR_COPY", "description" => ""})->status_is(400);

ok $t->post_ok('/api/1.2/profiles' => {Accept => 'application/json'} => json => {
	"name" => "CCR_CREATE", "description" => "ccr description"})->status_is(400);

ok $t->get_ok('/logout')->status_is(302)->or( sub { diag $t->tx->res->content->asset->{content}; } );
$dbh->disconnect();
done_testing();
