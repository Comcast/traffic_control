#!/usr/bin/perl
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

# Plugin for the "ping" check.
#

use strict;
use warnings;

$|++;

use Data::Dumper;
use Getopt::Std;
use Log::Log4perl qw(:easy);
use JSON;
use Extensions::Helper;

my $VERSION = "0.01";
my $hostn   = `hostname`;
chomp($hostn);

my %args = ();
getopts( "l:c:", \%args );

Log::Log4perl->easy_init($ERROR);
if ( defined( $args{l} ) ) {
	if    ( $args{l} == 1 ) { Log::Log4perl->easy_init($INFO); }
	elsif ( $args{l} == 2 ) { Log::Log4perl->easy_init($DEBUG); }
	elsif ( $args{l} == 3 ) { Log::Log4perl->easy_init($TRACE); }
	elsif ( $args{l} > 3 )  { Log::Log4perl->easy_init($TRACE); }
	else                    { Log::Log4perl->easy_init($INFO); }
}

DEBUG( "Including DEBUG messages in output. Config is \'" . $args{c} . "\'" );
TRACE( "Including TRACE messages in output. Config is \'" . $args{c} . "\'" );

if ( !defined( $args{c} ) ) {
	&help();
	exit(1);
}

my $jconf = undef;
eval { $jconf = decode_json( $args{c} ) };
if ($@) {
	ERROR("Bad json config: $@");
	exit(1);
}

TRACE Dumper($jconf);
my $b_url = $jconf->{base_url};
Extensions::Helper->import();
my $ext = Extensions::Helper->new( { base_url => $b_url, token => '91504CE6-8E4A-46B2-9F9F-FE7C15228498' } );

my $jdataserver = $ext->get(Extensions::Helper::SERVERLIST_PATH);
my $match       = $jconf->{match};
my $select      = $jconf->{select};
my $check_name  = $jconf->{check_name};
foreach my $server ( @{$jdataserver} ) {
	if ( $server->{type} eq 'EDGE' || $server->{type} eq 'MID' ) {
		my $ip = undef;
		if ( ref($select) eq 'ARRAY' ) {
			$ip = $server->{ $select->[0] } . "." . $server->{ $select->[1] };
		}
		else {
			$ip = $server->{$select};
		}
		my $pingable = &ping_check( $ip, 30 );
		DEBUG $check_name . " >> " . $server->{hostName} . ": " . $select . " = " . $ip . " ---> " . $pingable . "\n";
		$ext->post_result( $server->{id}, $check_name, $pingable );
	}
}

sub help {
	print "The -c argument is mandatory\n";
}

sub ping_check {
	my $ping_target = shift;    # use address to bypass DNS and FQDN to check DNS
	my $size        = shift;

	if ( !defined($ping_target) ) {
		print "Nothing to ping!\n";
		return 0;
	}

	if ( !defined($size) ) {
		$size = 30;
	}

	TRACE "Ping checking " . $ping_target;

	my $cmd;
	if ( $ping_target =~ /:/ ) {
		$ping_target =~ s/\/\d+$//;
		$cmd = '/bin/ping6 -M do -s ' . $size . ' -c 2 ' . $ping_target . ' 2>&1 > /dev/null';
	}
	else {
		$cmd = '/bin/ping -M do -s ' . $size . ' -c 2 ' . $ping_target . ' 2>&1 > /dev/null';
	}

	#my $cmd = '/sbin/ping -s ' . $size . ' -c 2 ' . $ping_target . ' 2>&1 > /dev/null';
	system($cmd);
	if ( $? != 0 ) {
		ERROR $ping_target . " is NOT Pingable (with " . $size . " packet size)";
		return 0;
	}
	return 1;
}

