#!/usr/bin/perl
#
# Copyright 2011-2014, Comcast Corporation. This software and its contents are
# Comcast confidential and proprietary. It cannot be used, disclosed, or
# distributed without Comcast's prior written permission. Modification of this
# software is only allowed at the direction of Comcast Corporation. All allowed
# modifications must be provided to Comcast Corporation.
#

use strict;
use warnings;
use JSON;
use LWP;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use Redis;

$| = 1;

# lotsa TODO JvD
my @stat_names = ();
push( @stat_names, "bandwidth" );
push( @stat_names, "ats.proxy.process.http.5xx_responses" );
push( @stat_names, "ats.proxy.process.http.4xx_responses" );
push( @stat_names, "ats.proxy.process.http.3xx_responses" );
push( @stat_names, "ats.proxy.process.http.2xx_responses" );
push( @stat_names, "ats.proxy.process.http.1xx_responses" );
push( @stat_names, "ats.proxy.process.http.current_client_connections" );
push( @stat_names, "ats.proxy.process.http.current_parent_proxy_connections" );
push( @stat_names, "ats.proxy.process.http.current_server_connections" );
push( @stat_names, "maxKbps" );

#push( @stat_names, "system.proc.loadavg" );
#push( @stat_names, "queryTime" );

my %rascal_urls;
$rascal_urls{'over-the-top'} = "http://odol-rascal-oswcdc-03.comcast.net/publish/CacheStats?hc=1&stats=" . join( ',', @stat_names );
$rascal_urls{'title-vi'}     = "http://odol-rascal-oswcdc-01.comcast.net/publish/CacheStats?hc=1&stats=" . join( ',', @stat_names );

# globals
my $redis = Redis->new;
my $ua    = LWP::UserAgent->new();
$ua->timeout(5);
$ua->agent('JvD-stat-getter-01');
my $timestamp;

while (1) {
	while (time() % 10 != 0) { # sync on to 10 secs
		select(undef, undef, undef, 0.1);
	}
	$timestamp = time();    # all samples are going to be "collapsed" on to this time
	my $start = [gettimeofday];
	foreach my $cdn ( keys %rascal_urls ) {
		my $response = $ua->get( $rascal_urls{$cdn} );
		if ( $response->code == 200 ) {
			&store_rascal_data( $response->content, $cdn );
		} else {
			print "failed to get " . $cdn . " code " . $response->code . "\n";
		}
	}
	my $duration = tv_interval($start);
	my $s_time   = 9 - $duration;
	select( undef, undef, undef, $s_time );
}

sub store_rascal_data {
	my $stats_string = shift;
	my $cdn          = shift;

	my $stats_var = JSON->new->utf8->decode($stats_string);

	my $ccount = 0;
	my $scount = 0;
	my %total  = ();
	my $tcount = $redis->zcount('utime', '-inf', '+inf') +1;
	foreach my $cache ( keys %{ $stats_var->{caches} } ) {
		$ccount++;
		foreach my $stat ( keys %{ $stats_var->{caches}->{$cache} } ) {

			my $val = defined( $stats_var->{caches}->{$cache}->{$stat}->[0]->{value} ) ? $stats_var->{caches}->{$cache}->{$stat}->[0]->{value} : 0;

			#my $timestamp = int( $stats_var->{caches}->{$cache}->{$stat}->[0]->{time} / 1000 );
			#my $key = $cache . ":" . $stat . ":" . $timestamp;
			my $set = $cache . ":" . $stat;

			# store timestamp:val
			$redis->zadd($set, $timestamp, $val);

			#$redis->set( $key => $val );
			$scount++;
			$total{$stat} += $val;
		}
	}
	foreach my $stat ( keys %total ) {
		#$redis->set( $cdn . ":" . $stat . ":" . $timestamp => $total{$stat} );
		$redis->zadd( $cdn . ":" . $stat,  $timestamp, $total{$stat} );
		$scount++;
	}
	#$redis->zadd( "utime",  $timestamp, $timestamp );
	print $scount . " keys stored for " . $ccount . " caches, all synced to " . $timestamp . "\n";
}

