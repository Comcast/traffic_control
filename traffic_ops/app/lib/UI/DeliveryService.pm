package UI::DeliveryService;

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

# JvD Note: you always want to put Utils as the first use. Sh*t don't work if it's after the Mojo lines.
use UI::Utils;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use JSON;

sub index {
	my $self = shift;

	my $pparam = $self->db->resultset('ProfileParameter')->search(
		{   -and => [
				'parameter.name' => 'deliveryservice_graph_url',
				'profile.name'   => 'GLOBAL'
			]
		},
		{ prefetch => [ 'parameter', 'profile' ] }
	)->single();
	my $p1_url = defined($pparam) ? $pparam->parameter->value : undef;
	$self->stash( graph_url => $p1_url, );

	&navbarpage($self);
}

sub edit {
	my $self = shift;
	my $id   = $self->param('id');

	my $rs_ds = $self->db->resultset('Deliveryservice')->search(
		{ 'me.id' => $id },
		{   prefetch => [ 'cdn', { 'type' => undef }, { 'profile' => undef } ]
		}
	);
	my $data = $rs_ds->single;
	my $action;
	my $regexp_set = &get_regexp_set( $self, $id );
	my $cdn_domain = &get_cdn_domain( $self, $id );
	my @example_urls
		= &get_example_urls( $self, $id, $regexp_set, $data, $cdn_domain,
		$data->protocol );

	my $server_count = $self->db->resultset('DeliveryserviceServer')
		->search( { deliveryservice => $id } )->count();
	my $static_count = $self->db->resultset('Staticdnsentry')
		->search( { deliveryservice => $id } )->count();
	&stash_role($self);
	$self->stash(
		ds           => $data,
		server_count => $server_count,
		static_count => $static_count,
		fbox_layout  => 1,
		regexp_set   => $regexp_set,
		example_urls => \@example_urls,
		mode         => 'edit'            #for form generation
	);
}

sub get_example_urls {
	my $self       = shift;
	my $id         = shift;
	my $regexp_set = shift;
	my $data       = shift;
	my $cdn_domain = shift;
	my $protocol   = shift;
	my $scheme;
	my $scheme2;
	my $url;

	if ( $protocol eq '0' ) {
		$scheme = 'http';
	}
	elsif ( $protocol eq '1' ) {
		$scheme = 'https';
	}
	elsif ( $protocol eq '2' ) {
		$scheme  = 'http';
		$scheme2 = 'https';
	}
	else {
		$scheme = 'http';
	}

	my @example_urls = ();
	if ( $data->type->name =~ /^DNS/ ) {
		foreach my $re ( @{$regexp_set} ) {
			if ( $re->{type} eq 'HOST_REGEXP' ) {
				my $host = $re->{pattern};
				$host =~ s/\\//g;
				$host =~ s/\.\*//g;
				$host =~ s/\.//g;
				if ( $re->{set_number} == 0 ) {
					$url = $scheme . '://edge.' . $host . "." . $cdn_domain;
					push( @example_urls, $url );
					if ($scheme2) {
						$url
							= $scheme2
							. '://edge.'
							. $host . "."
							. $cdn_domain;
						push( @example_urls, $url );
					}
				}
				else {
					$url = $scheme . '://' . $re->{pattern};
					push( @example_urls, $url );
					if ($scheme2) {
						$url = $scheme . '://' . $re->{pattern};
						push( @example_urls, $url );
					}
				}
			}
		}
	}
	else {
		foreach my $re ( @{$regexp_set} ) {
			if ( $re->{type} eq 'HOST_REGEXP' ) {
				my $host = $re->{pattern};
				my $url;
				$host =~ s/\\//g;
				$host =~ s/\.\*//g;
				$host =~ s/\.//g;
				my $p
					= defined( $example_urls[ $re->{set_number} ] )
					? $example_urls[ $re->{set_number} ]
					: "";
				if ( $re->{set_number} == 0 ) {
					$example_urls[ $re->{set_number} ]
						= $scheme
						. '://ccr.'
						. $host . "."
						. $cdn_domain
						. $p;
					if ($scheme2) {
						$url
							= $scheme2
							. '://ccr.'
							. $host . "."
							. $cdn_domain
							. $p;
						push( @example_urls, $url );
					}
				}
				else {
					$example_urls[ $re->{set_number} ]
						= $scheme . '://' . $re->{pattern} . $p;
					if ($scheme2) {
						$url = $scheme2 . '://' . $re->{pattern} . $p;
						push( @example_urls, $url );
					}
				}
			}
			elsif ( $re->{type} eq 'PATH_REGEXP' ) {
				if ( defined( $example_urls[ $re->{set_number} ] ) ) {
					$example_urls[ $re->{set_number} ] .= $re->{pattern};
				}
				else {
					$example_urls[ $re->{set_number} ] = $re->{pattern};
				}
			}
		}
	}
	return @example_urls;
}

sub get_cdn_domain {
	my $self       = shift;
	my $id         = shift;
	my $cdn_domain = $self->db->resultset('Parameter')->search(
		{   -and =>
				[ 'me.name' => 'domain_name', 'deliveryservices.id' => $id ]
		},
		{   join => {
				profile_parameters =>
					{ profile => { deliveryservices => undef } }
			},
			distinct => 1
		}
	)->get_column('value')->single();
	return $cdn_domain;
}

sub get_regexp_set {
	my $self = shift;
	my $id   = shift;
	my $regexp_set;
	my $i  = 0;
	my $rs = $self->db->resultset('RegexesForDeliveryService')
		->search( {}, { bind => [$id] } );
	while ( my $row = $rs->next ) {

		# my $p = $row->pattern;
		$regexp_set->[$i]->{id}         = $row->id;
		$regexp_set->[$i]->{pattern}    = $row->pattern;
		$regexp_set->[$i]->{type}       = $row->type;
		$regexp_set->[$i]->{set_number} = $row->set_number;
		$i++;
	}
	return $regexp_set;
}

# Read
sub read {
	my $self = shift;
	my @data;
	my $orderby = "xml_id";
	$orderby = $self->param('orderby') if ( defined $self->param('orderby') );
	my $rs_data = $self->db->resultset("Deliveryservice")->search(
		undef,
		{   prefetch => [ 'cdn', 'deliveryservice_regexes' ],
			order_by => 'me.' . $orderby
		}
	);
	while ( my $row = $rs_data->next ) {
		my $cdn_name  = defined( $row->cdn_id ) ? $row->cdn->name : "";
		my $re_rs     = $row->deliveryservice_regexes;
		my @matchlist = ();

		while ( my $re_row = $re_rs->next ) {
			push(
				@matchlist,
				{   type       => $re_row->regex->type->name,
					pattern    => $re_row->regex->pattern,
					set_number => $re_row->set_number,
				}
			);
		}
		push(
			@data,
			{   "xml_id"                 => $row->xml_id,
				"display_name"           => $row->display_name,
				"dscp"                   => $row->dscp,
				"signed"                 => \$row->signed,
				"qstring_ignore"         => $row->qstring_ignore,
				"geo_limit"              => $row->geo_limit,
				"http_bypass_fqdn"       => $row->http_bypass_fqdn,
				"dns_bypass_ip"          => $row->dns_bypass_ip,
				"dns_bypass_ip6"         => $row->dns_bypass_ip6,
				"dns_bypass_cname"       => $row->dns_bypass_cname,
				"dns_bypass_ttl"         => $row->dns_bypass_ttl,
				"org_server_fqdn"        => $row->org_server_fqdn,
				"multi_site_origin"      => \$row->multi_site_origin,
				"ccr_dns_ttl"            => $row->ccr_dns_ttl,
				"type"                   => $row->type->id,
				"cdn_name"               => $cdn_name,
				"profile_name"           => $row->profile->name,
				"profile_description"    => $row->profile->description,
				"global_max_mbps"        => $row->global_max_mbps,
				"global_max_tps"         => $row->global_max_tps,
				"edge_header_rewrite"    => $row->edge_header_rewrite,
				"mid_header_rewrite"     => $row->mid_header_rewrite,
				"tr_response_headers"    => $row->tr_response_headers,
				"tr_request_headers"     => $row->tr_request_headers,
				"regex_remap"            => $row->regex_remap,
				"long_desc"              => $row->long_desc,
				"long_desc_1"            => $row->long_desc_1,
				"long_desc_2"            => $row->long_desc_2,
				"max_dns_answers"        => $row->max_dns_answers,
				"info_url"               => $row->info_url,
				"miss_lat"               => $row->miss_lat,
				"miss_long"              => $row->miss_long,
				"check_path"             => $row->check_path,
				"matchlist"              => \@matchlist,
				"active"                 => \$row->active,
				"protocol"               => \$row->protocol,
				"ipv6_routing_enabled"   => \$row->ipv6_routing_enabled,
				"range_request_handling" => $row->range_request_handling,
				"cacheurl"               => $row->cacheurl,
				"remap_text"             => $row->remap_text,
				"initial_dispersion"     => $row->initial_dispersion,
				"regional_geo_blocking"  => $row->regional_geo_blocking,
			}
		);
	}
	$self->render( json => \@data );
}

# Delete
sub delete {
	my $self = shift;
	my $id   = $self->param('id');

	if ( !&is_oper($self) ) {
		$self->flash( alertmsg => "No can do. Get more privs." );
	}
	else {
		my @regexp_id_list
			= $self->db->resultset('DeliveryserviceRegex')
			->search( { deliveryservice => $id } )->get_column('regex')
			->all();

		my $dsname = $self->db->resultset('Deliveryservice')
			->search( { id => $id } )->get_column('xml_id')->single();
		my $delete = $self->db->resultset('Deliveryservice')
			->search( { id => $id } );
		$delete->delete();

		my $delete_re = $self->db->resultset('Regex')
			->search( { id => { -in => \@regexp_id_list } } );
		$delete_re->delete();
		&log(
			$self,
			"Delete deliveryservice with id:" . $id . " and name " . $dsname,
			"UICHANGE"
		);
	}
	return $self->redirect_to('/close_fancybox.html');
}

sub check_deliveryservice_input {
	my $self = shift;

	if ( $self->param('ds.xml_id') =~ /\s/ ) {
		$self->field('ds.xml_id')
			->is_equal( "",
			"Delivery service xml_id cannot contain whitespace." );
	}

	# TODO:  what restrictions on display_name?

	my $typename
		= $self->db->resultset('Type')
		->search( { id => $self->param('ds.type') } )->get_column('name')
		->single();
	if ( $typename eq 'ANY_MAP' ) {
		return
			$self->valid
			; # Anything goes for the ANY_MAP, but ds.type is only set on create
	}

	if (   $self->param('ds.qstring_ignore') == 2
		&& $self->param('ds.regex_remap') ne "" )
	{
		$self->field('ds.regex_remap')
			->is_equal( "",
			"Regex Remap can not be used when qstring_ignore is 2" );
	}
	my $profile_id = $self->param('ds.profile');
	my $cdn_domain = $self->db->resultset('Parameter')->search(
		{   'Name'                       => 'domain_name',
			'Config_file'                => 'CRConfig.json',
			'profile_parameters.profile' => $profile_id,
		},
		{ join => 'profile_parameters', }
	)->get_column('value')->single();

	my $match_one = 0;
	my %dbl_check = ();
	foreach my $param ( $self->param ) {
		if ( $param =~ /^re_type_(.*)/ ) {
			my $check_string = $self->param($param) . "|"
				. $self->param( 're_order_' . $1 );
			if ( defined( $dbl_check{$check_string} ) ) {
				$self->field('ds.regex')
					->is_equal( "",
					"Duplicate type/order combination is not allowed." );
			}
			else {
				$dbl_check{$check_string} = 1;
			}
			if (!(     $self->param($param) eq 'HOST_REGEXP'
					|| $self->param($param) eq 'PATH_REGEXP'
					|| $self->param($param) eq 'HEADER_REGEXP'
				)
				)
			{
				$self->field('ds.regex')
					->is_equal( "",
					$self->param($param) . " is not a valid regexp type" );
			}
		}
		elsif ( $param =~ /^re_re_/ ) {
			if ( $self->param($param) eq "" ) {
				$self->field('ds.regex')
					->is_equal( "", "Regular expression cannot be empty." );
			}
			else {
				my $err .= $self->check_regexp( $self->param($param) );
				if ( defined($err) && $err ne "" ) {
					$self->field('ds.regex')->is_equal( "", $err );
				}
			}

			if ( $param =~ /^re_re_(\d+)/ || $param =~ /^re_re_new_(\d+)/ ) {
				my $order_no = $1;
				my $type_id = &type_id( $self, 'HOST_REGEXP' );
				if ((   defined( $self->param( 're_type_' . $order_no ) )
						&& $self->param( 're_type_' . $order_no ) eq
						'HOST_REGEXP'
					)
					|| ( defined( $self->param( 're_type_new_' . $order_no ) )
						&& $self->param( 're_type_new_' . $order_no ) eq
						'HOST_REGEXP' )
					)
				{
					my $new_re
						= $self->param( 're_re_' . $order_no )
						? $self->param( 're_re_' . $order_no ) . $cdn_domain
						: $self->param( 're_re_new_' . $order_no )
						. $cdn_domain;
					my $new_order
						= defined( $self->param( 're_order_' . $order_no ) )
						? $self->param( 're_order_' . $order_no )
						: $self->param( 're_order_new_' . $order_no );
					my $rs
						= $self->db->resultset('DeliveryserviceRegex')
						->search(
						undef,
						{   prefetch => [
								{ regex           => undef },
								{ deliveryservice => undef }
							]
						}
						);
					while ( my $row = $rs->next ) {
						my $existing_re = $row->regex->pattern . $cdn_domain;
						if ( defined( $self->param('id') )
							&& $self->param('id')
							== $row->deliveryservice->id )
						{
							next;
						}
						if ( $existing_re eq $new_re ) {
							$self->field('ds.regex')->is_equal( "",
								      "There already is a HOST_REGEXP ("
									. $existing_re
									. ") that maches "
									. $new_re
									. "; No can do." );
							last;
						}
					}
				}
			}
		}
		elsif ( $param =~ /^re_order_.*(\d+)/ ) {
			if ( $self->param($param) !~ /^\d+$/ ) {
				$self->field('ds.regex')
					->is_equal( "",
					$self->param($param) . " is not a valid order number." );
			}
		}
		if ( $self->param($param) eq 'HOST_REGEXP' ) {
			if ( $param =~ /re_type_(\d+)/ ) {
				if ( defined( $self->param( 're_order_' . $1 ) )
					&& $self->param( 're_order_' . $1 ) == 0 )
				{
					$match_one = 1;
				}
			}
			if ( $param =~ /re_type_new_(\d+)/ ) {
				if ( defined( $self->param( 're_order_new_' . $1 ) )
					&& $self->param( 're_order_new_' . $1 ) == 0 )
				{
					$match_one = 1;
				}
			}
		}
	}
	if ( !$match_one ) {
		$self->field('ds.regex')->is_equal( "",
			"A minimum of one host regexp with order 0 is needed per delivery service."
		);
	}
	if ( $self->param('ds.dscp') !~ /^\d+$/ ) {
		$self->field('ds.dscp')
			->is_equal( "",
			$self->param('ds.dscp') . " is not a valid dscp value." );
	}

	my $org_host_name = $self->param('ds.org_server_fqdn');
	$self->field('ds.org_server_fqdn')
		->is_like( qr/^(https?:\/\/)/,
		"Origin Server Base URL must start with http(s)://" );
	$org_host_name =~ s!^https?://?!!i;
	$org_host_name =~ s/:(.*)$//;
	my $port = defined($1) ? $1 : 80;
	if ( !&is_hostname($org_host_name) || $port !~ /^[1-9][0-9]*$/ ) {
		$self->field('ds.org_server_fqdn')->is_equal( "",
			      $org_host_name
				. " is not a valid org server name (rfc1123) or "
				. $port
				. " is not a valid port" );
	}
	if ( $self->param('ds.http_bypass_fqdn') ne ""
		&& !&is_hostname( $self->param('ds.http_bypass_fqdn') ) )
	{
		$self->field('ds.http_bypass_fqdn')->is_equal( "",
			      "Invalid HTTP bypass FQDN "
				. $self->param('ds.http_bypass_fqdn')
				. "  : should by FQDN only, not URL. Example: host.overflowcdn.com"
		);
	}
	my $dns_bypass_ttl_required;
	if ( $self->param('ds.dns_bypass_ip') ne "" ) {
		if ( !&is_ipaddress( $self->param('ds.dns_bypass_ip') ) ) {
			$self->field('ds.dns_bypass_ip')->is_equal( "",
				      "DNS bypass IP "
					. $self->param('ds.dns_bypass_ip')
					. " is not valid IPv4 address." );
		}
		$dns_bypass_ttl_required = 1;
	}
	if ( $self->param('ds.dns_bypass_ip6') ne "" ) {
		if ( !&is_ip6address( $self->param('ds.dns_bypass_ip6') ) ) {
			$self->field('ds.dns_bypass_ip6')->is_equal( "",
				      "DNS bypass IPv6 IP ="
					. $self->param('ds.dns_bypass_ip6')
					. " is not a valid IPv6 address." );
		}
		$dns_bypass_ttl_required = 1;
	}
	if ( $self->param('ds.dns_bypass_cname') ne ""
		&& !&is_hostname( $self->param('ds.dns_bypass_cname') ) )
	{
		$self->field('ds.dns_bypass_cname')->is_equal( "",
			      "Invalid DNS bypass CNAME "
				. $self->param('ds.dns_bypass_cname')
				. "  : should by FQDN only, not URL. Example: host.bypass.com"
		);
		$dns_bypass_ttl_required = 1;
	}
	if ( $dns_bypass_ttl_required
		&& ( $self->param('ds.dns_bypass_ttl') eq "" ) )
	{
		$self->field('ds.dns_bypass_ttl')
			->is_equal( "",
			"DNS bypass TTL required when specifying DNS bypass IP" );
	}
	if ( defined( $self->param('ds.dns_bypass_ttl') )
		&& $self->param('ds.dns_bypass_ttl') =~ m/[a-zA-Z]/ )
	{
		$self->field('ds.dns_bypass_ttl')->is_equal( "",
			      "DNS bypass TTL "
				. $self->param('ds.dns_bypass_ttl')
				. " should be integers only." );
	}
	if (   defined( $self->param('ds.global_max_mbps') )
		&& $self->param('ds.global_max_mbps') ne ""
		&& $self->param('ds.global_max_mbps') !~ /^\d+$/ )
	{
		if ( $self->hr_string_to_mbps( $self->param('ds.global_max_mbps') )
			< 0 )
		{
			$self->field('ds.global_max_mbps')
				->is_equal( "", "Invalid global_max_mbps (NaN)." );
		}
	}
	if (   $self->param('ds.global_max_tps') ne ""
		&& $self->param('ds.global_max_tps') !~ /^\d+$/ )
	{
		$self->field('ds.global_max_tps')
			->is_equal( "", "Invalid global_max_tps (NaN)." );
	}

	if ( $typename =~ /^DNS/ ) {
		if ( defined( $self->param('ds.tr_response_headers') )
			&& $self->param('ds.tr_response_headers') ne "" )
		{
			$self->field('ds.tr_response_headers')->is_equal( "",
				"TR Response Headers are only valid for HTTP (302) delivery services"
			);
		}
		if ( defined( $self->param('ds.tr_request_headers') )
			&& $self->param('ds.tr_request_headers') ne "" )
		{
			$self->field('ds.tr_request_headers')->is_equal( "",
				"TR Log Request Headers are only valid for HTTP (302) delivery services"
			);
		}
	}

#TODO:  Fix this to work the right way.
# if ( defined( $self->param('ds.edge_header_rewrite') ) ) {
# 	if ( $self->param('ds.edge_header_rewrite') ne "" && $self->param('ds.edge_header_rewrite') !~ /^(?:add|rm|set)-header .* \[L\]$/ ) {
# 		$self->field('ds.edge_header_rewrite')
# 			->is_equal( "",
# 			"edge_header_rewrite is a single line that needs to start with [add|rm|set]-header, and end with [L] - see header rewrite docs." );
# 	}
# }
# if ( defined( $self->param('ds.ipv6_routing_enabled') ) ) {
# 	if ( $self->param('ds.type.name') =~ /^DNS/ && $self->param('ds.ipv6_routing_enabled') == 0 ) {
# 		$self->field('ds.ipv6_routing_enabled')->is_equal( "", "IPv6 Routing cannot be disabled for DNS deliveryservices." );
# 	}
# }
	return $self->valid;
}

sub associate_regexpes {
	my $self  = shift;
	my $ds_id = shift;

	if ( !defined($ds_id) ) {
		return;
	}

}

sub header_rewrite {
	my $self       = shift;
	my $ds_id      = shift;
	my $ds_profile = shift;
	my $ds_name    = shift;
	my $hdr_rw     = shift;
	my $tier       = shift;

	if ( defined($hdr_rw) && $hdr_rw ne "" ) {
		my $fname = "hdr_rw_" . $ds_name . ".config";
		if ( $tier eq "mid" ) {
			$fname = "hdr_rw_mid_" . $ds_name . ".config";
		}
		my $ats_cfg_loc
			= $self->db->resultset('Parameter')
			->search(
			{ -and => [ name => 'location', config_file => 'remap.config' ] }
			)->get_column('value')->single();
		$ats_cfg_loc =~ s/\/$//;

		my $param_id
			= $self->db->resultset('Parameter')
			->search(
			{ -and => [ name => 'location', config_file => $fname ] } )
			->get_column('id')->single();
		if ( !defined($param_id) ) {
			my $insert = $self->db->resultset('Parameter')->create(
				{   config_file => $fname,
					name        => 'location',
					value       => $ats_cfg_loc
				}
			);
			$insert->insert();
			$param_id = $insert->id;
		}
		my $cdn_name = undef;
		my @servers
			= $self->db->resultset('DeliveryserviceServer')
			->search( { deliveryservice => $ds_id } )->get_column('server')
			->all();
		if ( $tier eq "mid" ) {
			my $mtype_id = &type_id( $self, 'MID' );
			my $param
				= $self->db->resultset('Deliveryservice')
				->search( { 'me.profile' => $ds_profile },
				{ prefetch => 'cdn' } );
			$cdn_name = $param->next->cdn->name;

			@servers = $self->db->resultset('Server')
				->search( { type => $mtype_id } )->get_column('id')->all();
		}
		my @profiles
			= $self->db->resultset('Server')
			->search( { id => { -in => \@servers } } )->get_column('profile')
			->all();
		foreach my $profile_id (@profiles) {
			my $link
				= $self->db->resultset('ProfileParameter')
				->search( { profile => $profile_id, parameter => $param_id } )
				->single();
			if ( !defined($link) ) {
				if ($cdn_name) {
					my $p_cdn_param
						= $self->db->resultset('Server')
						->search( { 'me.profile' => $profile_id },
						{ prefetch => 'cdn' } );
					if ( $p_cdn_param->next->cdn->name ne $cdn_name ) {
						next;
					}
				}
				my $insert
					= $self->db->resultset('ProfileParameter')->create(
					{   profile   => $profile_id,
						parameter => $param_id
					}
					);

			}
		}
	}
	else {
		my $fname = "hdr_rw_" . $ds_name . ".config";
		if ( $tier eq "mid" ) {
			$fname = "hdr_rw_mid_" . $ds_name . ".config";
		}

		&delete_cfg_file( $self, $fname )
			; # don't change it to $self->delete_header_rewrite(), calling from other pm is wonky
	}
}

sub regex_remap {
	my $self        = shift;
	my $ds_id       = shift;
	my $ds_profile  = shift;
	my $ds_name     = shift;
	my $regex_remap = shift;

	if ( defined($regex_remap) && $regex_remap ne "" ) {
		my $fname = "regex_remap_" . $ds_name . ".config";
		my $ats_cfg_loc
			= $self->db->resultset('Parameter')
			->search(
			{ -and => [ name => 'location', config_file => 'remap.config' ] }
			)->get_column('value')->single();
		$ats_cfg_loc =~ s/\/$//;

		my $param_id
			= $self->db->resultset('Parameter')
			->search(
			{ -and => [ name => 'location', config_file => $fname ] } )
			->get_column('id')->single();
		if ( !defined($param_id) ) {
			my $insert = $self->db->resultset('Parameter')->create(
				{   config_file => $fname,
					name        => 'location',
					value       => $ats_cfg_loc
				}
			);
			$insert->insert();
			$param_id = $insert->id;
		}
		my @servers
			= $self->db->resultset('DeliveryserviceServer')
			->search( { deliveryservice => $ds_id } )->get_column('server')
			->all();
		my @profiles
			= $self->db->resultset('Server')
			->search( { id => { -in => \@servers } } )->get_column('profile')
			->all();
		foreach my $profile_id (@profiles) {
			my $link
				= $self->db->resultset('ProfileParameter')
				->search( { profile => $profile_id, parameter => $param_id } )
				->single();
			if ( !defined($link) ) {
				my $insert
					= $self->db->resultset('ProfileParameter')->create(
					{   profile   => $profile_id,
						parameter => $param_id
					}
					);
			}
		}
	}
	else {
		&delete_cfg_file( $self, "regex_remap_" . $ds_name . ".config" )
			; # don't change it to $self->delete_header_rewrite(), calling from other pm is wonky
	}
}

# Too much code copied from regex_remap, I know...
sub cacheurl {
	my $self       = shift;
	my $ds_id      = shift;
	my $ds_profile = shift;
	my $ds_name    = shift;
	my $cacheurl   = shift;

	if ( defined($cacheurl) && $cacheurl ne "" ) {
		my $fname = "cacheurl_" . $ds_name . ".config";
		my $ats_cfg_loc
			= $self->db->resultset('Parameter')
			->search(
			{ -and => [ name => 'location', config_file => 'remap.config' ] }
			)->get_column('value')->single();
		$ats_cfg_loc =~ s/\/$//;

		my $param_id
			= $self->db->resultset('Parameter')
			->search(
			{ -and => [ name => 'location', config_file => $fname ] } )
			->get_column('id')->single();
		if ( !defined($param_id) ) {
			my $insert = $self->db->resultset('Parameter')->create(
				{   config_file => $fname,
					name        => 'location',
					value       => $ats_cfg_loc
				}
			);
			$insert->insert();
			$param_id = $insert->id;
		}
		my @servers
			= $self->db->resultset('DeliveryserviceServer')
			->search( { deliveryservice => $ds_id } )->get_column('server')
			->all();
		my @profiles
			= $self->db->resultset('Server')
			->search( { id => { -in => \@servers } } )->get_column('profile')
			->all();
		foreach my $profile_id (@profiles) {
			my $link
				= $self->db->resultset('ProfileParameter')
				->search( { profile => $profile_id, parameter => $param_id } )
				->single();
			if ( !defined($link) ) {
				my $insert
					= $self->db->resultset('ProfileParameter')->create(
					{   profile   => $profile_id,
						parameter => $param_id
					}
					);
			}
		}
	}
	else {
		&delete_cfg_file( $self, "cacheurl_" . $ds_name . ".config" )
			; # don't change it to $self->delete_header_rewrite(), calling from other pm is wonky
	}
}

sub delete_cfg_file {
	my $self  = shift;
	my $fname = shift;

	my $param_id
		= $self->db->resultset('Parameter')
		->search( { -and => [ name => 'location', config_file => $fname ] } )
		->get_column('id')->single();
	if ( defined($param_id) ) {
		$self->app->log->info( 'deleting location parameter for ' . $fname );
		my $delete = $self->db->resultset('Parameter')
			->search( { id => $param_id } );
		$delete->delete();
	}
}

# Update
sub update {
	my $self = shift;
	my $id   = $self->param('id');

	if ( !&is_oper($self) ) {
		my $err = "You do not have enough privileges to modify this.";
		$self->flash( message => $err );
		my $referer = $self->req->headers->header('referer');
		return $self->redirect_to($referer);
	}
	if ( $self->check_deliveryservice_input() ) {

	  #print "global_max_mbps = " . $self->param('ds.global_max_mbps') . "\n";
	  # if error check passes
		my %hash = (
			xml_id            => $self->paramAsScalar('ds.xml_id'),
			display_name      => $self->paramAsScalar('ds.display_name'),
			dscp              => $self->paramAsScalar('ds.dscp'),
			signed            => $self->paramAsScalar('ds.signed'),
			qstring_ignore    => $self->paramAsScalar('ds.qstring_ignore'),
			geo_limit         => $self->paramAsScalar('ds.geo_limit'),
			org_server_fqdn   => $self->paramAsScalar('ds.org_server_fqdn'),
			multi_site_origin => $self->paramAsScalar('ds.multi_site_origin'),
			ccr_dns_ttl       => $self->paramAsScalar('ds.ccr_dns_ttl'),
			type              => $self->paramAsScalar('ds.type'),
			cdn_id            => $self->paramAsScalar('ds.cdn_id'),
			profile           => $self->paramAsScalar('ds.profile'),
			global_max_mbps   => $self->hr_string_to_mbps(
				$self->paramAsScalar( 'ds.global_max_mbps', 0 )
			),
			global_max_tps => $self->paramAsScalar( 'ds.global_max_tps', 0 ),
			miss_lat       => $self->paramAsScalar('ds.miss_lat'),
			miss_long      => $self->paramAsScalar('ds.miss_long'),
			long_desc      => $self->paramAsScalar('ds.long_desc'),
			long_desc_1    => $self->paramAsScalar('ds.long_desc_1'),
			long_desc_2    => $self->paramAsScalar('ds.long_desc_2'),
			info_url       => $self->paramAsScalar('ds.info_url'),
			check_path     => $self->paramAsScalar('ds.check_path'),
			active         => $self->paramAsScalar('ds.active'),
			protocol       => $self->paramAsScalar('ds.protocol'),
			ipv6_routing_enabled =>
				$self->paramAsScalar('ds.ipv6_routing_enabled'),
			regional_geo_blocking => 
				$self->paramAsScalar('ds.regional_geo_blocking'),
			range_request_handling =>
				$self->paramAsScalar('ds.range_request_handling'),
			edge_header_rewrite =>
				$self->paramAsScalar( 'ds.edge_header_rewrite', undef ),
			mid_header_rewrite =>
				$self->paramAsScalar( 'ds.mid_header_rewrite', undef ),
			tr_response_headers =>
				$self->paramAsScalar( 'ds.tr_response_headers', undef ),
			tr_request_headers =>
				$self->paramAsScalar( 'ds.tr_request_headers', undef ),
			regex_remap => $self->paramAsScalar( 'ds.regex_remap', undef ),
			origin_shield =>
				$self->paramAsScalar( 'ds.origin_shield', undef ),
			cacheurl   => $self->paramAsScalar( 'ds.cacheurl',   undef ),
			remap_text => $self->paramAsScalar( 'ds.remap_text', undef ),
			initial_dispersion =>
				$self->paramAsScalar( 'ds.initial_dispersion', 1 ),
		);

		if ( $self->paramAsScalar('ds.type') == &type_id( $self, "DNS" ) ) {
			$hash{dns_bypass_ip}  = $self->paramAsScalar('ds.dns_bypass_ip');
			$hash{dns_bypass_ip6} = $self->paramAsScalar('ds.dns_bypass_ip6');
			$hash{dns_bypass_cname}
				= $self->paramAsScalar('ds.dns_bypass_cname');
			$hash{max_dns_answers}
				= $self->paramAsScalar('ds.max_dns_answers');
			$hash{dns_bypass_ttl}
				= $self->paramAsScalar('ds.dns_bypass_ttl') eq ""
				? undef
				: $self->paramAsScalar('ds.dns_bypass_ttl');
		}
		else {
			$hash{http_bypass_fqdn} = $self->param('ds.http_bypass_fqdn');
		}

		# print Dumper( \%hash );
		my $update
			= $self->db->resultset('Deliveryservice')->find( { id => $id } );
		$update->update( \%hash );
		$update->update();
		&log(
			$self,
			"Update deliveryservice with xml_id:" . $self->param('ds.xml_id'),
			"UICHANGE"
		);

		# get the existing regexp set in a hash
		my $regexp_set;
		my $i  = 0;
		my $rs = $self->db->resultset('RegexesForDeliveryService')
			->search( {}, { bind => [$id] } );
		while ( my $row = $rs->next ) {
			$regexp_set->{ $row->id }->{pattern}    = $row->pattern;
			$regexp_set->{ $row->id }->{type}       = $row->type;
			$regexp_set->{ $row->id }->{set_number} = $row->set_number;
			$i++;
		}

		foreach my $param ( $self->param ) {
			if ( $param =~ /re_type_(\d+)/ ) {
				my $re_id          = $1;
				my $type_str       = 're_type_' . $1;
				my $re_str         = 're_re_' . $1;
				my $set_number_str = 're_order_' . $1;
				if ( defined( $regexp_set->{$re_id} ) ) {
					my $regexp = $self->param($re_str);

					my $update = $self->db->resultset('Regex')
						->find( { id => $re_id } );
					$update->update(
						{   pattern => $regexp,
							type =>
								&type_id( $self, $self->param($type_str) ),
						}
					);
					$update = $self->db->resultset('DeliveryserviceRegex')
						->find( { deliveryservice => $id, regex => $re_id } );
					$update->update(
						{ set_number => $self->param($set_number_str) } );
					$regexp_set->{$re_id}->{updated} = 1;
				}
			}
			elsif ( $param =~ /re_type_new_(\d+)/ ) {

				# this is a newly added regexp.
				my $type_str       = 're_type_new_' . $1;
				my $re_str         = 're_re_new_' . $1;
				my $set_number_str = 're_order_new_' . $1;
				my $type
					= $self->db->resultset('Type')
					->search( { name => $self->param($type_str) } )
					->get_column('id')->single();
				my $regexp = $self->param($re_str);

				my $insert = $self->db->resultset('Regex')->create(
					{   pattern => $regexp,
						type    => &type_id( $self, $self->param($type_str) ),
					}
				);
				$insert->insert();
				my $new_re_id = $insert->id;

				my $de_re_insert
					= $self->db->resultset('DeliveryserviceRegex')->create(
					{   regex           => $new_re_id,
						deliveryservice => $id,
						set_number      => $self->param($set_number_str),
					}
					);
				$de_re_insert->insert();
			}
		}

		foreach my $re_id ( keys %{$regexp_set} ) {
			if ( !defined( $regexp_set->{$re_id}->{updated} ) ) {

				my $delete_re = $self->db->resultset('Regex')
					->search( { id => $re_id } );
				$delete_re->delete();
			}
		}

		$self->header_rewrite(
			$self->param('id'),
			$self->param('ds.profile'),
			$self->param('ds.xml_id'),
			$self->param('ds.edge_header_rewrite'), "edge"
		);
		$self->header_rewrite(
			$self->param('id'),
			$self->param('ds.profile'),
			$self->param('ds.xml_id'),
			$self->param('ds.mid_header_rewrite'), "mid"
		);
		$self->regex_remap(
			$self->param('id'),        $self->param('ds.profile'),
			$self->param('ds.xml_id'), $self->param('ds.regex_remap')
		);
		$self->cacheurl(
			$self->param('id'),        $self->param('ds.profile'),
			$self->param('ds.xml_id'), $self->param('ds.cacheurl')
		);

		$self->flash( message => "Delivery service updated!" );
		return $self->redirect_to( '/ds/' . $id );
	}
	else {
		&stash_role($self);
		my $rs_ds
			= $self->db->resultset('Deliveryservice')
			->search( { 'me.id' => $id },
			{ prefetch => [ { 'type' => undef }, { 'profile' => undef } ] } );
		my $data         = $rs_ds->single;
		my $cdn_domain   = &get_cdn_domain( $self, $id );
		my $server_count = $self->db->resultset('DeliveryserviceServer')
			->search( { deliveryservice => $id } )->count();
		my $static_count = $self->db->resultset('Staticdnsentry')
			->search( { deliveryservice => $id } )->count();
		my $regexp_set = &get_regexp_set( $self, $id );
		my @example_urls
			= &get_example_urls( $self, $id, $regexp_set, $data, $cdn_domain,
			$data->protocol );
		my $action;

		$self->stash(
			ds           => $data,
			fbox_layout  => 1,
			server_count => $server_count,
			static_count => $static_count,
			regexp_set   => $regexp_set,
			example_urls => \@example_urls,
			mode         => "edit",
		);
		$self->render('delivery_service/edit');
	}
}

sub check_regexp {
	my $self = shift;
	my $re   = shift;

	my $sep = "__NEWLINE__";
	my $err = "";
	if ( $re =~ /^\s/ || $re =~ /\s$/ ) {
		$err
			.= "Regular expression can not start or end with whitespace... (did you cut-and-paste?)";
	}

	if ( $re eq ".*" ) {
		$err
			= ".* is not a valid regexp, at least not for any of the CDN entries.";
	}

	my $regexp_err = &is_regexp($re);
	if ( $regexp_err ne "" ) {
		$regexp_err =~ s/;.*$//;
		chomp($regexp_err);
		$err .= "Error in regexp \"" . $re . "\"" . $regexp_err . $sep;
	}

	return $err;
}

# Create
sub create {
	my $self = shift;
	return $self->redirect_to("/modify_error") if !&is_oper($self);
	my $new_id = -1;
	my $cdn_id = $self->param('ds.cdn_id');
	my $xml_id = $self->param('ds.xml_id');

	my $existing = $self->db->resultset('Deliveryservice')->search( { xml_id => $xml_id } )->get_column('xml_id')->single();
	if ($existing) {
		$self->field('ds.xml_id')->is_equal( "", "A Delivery service with xml_id \"$xml_id\" already exists." );
	}

	if ( $self->check_deliveryservice_input() ) {
		my $insert = $self->db->resultset('Deliveryservice')->create(
			{   xml_id         => $self->paramAsScalar('ds.xml_id'),
				display_name   => $self->paramAsScalar('ds.display_name'),
				dscp           => $self->paramAsScalar( 'ds.dscp', 0 ),
				signed         => $self->paramAsScalar('ds.signed'),
				qstring_ignore => $self->paramAsScalar('ds.qstring_ignore'),
				geo_limit      => $self->paramAsScalar('ds.geo_limit'),
				http_bypass_fqdn =>
					$self->paramAsScalar('ds.http_bypass_fqdn'),
				dns_bypass_ip  => $self->paramAsScalar('ds.dns_bypass_ip'),
				dns_bypass_ip6 => $self->paramAsScalar('ds.dns_bypass_ip6'),
				dns_bypass_cname =>
					$self->paramAsScalar('ds.dns_bypass_cname'),
				dns_bypass_ttl  => $self->paramAsScalar('ds.dns_bypass_ttl'),
				org_server_fqdn => $self->paramAsScalar('ds.org_server_fqdn'),
				multi_site_origin =>
					$self->paramAsScalar('ds.multi_site_origin'),
				ccr_dns_ttl     => $self->paramAsScalar('ds.ccr_dns_ttl'),
				type            => $self->paramAsScalar('ds.type'),
				cdn_id          => $cdn_id,
				profile         => $self->paramAsScalar('ds.profile'),
				global_max_mbps => $self->hr_string_to_mbps(
					$self->paramAsScalar( 'ds.global_max_mbps', 0 )
				),
				global_max_tps =>
					$self->paramAsScalar( 'ds.global_max_tps', 0 ),
				miss_lat    => $self->paramAsScalar('ds.miss_lat'),
				miss_long   => $self->paramAsScalar('ds.miss_long'),
				long_desc   => $self->paramAsScalar('ds.long_desc'),
				long_desc_1 => $self->paramAsScalar('ds.long_desc_1'),
				long_desc_2 => $self->paramAsScalar('ds.long_desc_2'),
				max_dns_answers =>
					$self->paramAsScalar( 'ds.max_dns_answers', 0 ),
				info_url   => $self->paramAsScalar('ds.info_url'),
				check_path => $self->paramAsScalar('ds.check_path'),
				regional_geo_blocking  => $self->paramAsScalar('ds.regional_geo_blocking'),
				active     => $self->paramAsScalar('ds.active'),
				protocol   => $self->paramAsScalar('ds.protocol'),
				ipv6_routing_enabled =>
					$self->paramAsScalar('ds.ipv6_routing_enabled'),
				range_request_handling =>
					$self->paramAsScalar('ds.range_request_handling'),
				edge_header_rewrite =>
					$self->paramAsScalar('ds.edge_header_rewrite'),
				mid_header_rewrite =>
					$self->paramAsScalar( 'ds.mid_header_rewrite', undef ),
				regex_remap =>
					$self->paramAsScalar( 'ds.regex_remap', undef ),
				origin_shield =>
					$self->paramAsScalar( 'ds.origin_shield', undef ),
				cacheurl   => $self->paramAsScalar( 'ds.cacheurl',   undef ),
				remap_text => $self->paramAsScalar( 'ds.remap_text', undef ),
				initial_dispersion =>
					$self->paramAsScalar( 'ds.initial_dispersion', 1 ),
			}
		);
		$insert->insert();
		$new_id = $insert->id;
		&log(
			$self,
			"Create deliveryservice with xml_id:" . $self->param('ds.xml_id'),
			"UICHANGE"
		);

		if ( $new_id == -1 )
		{    # there was an error the flash will already be set,
			my $referer = $self->req->headers->header('referer');
			my $qstring = "?";
			my @params  = $self->param;
			foreach my $field (@params) {
				if ( $self->param($field) ne "" ) {
					$qstring .= "$field=" . $self->param($field) . "\&";
				}
			}
			chop($qstring);
			if ( defined($referer) ) {
				my $stripped = ( split( /\?/, $referer ) )[0];
				return $self->redirect_to( $stripped . $qstring );
			}
			else {
				return $self->render(
					text   => "ERR = Referer is not defined.",
					layout => undef
				);    # for testing - $referer is not defined there.
			}
		}

		my $regexp_set = undef;
		foreach my $param ( $self->param ) {
			if ( $param =~ /re_type_(\d+)/ ) {
				$regexp_set->[$1]->{type} = $self->param($param);
			}
			if ( $param =~ /re_re_(\d+)/ ) {
				$regexp_set->[$1]->{re} = $self->param($param);
			}
			if ( $param =~ /re_order_(\d+)/ ) {
				$regexp_set->[$1]->{order} = $self->param($param);
			}
		}

		foreach my $re ( @{$regexp_set} ) {
			if ( !defined( $re->{order} ) ) {
				next;
			}    # 0 gets iterated over if the form sends just a _1
			my $type
				= $self->db->resultset('Type')
				->search( { name => $re->{type} } )->get_column('id')
				->single();
			my $regexp = $re->{re};

			my $insert = $self->db->resultset('Regex')->create(
				{   pattern => $regexp,
					type    => $type,
				}
			);
			$insert->insert();
			my $new_re_id = $insert->id;

			my $de_re_insert
				= $self->db->resultset('DeliveryserviceRegex')->create(
				{   regex           => $new_re_id,
					deliveryservice => $new_id,
					set_number      => $re->{order},
				}
				);
			$de_re_insert->insert();
		}

		$self->header_rewrite(
			$new_id,
			$self->param('ds.profile'),
			$self->param('ds.xml_id'),
			$self->param('ds.edge_header_rewrite'), "edge"
		);
		$self->header_rewrite(
			$new_id,
			$self->param('ds.profile'),
			$self->param('ds.xml_id'),
			$self->param('ds.mid_header_rewrite'), "mid"
		);
		$self->regex_remap(
			$self->param('ds.profile'),
			$self->param('ds.xml_id'),
			$self->param('ds.regex_remap')
		);
		$self->cacheurl(
			$new_id,
			$self->param('ds.profile'),
			$self->param('ds.xml_id'),
			$self->param('ds.cacheurl')
		);

		##create dnssec keys for the new DS if DNSSEC is enabled for the CDN
		my $cdn_rs = $self->db->resultset('Cdn')->search( { id => $cdn_id } )
			->single();
		my $dnssec_enabled = $cdn_rs->dnssec_enabled;

		if ( $dnssec_enabled == 1 ) {
			$self->app->log->debug("dnssec is enabled, creating dnssec keys");
			$self->create_dnssec_keys( $cdn_rs->name,
				$self->param('ds.xml_id'), $new_id );
		}
		$self->flash( message => "Success!" );
		return $self->redirect_to( '/ds/' . $new_id );
	}
	else {
		my $selected_type    = $self->param('ds.type');
		my $selected_profile = $self->param('ds.profile');
		my $selected_cdn     = $self->param('ds.cdn');
		&stash_role($self);
		$self->stash(
			ds               => {},
			fbox_layout      => 1,
			selected_type    => $selected_type,
			selected_profile => $selected_profile,
			selected_cdn     => $selected_cdn,
			mode             => "add",
		);
		$self->render('delivery_service/add');
	}
}

sub create_dnssec_keys {
	my $self     = shift;
	my $cdn_name = shift;
	my $xml_id   = shift;
	my $ds_id    = shift;

	#get keys for cdn
	my $keys;
	my $response_container = $self->riak_get( "dnssec", $cdn_name );
	my $get_keys = $response_container->{'response'};
	$keys = decode_json( $get_keys->content );

#get default expiration days and ttl for DSs from CDN record to use when generating new keys
	my $cdn_ksk = $keys->{$cdn_name}->{ksk};
	my $k_exp_days = $self->get_key_expiration_days( $cdn_ksk, "365" );

	my $cdn_zsk = $keys->{$cdn_name}->{zsk};
	my $z_exp_days = $self->get_key_expiration_days( $cdn_zsk, "30" );

	my $dnskey_ttl = $self->get_key_ttl( $cdn_ksk, "60" );

	#create the ds domain name for dnssec keys
	my $domain_name             = $self->get_cdn_domain($ds_id);
	my $deliveryservice_regexes = $self->get_regexp_set($ds_id);
	my $rs_ds
		= $self->db->resultset('Deliveryservice')
		->search( { 'me.xml_id' => $xml_id },
		{ prefetch => [ { 'type' => undef }, { 'profile' => undef } ] } );
	my $data         = $rs_ds->single;
	my @example_urls = UI::DeliveryService::get_example_urls( $self, $ds_id,
		$deliveryservice_regexes, $data, $domain_name, $data->protocol );

#first one is the one we want.  period at end for dnssec, substring off stuff we dont want
	my $ds_name = $example_urls[0] . ".";
	my $length = length($ds_name) - CORE::index( $ds_name, "." );
	$ds_name = substr( $ds_name, CORE::index( $ds_name, "." ) + 1, $length );

	my $inception    = time();
	my $z_expiration = $inception + ( 86400 * $z_exp_days );
	my $k_expiration = $inception + ( 86400 * $k_exp_days );

	my $zsk
		= $self->get_dnssec_keys( "zsk", $ds_name, $dnskey_ttl, $inception,
		$z_expiration, "new", $inception );
	my $ksk
		= $self->get_dnssec_keys( "ksk", $ds_name, $dnskey_ttl, $inception,
		$k_expiration, "new", $inception );

	#add to keys hash
	$keys->{$xml_id} = {
		zsk => [$zsk],
		ksk => [$ksk]
	};

	#put keys back in Riak
	my $json_data = encode_json($keys);
	$response_container = $self->riak_put( "dnssec", $cdn_name, $json_data );
}

sub get_key_expiration_days {
	my $self        = shift;
	my $keys        = shift;
	my $default_exp = shift;
	foreach my $key (@$keys) {
		my $status = $key->{status};
		if ( $status eq 'new' ) { #ignore anything other than the 'new' record
			my $exp   = $key->{expirationDate};
			my $incep = $key->{inceptionDate};
			return ( $exp - $incep ) / 86400;
		}
	}
	return $default_exp;
}

sub get_key_ttl {
	my $self = shift;
	my $keys = shift;
	my $ttl  = shift;

	foreach my $key (@$keys) {
		my $status = $key->{status};
		if ( $status eq 'new' ) { #ignore anything other than the 'new' record
			return $key->{ttl};
		}
	}
	return $ttl;
}

# for the add delivery service view
sub add {
	my $self = shift;
	&stash_role($self);
	$self->stash(
		fbox_layout      => 1,
		ds               => {},
		selected_type    => "",
		selected_profile => "",
		selected_cdn     => "",
		mode             => 'add'    #for form generation
	);
	my @params = $self->param;
	foreach my $field (@params) {
		$self->stash( $field => $self->param($field) );
	}
}

1;
