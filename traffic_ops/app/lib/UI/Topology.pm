package UI::Topology;

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

use UI::Utils;
use UI::Render;
use List::Compare;
use JSON;
use Data::Dumper;
use Mojo::Base 'Mojolicious::Controller';
use Time::HiRes qw(gettimeofday);
use File::Basename;
use File::Path;

sub ccr_config {
	my $self     = shift;
	my $cdn_name = $self->param('cdnname');
	my $json     = &gen_crconfig_json( $self, $cdn_name );
	$self->render( json => $json );
}

# Produces a list of Cdns for traversing child links
sub gen_crconfig_json {
	my $self     = shift;
	my $cdn_name = shift;

	my $data_obj;
	my $cdn_id;
	my %type_to_name;
	my $ccr_domain_name = "";
	my $profile_cache;
	my $cdn_soa_minimum = 30;
	my $cdn_soa_expire  = 604800;
	my $cdn_soa_retry   = 7200;
	my $cdn_soa_refresh = 28800;
	my $cdn_soa_admin   = "traffic_ops";
	my $tld_ttls_soa    = 86400;
	my $tld_ttls_ns     = 3600;

	$SIG{__WARN__} = sub {
		warn $_[0]
			unless $_[0] =~ m/Prefetching multiple has_many rels deliveryservice_servers/;
	};

	$data_obj->{'stats'}->{'CDN_name'}   = $cdn_name;
	$data_obj->{'stats'}->{'date'}       = time();
	$data_obj->{'stats'}->{'tm_version'} = &tm_version();
	$data_obj->{'stats'}->{'tm_path'}    = $self->req->url->path->{'path'};
	$data_obj->{'stats'}->{'tm_host'}    = $self->req->headers->host;
	$data_obj->{'stats'}->{'tm_user'}    = $self->current_user()->{'username'};

	my $rs_cdn_profiles = $self->db->resultset('Server')->search(
		{ 'cdn.name' => $cdn_name },
		{
			select => [ 'cdn.id', 'me.profile', 'me.type' ],
			join   => 'cdn',
			prefetch => [ 'profile', 'type' ],
			distinct => 1
		}
	);

	while ( my $row = $rs_cdn_profiles->next ) {
		push( @{ $profile_cache->{ $row->type->name } }, $row->profile->id );
		$cdn_id = defined($cdn_id) ? next : $row->cdn->id;
	}

	my %param_cache;
	my @profile_caches;
	for my $cachetype (qw/CCR EDGE MID/) {
		my $r = $profile_cache->{$cachetype};
		if ( defined($r) && scalar @{$r} != 0 ) {
			push @profile_caches, @{$r};
		}
		else {
			if ( $cachetype eq 'CCR' ) {
				$cachetype = 'Traffic Router';
			}
			my $e = Mojo::Exception->throw( "No $cachetype profiles found for CDN: " . $cdn_name );
		}
	}
	my %condition = (
		-and => [
			profile => {
				-in => \@profile_caches,
			},
			'parameter.config_file' => 'CRConfig.json'
		]
	);
	my $rs_pp = $self->db->resultset('ProfileParameter')->search( \%condition, { prefetch => [ { 'parameter' => undef }, { 'profile' => undef } ] } );

	#add dnssec.enabled value to config section
	my $cdn_rs = $self->db->resultset('Cdn')->search( { name => $cdn_name } )->single();
	my $dnssec_enabled = "false";
	if ( $cdn_rs->dnssec_enabled == 1 ) {
		$dnssec_enabled = "true";
	}
	$data_obj->{'config'}->{'dnssec.enabled'} = $dnssec_enabled;

	while ( my $row = $rs_pp->next ) {

		$param_cache{ $row->profile->id }->{ $row->parameter->name } = $row->parameter->value;

		if ( $row->parameter->name eq 'tld.soa.admin' ) {
			$cdn_soa_admin = $row->parameter->value;
		}
		if ( $row->parameter->name eq 'tld.soa.expire' ) {
			$cdn_soa_expire = $row->parameter->value;
		}
		if ( $row->parameter->name eq 'tld.soa.minimum' ) {
			$cdn_soa_minimum = $row->parameter->value;
		}
		if ( $row->parameter->name eq 'tld.soa.refresh' ) {
			$cdn_soa_refresh = $row->parameter->value;
		}
		if ( $row->parameter->name eq 'tld.soa.retry' ) {
			$cdn_soa_retry = $row->parameter->value;
		}
		if ( $row->parameter->name eq 'tld.ttls.SOA' ) {
			$tld_ttls_soa = $row->parameter->value;
		}
		if ( $row->parameter->name eq 'tld.ttls.NS' ) {
			$tld_ttls_ns = $row->parameter->value;
		}
		if ( $row->parameter->name eq 'domain_name' ) {
			$ccr_domain_name = $row->parameter->value;
			$data_obj->{'config'}->{ $row->parameter->name } = $row->parameter->value;
		}
		elsif ( $row->parameter->name =~ m/^tld/ ) {
			my $param = $row->parameter->name;
			$param =~ s/tld\.//;
			( my $top_key, my $second_key ) = split( /\./, $param );
			$data_obj->{'config'}->{$top_key}->{$second_key} =
				$row->parameter->value;
		}
		elsif ( $row->parameter->name eq 'LogRequestHeaders' ) {
			my $headers;
			foreach my $header ( split( /__RETURN__/, $row->parameter->value ) ) {
				$header = &trim_spaces($header);
				push( @$headers, $header );
			}
			$data_obj->{'config'}->{'requestHeaders'} = $headers;
		}
		else {
			$data_obj->{'config'}->{ $row->parameter->name } = $row->parameter->value;
		}

	}

	my $regex_tracker;
	my $rs_regexes = $self->db->resultset('Regex')->search( {}, { 'prefetch' => 'type' } );
	while ( my $row = $rs_regexes->next ) {
		$regex_tracker->{ $row->id }->{'type'}    = $row->type->name;
		$regex_tracker->{ $row->id }->{'pattern'} = $row->pattern;
	}

	my %cache_tracker;
	my $rs_caches = $self->db->resultset('Server')->search(
		{ 'type.name' => { -in => [ 'EDGE', 'MID', 'CCR', 'RASCAL', 'TR', 'TM' ] }, 'me.cdn_id' => $cdn_id },
		{
			prefetch => [ 'type',      'status',      'cachegroup', 'profile' ],
			columns  => [ 'host_name', 'domain_name', 'tcp_port',   'interface_name', 'ip_address', 'ip6_address', 'id', 'xmpp_id' ]
		}
	);

	while ( my $row = $rs_caches->next ) {

		next
			unless ( $row->status->name eq 'ONLINE'
			|| $row->status->name eq 'REPORTED'
			|| $row->status->name eq 'ADMIN_DOWN' );

		if ( $row->type->name eq "RASCAL" ) {
			$data_obj->{'monitors'}->{ $row->host_name }->{'fqdn'} =
				$row->host_name . "." . $row->domain_name;
			$data_obj->{'monitors'}->{ $row->host_name }->{'status'} =
				$row->status->name;
			$data_obj->{'monitors'}->{ $row->host_name }->{'location'} =
				$row->cachegroup->name;
			$data_obj->{'monitors'}->{ $row->host_name }->{'port'} =
				$row->tcp_port;
			$data_obj->{'monitors'}->{ $row->host_name }->{'ip'} =
				$row->ip_address;
			$data_obj->{'monitors'}->{ $row->host_name }->{'ip6'} =
				( $row->ip6_address || "" );
			$data_obj->{'monitors'}->{ $row->host_name }->{'profile'} =
				$row->profile->name;

		}
		elsif ( $row->type->name eq "CCR" ) {
			my $rs_param = $self->db->resultset('Parameter')->search(
				{
					'profile_parameters.profile' => $row->profile->id,
					'name'                       => 'api.port'
				},
				{ join => 'profile_parameters' }
			);
			my $r = $rs_param->single;
			my $port =
				( defined($r) && defined( $r->value ) ) ? $r->value : 80;

			$data_obj->{'contentRouters'}->{ $row->host_name }->{'fqdn'} =
				$row->host_name . "." . $row->domain_name;
			$data_obj->{'contentRouters'}->{ $row->host_name }->{'status'} =
				$row->status->name;
			$data_obj->{'contentRouters'}->{ $row->host_name }->{'location'} =
				$row->cachegroup->name;
			$data_obj->{'contentRouters'}->{ $row->host_name }->{'port'} =
				$row->tcp_port;
			$data_obj->{'contentRouters'}->{ $row->host_name }->{'api.port'} =
				$port;
			$data_obj->{'contentRouters'}->{ $row->host_name }->{'ip'} =
				$row->ip_address;
			$data_obj->{'contentRouters'}->{ $row->host_name }->{'ip6'} =
				( $row->ip6_address || "" );
			$data_obj->{'contentRouters'}->{ $row->host_name }->{'profile'} =
				$row->profile->name;
		}
		elsif ( $row->type->name eq "EDGE" || $row->type->name eq "MID" ) {

			if ( $row->type->name eq "EDGE" ) {
				$data_obj->{'edgeLocations'}->{ $row->cachegroup->name }->{'latitude'}  = $row->cachegroup->latitude + 0;
				$data_obj->{'edgeLocations'}->{ $row->cachegroup->name }->{'longitude'} = $row->cachegroup->longitude + 0;
			}

			if ( !exists $cache_tracker{ $row->id } ) {
				$cache_tracker{ $row->id } = $row->host_name;
			}

			my $pid = $row->profile->id;
			my $weight =
				defined( $param_cache{$pid}->{'weight'} )
				? $param_cache{$pid}->{'weight'}
				: 0.999;
			my $weight_multiplier =
				defined( $param_cache{$pid}->{'weightMultiplier'} )
				? $param_cache{$pid}->{'weightMultiplier'}
				: 1000;

			$data_obj->{'contentServers'}->{ $row->host_name }->{'locationId'} =
				$row->cachegroup->name;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'cacheGroup'} =
				$row->cachegroup->name;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'fqdn'} =
				$row->host_name . "." . $row->domain_name;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'port'} =
				$row->tcp_port;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'interfaceName'} = $row->interface_name;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'status'} =
				$row->status->name;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'ip'} =
				$row->ip_address;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'ip6'} =
				( $row->ip6_address || "" );
			$data_obj->{'contentServers'}->{ $row->host_name }->{'profile'} =
				$row->profile->name;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'type'} =
				$row->type->name;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'hashId'} =
				$row->xmpp_id;
			$data_obj->{'contentServers'}->{ $row->host_name }->{'hashCount'} =
				int( $weight * $weight_multiplier );
		}
	}
	my $regexps;
	my $rs_ds = $self->db->resultset('Deliveryservice')->search(
		{
			'me.profile' => { -in => \@{ $profile_cache->{'CCR'} } },
			'active'     => 1
		},
		{ prefetch => [ 'deliveryservice_servers', 'deliveryservice_regexes', 'type' ] }
	);

	while ( my $row = $rs_ds->next ) {
		my $protocol;
		if ( $row->type->name =~ m/DNS/ ) {
			$protocol = 'DNS';
		}
		else {
			$protocol = 'HTTP';
		}

		my @server_subrows = $row->deliveryservice_servers->all;
		my @regex_subrows  = $row->deliveryservice_regexes->all;

		my $regex_to_props;
		my %ds_to_remap;
		if ( scalar(@regex_subrows) ) {
			foreach my $subrow (@regex_subrows) {
				$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'matchsets'}->[ $subrow->set_number ]->{'protocol'} = $protocol;
				$regex_to_props->{ $subrow->{'_column_data'}->{'regex'} }->{'pattern'} =
					$regex_tracker->{ $subrow->{'_column_data'}->{'regex'} }->{'pattern'};
				$regex_to_props->{ $subrow->{'_column_data'}->{'regex'} }->{'set_number'} = $subrow->set_number;
				$regex_to_props->{ $subrow->{'_column_data'}->{'regex'} }->{'type'} = $regex_tracker->{ $subrow->{'_column_data'}->{'regex'} }->{'type'};
				if ( $regex_to_props->{ $subrow->{'_column_data'}->{'regex'} }->{'type'} eq 'HOST_REGEXP' ) {
					$ds_to_remap{ $row->xml_id }->[ $subrow->set_number ] = $regex_to_props->{ $subrow->{'_column_data'}->{'regex'} }->{'pattern'};
				}
			}
		}
		my @domains;
		foreach my $regex ( sort keys %{$regex_to_props} ) {
			my $set_number = $regex_to_props->{$regex}->{'set_number'};
			my $pattern    = $regex_to_props->{$regex}->{'pattern'};
			my $type       = $regex_to_props->{$regex}->{'type'};
			if ( $type eq 'HOST_REGEXP' ) {
				push(
					@{ $data_obj->{'deliveryServices'}->{ $row->xml_id }->{'matchsets'}->[$set_number]->{'matchlist'} },
					{ 'match-type' => 'HOST', 'regex' => $pattern }
				);
				if ( $set_number == 0 ) {
					my $host = $pattern;
					$host =~ s/\\//g;
					$host =~ s/\.\*//g;
					$host =~ s/\.//g;
					push @domains, "$host.$ccr_domain_name";
				}
			}
			elsif ( $type eq 'PATH_REGEXP' ) {
				push(
					@{ $data_obj->{'deliveryServices'}->{ $row->xml_id }->{'matchsets'}->[$set_number]->{'matchlist'} },
					{ 'match-type' => 'PATH', 'regex' => $pattern }
				);
			}
			elsif ( $type eq 'HEADER_REGEXP' ) {
				push(
					@{ $data_obj->{'deliveryServices'}->{ $row->xml_id }->{'matchsets'}->[$set_number]->{'matchlist'} },
					{ 'match-type' => 'HEADER', 'regex' => $pattern }
				);
			}
		}
		$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'domains'} = \@domains;

		if ( scalar(@server_subrows) ) {

			#my $host_regex = qr/(^(\.)+\*\\\.)(.*)(\\\.(\.)+\*$)/;
			my $host_regex1 = qr/\\|\.\*/;

			#MAT: Have to do this dedup because @server_subrows contains duplicates (* the # of host regexes)
			my %server_subrow_dedup;
			foreach my $subrow (@server_subrows) {
				$server_subrow_dedup{ $subrow->{'_column_data'}->{'server'} } =
					$subrow->{'_column_data'}->{'deliveryservice'};
			}
			foreach my $server ( keys %server_subrow_dedup ) {

				next if ( !defined( $cache_tracker{$server} ) );

				foreach my $host ( @{ $ds_to_remap{ $row->xml_id } } ) {
					my $remap;
					if ( $host =~ m/\.\*$/ ) {
						my $host_copy = $host;
						$host_copy =~ s/$host_regex1//g;
						if ( $protocol eq 'DNS' ) {
							$remap = 'edge' . $host_copy . $ccr_domain_name;
						}
						else {
							$remap = $cache_tracker{$server} . $host_copy . $ccr_domain_name;
						}
					}
					else {
						$remap = $host;
					}
					push( @{ $data_obj->{'contentServers'}->{ $cache_tracker{$server} }->{'deliveryServices'}->{ $row->xml_id } }, $remap );
				}
			}
		}

		$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'ttl'} =
			$row->ccr_dns_ttl;
		if ( $protocol ne 'DNS' ) {
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'dispersion'} = {
				limit    => int( $row->initial_dispersion ),
				shuffled => 'true'
			};
		}

		my $geo_limit = $row->geo_limit;
		if ( $geo_limit == 1 ) {
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'coverageZoneOnly'} = 'true';
		}
		elsif ( $geo_limit == 2 ) {
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'coverageZoneOnly'} = 'false';
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'geoEnabled'} =
				[ { 'countryCode' => 'US' } ];
		}
		elsif ( $geo_limit == 3 ) {
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'coverageZoneOnly'} = 'false';
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'geoEnabled'} =
				[ { 'countryCode' => 'CA' } ];
		}
		else {
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'coverageZoneOnly'} = 'false';
		}

		if ( $protocol =~ m/DNS/ ) {

			#$data_obj->{'deliveryServices'}->{$row->xml_id}->{'matchsets'}->[0]->{'protocol'} = 'DNS';
			if ( defined( $row->dns_bypass_ip ) && $row->dns_bypass_ip ne "" ) {
				$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'bypassDestination'}->{'DNS'}->{'ip'} = $row->dns_bypass_ip;
			}
			if ( defined( $row->dns_bypass_ip6 )
				&& $row->dns_bypass_ip6 ne "" )
			{
				$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'bypassDestination'}->{'DNS'}->{'ip6'} = $row->dns_bypass_ip6;
			}
			if ( defined( $row->dns_bypass_cname )
				&& $row->dns_bypass_cname ne "" )
			{
				$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'bypassDestination'}->{'DNS'}->{'cname'} = $row->dns_bypass_cname;
			}
			if ( defined( $row->dns_bypass_ttl )
				&& $row->dns_bypass_ttl ne "" )
			{
				$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'bypassDestination'}->{'DNS'}->{'ttl'} = $row->dns_bypass_ttl;
			}
			if ( defined( $row->max_dns_answers )
				&& $row->max_dns_answers ne "" )
			{
				$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'maxDnsIpsForLocation'} = $row->max_dns_answers;
			}
		}
		elsif ( $protocol =~ m/HTTP/ ) {

			#$data_obj->{'deliveryServices'}->{$row->xml_id}->{'matchsets'}->[0]->{'protocol'} = 'HTTP';
			if ( defined( $row->http_bypass_fqdn )
				&& $row->http_bypass_fqdn ne "" )
			{
				my $full = $row->http_bypass_fqdn;
				my $port;
				my $fqdn;
				if ( $full =~ m/\:/ ) {
					( $fqdn, $port ) = split( /\:/, $full );
				}
				else {
					$fqdn = $full;
					$port = '80';
				}
				$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'bypassDestination'}->{'HTTP'}->{'fqdn'} = $fqdn;
				$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'bypassDestination'}->{'HTTP'}->{'port'} = $port;
			}

			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'regionalGeoBlocking'} = $row->regional_geo_blocking ? 'true' : 'false';
		}

		if ( defined( $row->tr_response_headers )
			&& $row->tr_response_headers ne "" )
		{
			foreach my $header ( split( /__RETURN__/, $row->tr_response_headers ) ) {
				my ( $header_name, $header_value ) = split( /:\s/, $header );
				$header_name                                                                           = &trim_spaces($header_name);
				$header_value                                                                          = &trim_spaces($header_value);
				$header_value                                                                          = &trim_quotes($header_value);
				$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'responseHeaders'}->{$header_name} = $header_value;
			}
		}

		if ( defined( $row->tr_request_headers )
			&& $row->tr_request_headers ne "" )
		{
			my $headers;
			foreach my $header ( split( /__RETURN__/, $row->tr_request_headers ) ) {
				$header = &trim_spaces($header);
				push( @$headers, $header );
			}
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'requestHeaders'} = $headers;
		}

		if ( defined( $row->miss_lat ) && $row->miss_lat ne "" ) {
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'missLocation'}->{'lat'} = $row->miss_lat;
		}
		if ( defined( $row->miss_long ) && $row->miss_long ne "" ) {
			$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'missLocation'}->{'long'} = $row->miss_long;
		}

		$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'ttls'} = {
			'A'    => $row->ccr_dns_ttl,
			'AAAA' => $row->ccr_dns_ttl,
			'NS'   => $tld_ttls_ns,
			'SOA'  => $tld_ttls_soa
		};
		$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'soa'}->{'minimum'} = $cdn_soa_minimum;
		$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'soa'}->{'expire'} =
			$cdn_soa_expire;
		$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'soa'}->{'retry'} =
			$cdn_soa_retry;
		$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'soa'}->{'refresh'} = $cdn_soa_refresh;
		$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'soa'}->{'admin'} =
			$cdn_soa_admin;
		$data_obj->{'deliveryServices'}->{ $row->xml_id }->{'ip6RoutingEnabled'} = $row->ipv6_routing_enabled ? 'true' : 'false';

	}

	my $rs_dns = $self->db->resultset('Staticdnsentry')->search(
		{
			'deliveryservice.active' => 1,
			'deliveryservice.cdn_id' => $cdn_id
		}, {
			prefetch => [ 'deliveryservice', 'type' ],
			columns  => [ 'host',            'type', 'ttl', 'address' ]
		}
	);

	while ( my $dns_row = $rs_dns->next ) {

		my $dns_obj;
		$dns_obj->{'name'}  = $dns_row->host;
		$dns_obj->{'ttl'}   = $dns_row->ttl;
		$dns_obj->{'value'} = $dns_row->address;

		my $type = $dns_row->type->name;
		$type =~ s/\_RECORD//g;
		$dns_obj->{'type'} = $type;

		push( @{ $data_obj->{'deliveryServices'}->{ $dns_row->deliveryservice->xml_id }->{'staticDnsEntries'} }, $dns_obj );
	}

	return ($data_obj);
}

sub read_crconfig_json {
	my $cdn_name      = shift;
	my $crconfig_file = "public/CRConfig-Snapshots/$cdn_name/CRConfig.json";

	open my $fh, '<', $crconfig_file;
	if ( $! && $! !~ m/Inappropriate ioctl for device/ ) {
		my $e = Mojo::Exception->throw("$! when opening $crconfig_file");
	}
	my $crconfig_disk = do { local $/; <$fh> };
	close($fh);
	my $crconfig_scalar = decode_json($crconfig_disk);
	return $crconfig_scalar;
}

sub write_crconfig_json {
	my $self          = shift;
	my $cdn_name      = shift;
	my $crconfig_db   = shift;
	my $crconfig_json = encode_json($crconfig_db);
	my $crconfig_file = "public/CRConfig-Snapshots/$cdn_name/CRConfig.json";
	my $dir           = dirname($crconfig_file);

	if ( !-d $dir ) {
		print "$dir does not exist; attempting to create\n";
		mkpath($dir);
	}

	open my $fh, '>', $crconfig_file;
	if ( $! && $! !~ m/Inappropriate ioctl for device/ ) {
		my $e = Mojo::Exception->throw("$! when opening $crconfig_file");
	}
	print $fh $crconfig_json;
	close($fh);
	return;

	#$self->flash( alertmsg => "Success!" );
	#return $self->redirect_to($self->tx->req->content->headers->{'headers'}->{'referer'}->[0]->[0]);
}

sub diff_crconfig_json {
	my $self     = shift;
	my $json     = shift;
	my $cdn_name = shift;

	if ( !-f "public/CRConfig-Snapshots/$cdn_name/CRConfig.json"
		&& &is_admin($self) )
	{
		my @err = ();
		$err[0] = "There is no existing CRConfig for " . $cdn_name . " to diff against... Is this the first snapshot???";
		my @caution = ();
		$caution[0] = "If you are not sure why you are getting this message, please do not proceed!";
		my @proceed = ();
		$proceed[0] = "To proceed writing the snapshot anyway click the 'Write CRConfig' button below.";
		my @dummy = ();
		return ( \@err, \@dummy, \@caution, \@dummy, \@dummy, \@proceed, \@dummy );
	}

	# my $db_config = &gen_crconfig_json( $self, $cdn_name );
	my $disk_config = &read_crconfig_json($cdn_name);

	(
		my $disk_ds_strings,
		my $disk_loc_strings,
		my $disk_cs_strings,
		my $disk_csds_strings,
		my $disk_rascal_strings,
		my $disk_ccr_strings,
		my $disk_cfg_strings
	) = &crconfig_strings($disk_config);
	my @disk_ds_strings     = @$disk_ds_strings;
	my @disk_loc_strings    = @$disk_loc_strings;
	my @disk_cs_strings     = @$disk_cs_strings;
	my @disk_csds_strings   = @$disk_csds_strings;
	my @disk_rascal_strings = @$disk_rascal_strings;
	my @disk_ccr_strings    = @$disk_ccr_strings;
	my @disk_cfg_strings    = @$disk_cfg_strings;

	( my $db_ds_strings, my $db_loc_strings, my $db_cs_strings, my $db_csds_strings, my $db_rascal_strings, my $db_ccr_strings, my $db_cfg_strings ) =
		&crconfig_strings($json);
	my @db_ds_strings     = @$db_ds_strings;
	my @db_loc_strings    = @$db_loc_strings;
	my @db_cs_strings     = @$db_cs_strings;
	my @db_csds_strings   = @$db_csds_strings;
	my @db_rascal_strings = @$db_rascal_strings;
	my @db_ccr_strings    = @$db_ccr_strings;
	my @db_cfg_strings    = @$db_cfg_strings;

	my @ds_text     = &compare_lists( \@db_ds_strings,     \@disk_ds_strings,     "Section: Delivery Services" );
	my @loc_text    = &compare_lists( \@db_loc_strings,    \@disk_loc_strings,    "Section: Locations" );
	my @cs_text     = &compare_lists( \@db_cs_strings,     \@disk_cs_strings,     "Section: Content Servers" );
	my @csds_text   = &compare_lists( \@db_csds_strings,   \@disk_csds_strings,   "Section: Content Server - Delivery Services" );
	my @rascal_text = &compare_lists( \@db_rascal_strings, \@disk_rascal_strings, "Section: Rascals" );
	my @ccr_text    = &compare_lists( \@db_ccr_strings,    \@disk_ccr_strings,    "Section: Content Routers" );
	my @cfg_text    = &compare_lists( \@db_cfg_strings,    \@disk_cfg_strings,    "Section: Configs" );

	return ( \@ds_text, \@loc_text, \@cs_text, \@csds_text, \@rascal_text, \@ccr_text, \@cfg_text );
}

sub crconfig_strings {
	my $config      = shift;
	my $config_json = $config;

	my @ds_strings;
	my @loc_strings;
	my @cs_strings;
	my @csds_strings;
	my @config_strings;
	my @rascal_strings;
	my @ccr_strings;

	foreach my $ds ( sort keys %{ $config_json->{'deliveryServices'} } ) {
		my $return =
			&stringify_ds( $config_json->{'deliveryServices'}->{$ds} );
		push( @ds_strings, "|DS:$ds$return" );
	}
	foreach my $cachegroup ( sort keys %{ $config_json->{'edgeLocations'} } ) {
		my $return = &stringify_cachegroup( $config_json->{'edgeLocations'}->{$cachegroup} );
		push( @loc_strings, "|edge-cachegroup:$cachegroup|$return" );
	}
	foreach my $server ( sort keys %{ $config_json->{'contentServers'} } ) {
		my $return = &stringify_content_server( $config_json->{'contentServers'}->{$server} );
		push( @cs_strings, $return );
		my @return = &stringify_cs_ds( $config_json->{'contentServers'}->{$server}->{'deliveryServices'}, $server );
		push( @csds_strings, @return );
	}
	foreach my $cfg ( sort keys %{ $config_json->{'config'} } ) {
		my $string;
		if ( $cfg eq 'ttls' || $cfg eq 'soa' ) {
			$string = "|param:$cfg";
			foreach my $key ( sort keys %{ $config_json->{'config'}->{$cfg} } ) {
				$string
					.= "|$key:" . $config_json->{'config'}->{$cfg}->{$key};
			}
		}
		else {
			$string = "|param:$cfg|value:" . $config_json->{'config'}->{$cfg} . "|";
		}
		push( @config_strings, $string );
	}
	foreach my $rascal ( sort keys %{ $config_json->{'monitors'} } ) {
		my $return =
			&stringify_rascal( $config_json->{'monitors'}->{$rascal} );
		push( @rascal_strings, $return );
	}
	foreach my $ccr ( sort keys %{ $config_json->{'contentRouters'} } ) {
		my $return =
			&stringify_ccr( $config_json->{'contentRouters'}->{$ccr} );
		push( @ccr_strings, $return );
	}

	return ( \@ds_strings, \@loc_strings, \@cs_strings, \@csds_strings, \@rascal_strings, \@ccr_strings, \@config_strings );

}

sub stringify_ds {
	my $ds = shift;
	my $string;
	foreach my $matchset ( @{ $ds->{'matchsets'} } ) {
		$string .= "|<br>&emsp;protocol:" . $matchset->{'protocol'};
		foreach my $matchlist ( @{ $matchset->{'matchlist'} } ) {
			$string .= "|regex:" . $matchlist->{'regex'};
			$string .= "|match-type:" . $matchlist->{'match-type'};
		}
	}
	$string .= "|<br>&emsp;CZF Only:" . $ds->{'coverageZoneOnly'};
	if ( defined( $ds->{'geoEnabled'} ) ) {
		$string .= "|Geo Limit: true; Country: " . $ds->{'geoEnabled'}->[0]->{'countryCode'};
	}
	if ( defined( $ds->{'missLocation'} ) ) {
		$string .= "|GeoMiss: " . $ds->{'missLocation'}->{'lat'} . "," . $ds->{'missLocation'}->{'long'};
	}
	if ( defined( $ds->{'bypassDestination'} ) ) {
		$string .= "<br>|BypassDest:";
		if ( defined( $ds->{'bypassDestination'}->{'DNS'}->{'ip'} ) ) {
			$string .= " -ip:" . $ds->{'bypassDestination'}->{'DNS'}->{'ip'};
		}
		if ( defined( $ds->{'bypassDestination'}->{'DNS'}->{'ip6'} ) ) {
			$string
				.= " -ip6:" . $ds->{'bypassDestination'}->{'DNS'}->{'ip6'};
		}
		if ( defined( $ds->{'bypassDestination'}->{'DNS'}->{'cname'} ) ) {
			$string .= " -cname:" . $ds->{'bypassDestination'}->{'DNS'}->{'cname'};
		}
		if ( defined( $ds->{'bypassDestination'}->{'DNS'}->{'ttl'} ) ) {
			$string
				.= " -ttl:" . $ds->{'bypassDestination'}->{'DNS'}->{'ttl'};
		}
		if ( defined( $ds->{'bypassDestination'}->{'HTTP'}->{'fqdn'} ) ) {
			$string
				.= " -fqdn:" . $ds->{'bypassDestination'}->{'HTTP'}->{'fqdn'};
		}
	}
	if ( defined( $ds->{'ip6RoutingEnabled'} ) ) {
		$string .= "|ip6RoutingEnabled: " . $ds->{'ip6RoutingEnabled'};
	}
	if ( defined( $ds->{'maxDnsIpsForLocation'} ) ) {
		$string .= "|maxDnsIpsForLocation:" . $ds->{'maxDnsIpsForLocation'};
	}
	if ( defined( $ds->{'responseHeaders'} ) ) {
		foreach my $header ( sort keys %{ $ds->{'responseHeaders'} } ) {
			$string .= "|responseHeader:$header:" . $ds->{'responseHeaders'}->{$header};
		}
	}
	if ( defined( $ds->{'initial_dispersion'} ) ) {
		$string .= "|initial_dispersion: " . $ds->{'initial_dispersion'};
	}
	if ( defined( $ds->{'regionalGeoBlocking'} ) ) {
		$string .= "|Regional_Geoblocking:" . $ds->{'regionalGeoBlocking'};
	}
	$string .= "|<br>&emsp;DNS TTLs: A:" . $ds->{'ttls'}->{'A'} . " AAAA:" . $ds->{'ttls'}->{'AAAA'} . "|";
	foreach my $dns ( @{ $ds->{'staticDnsEntries'} } ) {
		$string .= "|<br>&emsp;staticDns: |name:" . $dns->{'name'} . "|type:" . $dns->{'type'} . "|ttl:" . $dns->{'ttl'} . "|addr:" . $dns->{'value'} . "|";
	}
	return $string;
}

sub stringify_cachegroup {
	my $loc    = shift;
	my $string = "longitude:" . $loc->{'longitude'} . "|latitude:" . $loc->{'latitude'} . "|";
	return $string;
}

sub stringify_content_server {
	my $cs = shift;
	my $string =
		  "&emsp;|fqdn:"
		. $cs->{'fqdn'} . "|ip:"
		. $cs->{'ip'} . "|ip6:"
		. $cs->{'ip6'}
		. "|port:"
		. $cs->{'port'}
		. "|interfaceName: "
		. $cs->{'interfaceName'}
		. "|<br>&emsp;&emsp;|cacheGroup:"
		. (
		defined( $cs->{'cacheGroup'} )
		? $cs->{'cacheGroup'}
		: $cs->{'locationId'}
		)
		. "|profile:"
		. $cs->{'profile'}
		. "|status:"
		. $cs->{'status'}
		. "|type: "
		. $cs->{'type'}
		. "|hashId: "
		. ( $cs->{'hashId'} || "" )
		. "|hashCount: "
		. ( $cs->{'hashCount'} || "" ) . "|";
	return $string;
}

sub stringify_cs_ds {
	my $csds   = shift;
	my $server = shift;
	my @strings;
	foreach my $ds ( sort keys %{$csds} ) {
		if ( ref( $csds->{$ds} ) eq 'ARRAY' ) {
			foreach my $map ( @{ $csds->{$ds} } ) {
				push( @strings, "|ds:" . $ds . "|server:" . $server . "|mapped:" . $map . "|" );
			}
		}
		else {
			push( @strings, "|ds:" . $ds . "|server:" . $server . "|mapped:" . $csds->{$ds} . "|" );
		}
	}
	return @strings;
}

sub stringify_rascal {
	my $rascal = shift;
	my $string =
		  "|fqdn:"
		. $rascal->{'fqdn'} . "|ip:"
		. $rascal->{'ip'} . "|ip6:"
		. $rascal->{'ip6'}
		. "|port:"
		. $rascal->{'port'}
		. "|location:"
		. $rascal->{'location'}
		. "|status:"
		. $rascal->{'status'}
		. "|profile:"
		. $rascal->{'profile'} . "|";
	return $string;
}

sub stringify_ccr {
	my $ccr = shift;
	my $string =
		  "|fqdn:"
		. $ccr->{'fqdn'} . "|ip:"
		. $ccr->{'ip'} . "|ip6:"
		. $ccr->{'ip6'}
		. "|port:"
		. $ccr->{'port'}
		. "|api.port:"
		. $ccr->{'api.port'}
		. "|location:"
		. $ccr->{'location'}
		. "|status:"
		. $ccr->{'status'}
		. "|profile:"
		. $ccr->{'profile'} . "|";
	return $string;
}

sub compare_lists {
	my $list_db   = shift;
	my $list_disk = shift;
	my $text      = shift;
	my @compare_text;

	my $list_compare_obj = List::Compare->new( \@$list_db, \@$list_disk );

	my @db_only = $list_compare_obj->get_Lonly;
	if ( $#db_only >= 0 ) {
		push( @compare_text, "    " . $text . " only in 12M:" );
		foreach my $ds_string (@db_only) {
			push( @compare_text, "        " . $ds_string );
		}
	}
	my @disk_only = $list_compare_obj->get_Ronly;
	if ( $#disk_only >= 0 ) {
		push( @compare_text, "    " . $text . " only in old file:" );
		foreach my $ds_string (@disk_only) {
			push( @compare_text, "        " . $ds_string );
		}
	}
	if ( $#disk_only < 0 && $#db_only < 0 ) {
		push( @compare_text, "    " . $text . " is the same." );
	}
	return @compare_text;
}

sub trim_spaces {
	my $text = shift;
	$text =~ s/^\s+//g;
	$text =~ s/\s+$//g;
	return $text;
}

sub trim_quotes {
	my $text = shift;
	$text =~ s/^\"//g;
	$text =~ s/\"$//g;
	return $text;
}
1;
