package main;

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

ok $t->post_ok('/api/1.2/parameters' => {Accept => 'application/json'} => json => 
        {
            'name'  => 'param10',
            'configFile' => 'configFile10',
            'value'      => 'value10',
            'secure'     => '0'
        }
    )->status_is(200)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
    ->json_is( "/response/0/name" => "param10" )
    ->json_is( "/response/0/configFile" => "configFile10" )
    ->json_is( "/response/0/value" => "value10" )
    ->json_is( "/response/0/secure" => "0" )
		, 'Does the paramters created return?';

ok $t->post_ok('/api/1.2/parameters' => {Accept => 'application/json'} => json => 
	[
        {
            'name'  => 'param1',
            'configFile' => 'configFile1',
            'value'      => 'value1',
            'secure'     => '0'
        },
        {
            'name'  => 'param2',
            'configFile' => 'configFile2',
            'value'      => 'value2',
            'secure'     => '1'
        }
    ])->status_is(200)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
    ->json_is( "/response/0/name" => "param1" )
    ->json_is( "/response/0/configFile" => "configFile1" )
    ->json_is( "/response/0/value" => "value1" )
    ->json_is( "/response/0/secure" => "0" )
    ->json_is( "/response/1/name" => "param2" )
    ->json_is( "/response/1/configFile" => "configFile2" )
    ->json_is( "/response/1/value" => "value2" )
    ->json_is( "/response/1/secure" => "1" )
		, 'Does the paramters created return?';

ok $t->post_ok('/api/1.2/parameters' => {Accept => 'application/json'} => json => [
        {
            'name'  => 'param3',
            'configFile' => 'configFile3',
            'value'      => 'value3',
            'secure'     => '0'
        },
        {
             name        => 'domain_name',
             value       => 'foo.com',
             configFile  => 'CRConfig.json',
            'secure'     => '0'
        }
    ])->status_is(400)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/alerts/0/text" => "parameter [name:domain_name , configFile:CRConfig.json , value:foo.com] already exists." )
		, 'Does the paramters created return?';

ok $t->post_ok('/api/1.2/parameters' => {Accept => 'application/json'} => json => [
        {
            'name'  => 'param3',
            'configFile' => 'configFile3',
            'value'      => 'value3',
            'secure'     => '0'
        },
        {
            'name'  => 'param3',
             configFile  => 'CRConfig.json',
            'secure'     => '0'
        }
    ])->status_is(400)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/alerts/0/text" => 'there is parameter value does not provide , name:param3 , configFile:CRConfig.json' )
		, 'Does the paramters created return?';

ok $t->post_ok('/api/1.2/parameters' => {Accept => 'application/json'} => json => [
        {
            'name'  => 'param3',
            'configFile' => 'configFile3',
            'value'      => 'value3',
            'secure'     => '0'
        },
        {
            'secure'     => '0'
        }
    ])->status_is(400)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
		, 'Does the paramters created return?';

my $para_id = &get_param_id('param2');

ok $t->put_ok('/api/1.2/parameters/' . $para_id => {Accept => 'application/json'} => json => {
            'value'      => 'value2.1',
            'secure'     => '0'
    })->status_is(200)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/name" => "param2" )
	->json_is( "/response/configFile" => "configFile2" )
	->json_is( "/response/value" => "value2.1" )
	->json_is( "/response/secure" => "0" )
		, 'Does the paramters modified return?';

ok $t->put_ok('/api/1.2/parameters/' . $para_id => {Accept => 'application/json'} => json => {
            'name'  => 'param2.1',
            'configFile' => 'configFile2.1',
            'secure'     => '1'
    })->status_is(200)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/name" => "param2.1" )
	->json_is( "/response/configFile" => "configFile2.1" )
	->json_is( "/response/value" => "value2.1" )
	->json_is( "/response/secure" => "1" )
		, 'Does the paramters modified return?';

ok $t->put_ok('/api/1.2/parameters/0' => {Accept => 'application/json'} => json => {
    })->status_is(404)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
		, 'Does the paramters modified return?';

ok $t->delete_ok('/api/1.2/parameters/' . $para_id )->status_is(200)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
		, 'Does the paramter delete return?';

ok $t->delete_ok('/api/1.2/parameters/3' )->status_is(400)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_like( "/alerts/0/text" => qr/has profile associated/ )
		, 'Does the paramter delete return?';

ok $t->post_ok('/api/1.2/parameters/validate' => {Accept => 'application/json'} => json => {
            'name'  => 'param1',
            'configFile' => 'configFile1',
            'value'      => 'value1'
    })->status_is(200)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
    ->json_like( "/response/id" => qr/^\d+$/ )
	->json_is( "/response/name" => "param1" )
	->json_is( "/response/configFile" => "configFile1" )
	->json_is( "/response/value" => "value1" )
	->json_is( "/response/secure" => "0" )
		, 'Does the paramters validate return?';

ok $t->post_ok('/api/1.2/parameters/validate' => {Accept => 'application/json'} => json => {
            'configFile' => 'configFile1',
            'value'      => 'value1'
    })->status_is(400)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_like( "/alerts/0/text" => qr/is required.$/ )
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
		, 'Does the paramters validate return?';
ok $t->post_ok('/api/1.2/parameters/validate' => {Accept => 'application/json'} => json => {
            'name'  => 'param1',
            'value'      => 'value1'
    })->status_is(400)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_like( "/alerts/0/text" => qr/is required.$/ )
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
		, 'Does the paramters validate return?';
ok $t->post_ok('/api/1.2/parameters/validate' => {Accept => 'application/json'} => json => {
            'name'  => 'param1',
            'configFile' => 'configFile1',
    })->status_is(400)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_like( "/alerts/0/text" => qr/is required.$/ )
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
		, 'Does the paramters validate return?';
ok $t->post_ok('/api/1.2/parameters/validate' => {Accept => 'application/json'} => json => {
            'name'  => 'noexist',
            'configFile' => 'noexist',
            'value'      => 'noexist'
    })->status_is(400)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_like( "/alerts/0/text" => qr/does not exist.$/ )
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
		, 'Does the paramters validate return?';

ok $t->get_ok('/logout')->status_is(302)->or( sub { diag $t->tx->res->content->asset->{content}; } );

ok $t->post_ok( '/login', => form => { u =>Test::TestHelper::FEDERATION_USER , p => Test::TestHelper::FEDERATION_USER_PASSWORD } )->status_is(302)
	->or( sub { diag $t->tx->res->content->asset->{content}; } ), 'Should login?';

ok $t->post_ok('/api/1.2/parameters' => {Accept => 'application/json'} => json => [
        {
            'name'  => 'param3',
            'configFile' => 'configFile3',
            'value'      => 'value3',
            'secure'     => '0'
        }]
    )->status_is(403)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/alerts/0/text" => "You must be an admin or oper to perform this operation!" )
		, 'Does the paramters created return?';

ok $t->put_ok('/api/1.2/parameters/' . $para_id => {Accept => 'application/json'} => json => {
    })->status_is(403)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/alerts/0/text" => "You must be an admin or oper to perform this operation!" )
		, 'Does the paramters modified return?';

$para_id = &get_param_id('param1');
ok $t->delete_ok('/api/1.2/parameters/' . $para_id )->status_is(403)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/alerts/0/text" => "You must be an admin or oper to perform this operation!" )
		, 'Does the paramter delete return?';

ok $t->get_ok('/api/1.2/parameters/3')->status_is(200)
	->or( sub { diag $t->tx->res->content->asset->{content}; } )
	->json_is( "/response/0/name" => "domain_name" )
	->json_is( "/response/0/value" => "foo.com" )
	->json_is( "/response/0/configFile" => "CRConfig.json" )
	->json_is( "/response/0/secure" => "0" )
		, 'Does the paramter get return?';

ok $t->get_ok('/logout')->status_is(302)->or( sub { diag $t->tx->res->content->asset->{content}; } );

$dbh->disconnect();
done_testing();

sub get_param_id {
    my $name = shift;
    my $q      = "select id from parameter where name = \'$name\'";
    my $get_svr = $dbh->prepare($q);
    $get_svr->execute();
    my $p = $get_svr->fetchall_arrayref( {} );
    $get_svr->finish();
    my $id = $p->[0]->{id};
    return $id;
}



