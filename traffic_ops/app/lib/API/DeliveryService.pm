package API::DeliveryService;
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
use UI::DeliveryService;
use Mojo::Base 'Mojolicious::Controller';
use Mojolicious::Validator;
use Mojolicious::Validator::Validation;
use Email::Valid;
use Validate::Tiny ':all';
use Data::Dumper;
use Common::ReturnCodes qw(SUCCESS ERROR);
use JSON;
use MojoPlugins::Response;
use UI::DeliveryService;

my $valid_server_types = {
	edge => "EDGE",
	mid  => "MID",
};

# this structure maps the above types to the allowed metrics below
my $valid_metric_types = {
	origin_tps => "mid",
	ooff       => "mid",
};

sub delivery_services {
	my $self         = shift;
	my $id           = $self->param('id');
	my $logs_enabled = $self->param('logsEnabled');
	my $current_user = $self->current_user()->{username};

	my $rs;
	my $tm_user_id;
	my $forbidden;
	if ( defined($id) || defined($logs_enabled) ) {
		( $forbidden, $rs, $tm_user_id ) = $self->get_delivery_service_params( $current_user, $id, $logs_enabled );
	}
	else {
		( $rs, $tm_user_id ) = $self->get_delivery_services_by_user($current_user);
	}

	my @data;
	if ( defined($rs) ) {
		while ( my $row = $rs->next ) {
			my $cdn_name  = defined( $row->cdn_id ) ? $row->cdn->name : "";
			my $re_rs     = $row->deliveryservice_regexes;
			my @matchlist = ();
			while ( my $re_row = $re_rs->next ) {
				push(
					@matchlist, {
						type      => $re_row->regex->type->name,
						pattern   => $re_row->regex->pattern,
						setNumber => $re_row->set_number,
					}
				);
			}
			my $cdn_domain = &UI::DeliveryService::get_cdn_domain( $self, $row->id );
			my $regexp_set = &UI::DeliveryService::get_regexp_set( $self, $row->id );
			my @example_urls = &UI::DeliveryService::get_example_urls( $self, $row->id, $regexp_set, $row, $cdn_domain, $row->protocol );
			push(
				@data, {
					"id"                       => $row->id,
					"xmlId"                    => $row->xml_id,
					"displayName"              => $row->display_name,
					"dscp"                     => $row->dscp,
					"signed"                   => \$row->signed,
					"qstringIgnore"            => $row->qstring_ignore,
					"geoLimit"                 => $row->geo_limit,
					"geoLimitCountries"        => $row->geo_limit_countries,
					"geoProvider"              => $row->geo_provider,
					"httpBypassFqdn"           => $row->http_bypass_fqdn,
					"dnsBypassIp"              => $row->dns_bypass_ip,
					"dnsBypassIp6"             => $row->dns_bypass_ip6,
					"dnsBypassCname"           => $row->dns_bypass_cname,
					"dnsBypassTtl"             => $row->dns_bypass_ttl,
					"orgServerFqdn"            => $row->org_server_fqdn,
					"multiSiteOrigin"          => $row->multi_site_origin,
					"multiSiteOriginAlgorithm" => $row->multi_site_origin_algorithm,
					"ccrDnsTtl"                => $row->ccr_dns_ttl,
					"type"                     => $row->type->name,
					"profileName"              => $row->profile->name,
					"profileDescription"       => $row->profile->description,
					"cdnName"                  => $cdn_name,
					"globalMaxMbps"            => $row->global_max_mbps,
					"globalMaxTps"             => $row->global_max_tps,
					"headerRewrite"            => $row->edge_header_rewrite,
					"edgeHeaderRewrite"        => $row->edge_header_rewrite,
					"midHeaderRewrite"         => $row->mid_header_rewrite,
					"trResponseHeaders"        => $row->tr_response_headers,
					"regexRemap"               => $row->regex_remap,
					"longDesc"                 => $row->long_desc,
					"longDesc1"                => $row->long_desc_1,
					"longDesc2"                => $row->long_desc_2,
					"maxDnsAnswers"            => $row->max_dns_answers,
					"infoUrl"                  => $row->info_url,
					"missLat"                  => $row->miss_lat,
					"missLong"                 => $row->miss_long,
					"checkPath"                => $row->check_path,
					"matchList"                => \@matchlist,
					"active"                   => \$row->active,
					"protocol"                 => $row->protocol,
					"ipv6RoutingEnabled"       => \$row->ipv6_routing_enabled,
					"rangeRequestHandling"     => $row->range_request_handling,
					"cacheurl"                 => $row->cacheurl,
					"remapText"                => $row->remap_text,
					"initialDispersion"        => $row->initial_dispersion,
					"exampleURLs"              => \@example_urls,
					"logsEnabled"              => \$row->logs_enabled,
				}
			);
		}
	}

	return defined($forbidden) ? $self->forbidden() : $self->success( \@data );
}

sub get_delivery_services_by_user {
	my $self         = shift;
	my $current_user = shift;

	my $tm_user_id;
	my $rs;
	if ( &is_privileged($self) ) {
		$rs = $self->db->resultset('Deliveryservice')->search( undef, { prefetch => [ 'cdn', 'deliveryservice_regexes' ], order_by => 'xml_id' } );
	}
	else {
		my $tm_user = $self->db->resultset('TmUser')->search( { username => $current_user } )->single();
		$tm_user_id = $tm_user->id;

		my @ds_ids = $self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $tm_user_id } )->get_column('deliveryservice')->all();
		$rs = $self->db->resultset('Deliveryservice')
			->search( { 'me.id' => { -in => \@ds_ids } }, { prefetch => [ 'cdn', 'deliveryservice_regexes' ], order_by => 'xml_id' } );
	}

	return ( $rs, $tm_user_id );
}

sub get_delivery_service_params {
	my $self         = shift;
	my $current_user = shift;
	my $id           = shift;
	my $logs_enabled = shift;

	# Convert to 1 or 0
	$logs_enabled = $logs_enabled ? 1 : 0;

	my $tm_user_id;
	my $rs;
	my $forbidden;
	my $condition;
	if ( &is_privileged($self) ) {
		if ( defined($id) ) {
			$condition = ( { 'me.id' => $id } );
		}
		else {
			$condition = ( { 'me.logs_enabled' => $logs_enabled } );
		}
		my @ds_ids = $rs =
			$self->db->resultset('Deliveryservice')->search( $condition, { prefetch => [ 'cdn', 'deliveryservice_regexes' ], order_by => 'xml_id' } );
	}
	elsif ( $self->is_delivery_service_assigned($id) ) {
		my $tm_user = $self->db->resultset('TmUser')->search( { username => $current_user } )->single();
		$tm_user_id = $tm_user->id;

		my @ds_ids =
			$self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $tm_user_id, deliveryservice => $id } )->get_column('deliveryservice')
			->all();
		$rs =
			$self->db->resultset('Deliveryservice')
			->search( { 'me.id' => { -in => \@ds_ids } }, { prefetch => [ 'cdn', 'deliveryservice_regexes' ], order_by => 'xml_id' } );
	}
	elsif ( !$self->is_delivery_service_assigned($id) ) {
		$forbidden = "true";
	}

	return ( $forbidden, $rs, $tm_user_id );
}

sub routing {
	my $self = shift;

	# get and pass { cdn_name => $foo } into get_routing_stats
	my $id = $self->param('id');

	if ( $self->is_valid_delivery_service($id) ) {
		if ( $self->is_delivery_service_assigned($id) || &is_admin($self) || &is_oper($self) ) {
			my $result = $self->db->resultset("Deliveryservice")->search( { 'me.id' => $id }, { prefetch => ['cdn'] } )->single();
			my $cdn_name = $result->cdn->name;

			# we expect type to be a dns or http type, but strip off any trailing bit
			my $stat_key = lc( $result->type->name );
			$stat_key =~ s/^(dns|http).*/$1/;
			$stat_key .= "Map";
			my $re_rs = $result->deliveryservice_regexes;
			my @patterns;
			while ( my $re_row = $re_rs->next ) {
				push( @patterns, $re_row->regex->pattern );
			}

			my $e = $self->get_routing_stats( { stat_key => $stat_key, patterns => \@patterns, cdn_name => $cdn_name } );
			if ( defined($e) ) {
				$self->alert($e);
			}
		}
		else {
			$self->forbidden("Forbidden. Delivery service not assigned to user.");
		}
	}
	else {
		$self->not_found();
	}
}

sub capacity {
	my $self = shift;

	# get and pass { cdn_name => $foo } into get_cache_capacity
	my $id = $self->param('id');

	if ( $self->is_valid_delivery_service($id) ) {
		if ( $self->is_delivery_service_assigned($id) || &is_admin($self) || &is_oper($self) ) {
			my $result = $self->db->resultset("Deliveryservice")->search( { 'me.id' => $id }, { prefetch => ['cdn'] } )->single();
			my $cdn_name = $result->cdn->name;

			$self->get_cache_capacity( { delivery_service => $result->xml_id, cdn_name => $cdn_name } );
		}
		else {
			$self->forbidden("Forbidden. Delivery service not assigned to user.");
		}
	}
	else {
		$self->not_found();
	}
}

sub health {
	my $self = shift;
	my $id   = $self->param('id');

	if ( $self->is_valid_delivery_service($id) ) {
		if ( $self->is_delivery_service_assigned($id) || &is_admin($self) || &is_oper($self) ) {
			my $result = $self->db->resultset("Deliveryservice")->search( { 'me.id' => $id }, { prefetch => ['cdn'] } )->single();
			my $cdn_name = $result->cdn->name;

			return ( $self->get_cache_health( { server_type => "caches", delivery_service => $result->xml_id, cdn_name => $cdn_name } ) );
		}
		else {
			$self->forbidden("Forbidden. Delivery service not assigned to user.");
		}
	}
	else {
		$self->not_found();
	}
}

sub state {

	my $self = shift;
	my $id   = $self->param('id');

	if ( $self->is_valid_delivery_service($id) ) {
		if ( $self->is_delivery_service_assigned($id) || &is_admin($self) || &is_oper($self) ) {
			my $result      = $self->db->resultset("Deliveryservice")->search( { 'me.id' => $id }, { prefetch => ['cdn'] } )->single();
			my $cdn_name    = $result->cdn->name;
			my $ds_name     = $result->xml_id;
			my $rascal_data = $self->get_rascal_state_data( { type => "RASCAL", state_type => "deliveryServices", cdn_name => $cdn_name } );

			# scalar refs get converted into json booleans
			my $data = {
				enabled  => \0,
				failover => {
					enabled     => \0,
					configured  => \0,
					destination => undef,
					locations   => []
				}
			};

			if ( exists( $rascal_data->{$cdn_name} ) && exists( $rascal_data->{$cdn_name}->{state}->{$ds_name} ) ) {
				my $health_config = $self->get_health_config($cdn_name);
				my $c             = $rascal_data->{$cdn_name}->{config}->{deliveryServices}->{$ds_name};
				my $r             = $rascal_data->{$cdn_name}->{state}->{$ds_name};

				if ( exists( $health_config->{deliveryServices}->{$ds_name} ) ) {
					my $h = $health_config->{deliveryServices}->{$ds_name};

					if ( $h->{status} eq "REPORTED" ) {
						$data->{enabled} = \1;
					}

					if ( !$r->{isAvailable} ) {
						$data->{failover}->{enabled}   = \1;
						$data->{failover}->{locations} = $r->{disabledLocations};
					}

					if ( exists( $h->{"health.threshold.total.kbps"} ) ) {

						# get current kbps, calculate percent used
						$data->{failover}->{configured} = \1;
						push( @{ $data->{failover}->{limits} }, { metric => "total_kbps", limit => $h->{"health.threshold.total.kbps"} } );
					}

					if ( exists( $h->{"health.threshold.total.tps_total"} ) ) {

						# get current tps, calculate percent used
						$data->{failover}->{configured} = \1;
						push( @{ $data->{failover}->{limits} }, { metric => "total_tps", limit => $h->{"health.threshold.total.tps_total"} } );
					}

					if ( exists( $c->{bypassDestination} ) ) {
						my @k        = keys( %{ $c->{bypassDestination} } );
						my $type     = shift(@k);
						my $location = undef;

						if ( $type eq "DNS" ) {
							$location = $c->{bypassDestination}->{$type}->{ip};
						}
						elsif ( $type eq "HTTP" ) {
							my $port = ( exists( $c->{bypassDestination}->{$type}->{port} ) ) ? ":" . $c->{bypassDestination}->{$type}->{port} : "";
							$location = sprintf( "http://%s%s", $c->{bypassDestination}->{$type}->{fqdn}, $port );
						}

						$data->{failover}->{destination} = {
							type     => $type,
							location => $location
						};
					}
				}
			}

			$self->success($data);
		}
		else {
			$self->forbidden("Forbidden. Delivery service not assigned to user.");
		}
	}
	else {
		$self->not_found();
	}
}

sub request {
	my $self     = shift;
	my $email_to = $self->req->json->{emailTo};
	my $details  = $self->req->json->{details};

	my $is_email_valid = Email::Valid->address($email_to);

	if ( !$is_email_valid ) {
		return $self->alert("Please provide a valid email address to send the delivery service request to.");
	}

	my ( $is_valid, $result ) = $self->is_deliveryservice_request_valid($details);

	if ($is_valid) {
		if ( $self->send_deliveryservice_request( $email_to, $details ) ) {
			return $self->success_message( "Delivery Service request sent to " . $email_to );
		}
	}
	else {
		return $self->alert($result);
	}
}

sub is_deliveryservice_request_valid {
	my $self    = shift;
	my $details = shift;

	my $rules = {
		fields => [
			qw/customer contentType deliveryProtocol routingType serviceDesc peakBPSEstimate peakTPSEstimate maxLibrarySizeEstimate originURL hasOriginDynamicRemap originTestFile hasOriginACLWhitelist originHeaders otherOriginSecurity queryStringHandling rangeRequestHandling hasSignedURLs hasNegativeCachingCustomization negativeCachingCustomizationNote serviceAliases rateLimitingGBPS rateLimitingTPS overflowService headerRewriteEdge headerRewriteMid headerRewriteRedirectRouter notes/
		],

		# Validation checks to perform
		checks => [

			# required deliveryservice request fields
			[
				qw/customer contentType deliveryProtocol routingType serviceDesc peakBPSEstimate peakTPSEstimate maxLibrarySizeEstimate originURL hasOriginDynamicRemap originTestFile hasOriginACLWhitelist queryStringHandling rangeRequestHandling hasSignedURLs hasNegativeCachingCustomization rateLimitingGBPS rateLimitingTPS/
			] => is_required("is required")

		]
	};

	# Validate the input against the rules
	my $result = validate( $details, $rules );

	if ( $result->{success} ) {
		return ( 1, $result->{data} );
	}
	else {
		return ( 0, $result->{error} );
	}
}

sub update_profileparameter {
	my $self   = shift;
	my $ds_id = shift;
	my $profile_id = shift;
	my $params = shift;

	&UI::DeliveryService::header_rewrite( $self, $ds_id, $profile_id, $params->{xmlId}, $params->{edgeHeaderRewrite}, "edge" );
	&UI::DeliveryService::header_rewrite( $self, $ds_id, $profile_id, $params->{xmlId}, $params->{midHeaderRewrite},  "mid" );
	&UI::DeliveryService::regex_remap( $self, $ds_id, $profile_id, $params->{xmlId}, $params->{regexRemap} );
	&UI::DeliveryService::cacheurl( $self, $ds_id, $profile_id, $params->{xmlId}, $params->{cacheurl} );
}

sub create {
	my $self   = shift;
	my $params = $self->req->json;

	if ( !&is_oper($self) ) {
		return $self->forbidden();
	}

	my ($transformed_params, $err) = (undef, undef);
	($transformed_params, $err) = $self->check_params($params);
	if ( defined($err) ) {
		return $self->alert($err);
	}

        my $existing = $self->db->resultset('Deliveryservice')->search( { xml_id => $params->{xmlId} } )->get_column('xml_id')->single();
        if ( $existing ) {
                $self->alert("a delivery service with xmlId " . $params->{xmlId} . " already exists." );
        }

	my $value=$self->new_value($params, $transformed_params);
	my $insert = $self->db->resultset('Deliveryservice')->create($value);
	$insert->insert();
	my $new_id = $insert->id;

	if ( $new_id > 0 ) {
		my $patterns = $params->{matchList};
		foreach my $re (@$patterns) {
			my $type = $self->db->resultset('Type')->search( { name => $re->{type} } )->get_column('id')->single();
			my $regexp = $re->{pattern};

			my $insert = $self->db->resultset('Regex')->create(
				{
					pattern => $regexp,
					type    => $type,
				}
			);
			$insert->insert();
			my $new_re_id = $insert->id;

			my $de_re_insert = $self->db->resultset('DeliveryserviceRegex')->create(
				{
					regex           => $new_re_id,
					deliveryservice => $new_id,
					set_number      => defined($re->{setNumber}) ? $re->{setNumber} : 0,
				}
			);
			$de_re_insert->insert();
		}

		my $profile_id=$transformed_params->{ profile_id };
		$self->update_profileparameter($new_id, $profile_id, $params);

		my $cdn_rs = $self->db->resultset('Cdn')->search( { id => $transformed_params->{cdn_id} } )->single();
		my $dnssec_enabled = $cdn_rs->dnssec_enabled;
		if ( $dnssec_enabled == 1 ) {
			$self->app->log->debug("dnssec is enabled, creating dnssec keys");
			&UI::DeliveryService::create_dnssec_keys( $self, $cdn_rs->name, $params->{xmlId}, $new_id );
		}

		&log( $self, "Create deliveryservice with xml_id: " . $params->{xmlId}, " APICHANGE" );

		my $response = $self->get_response($new_id);
		return $self->success($response, "Delivery service was created: " . $new_id);
	}

	my $r = "Create Delivery Service fail, insert to database failed.";
	return $self->alert($r);
}

sub nodef_to_default {
	my $self    = shift;
	my $v       = shift;
	my $default = shift;

    return $v || $default;
}

sub get_types {
	my $self         = shift;
	my $use_in_table = shift;
	my $types;
	my $rs = $self->db->resultset('Type')->search( { use_in_table => $use_in_table } );
	while ( my $row = $rs->next ) {
		$types->{ $row->name } = $row->id;
	}
	return $types;
}

sub assign_servers {
	my $self      = shift;
	my $ds_xml_Id = $self->param('xml_id');
	my $params    = $self->req->json;

	if ( !defined($params) ) {
		return $self->alert("parameters are JSON format, please check!");
	}
	if ( !&is_oper($self) ) {
		return $self->alert("You must be an ADMIN or OPER to perform this operation!");
	}

	if ( !exists( $params->{serverNames} ) ) {
		return $self->alert("Parameter 'serverNames' is required.");
	}

	my $dsid = $self->db->resultset('Deliveryservice')->search( { xml_id => $ds_xml_Id } )->get_column('id')->single();
	if ( !defined($dsid) ) {
		return $self->alert( "DeliveryService[" . $ds_xml_Id . "] is not found." );
	}

	my @server_ids;
	my $svrs = $params->{serverNames};
	foreach my $svr (@$svrs) {
		my $svr_id = $self->db->resultset('Server')->search( { host_name => $svr } )->get_column('id')->single();
		if ( !defined($svr_id) ) {
			return $self->alert( "Server[" . $svr . "] is not found in database." );
		}
		push( @server_ids, $svr_id );
	}

	# clean up
	my $delete = $self->db->resultset('DeliveryserviceServer')->search( { deliveryservice => $dsid } );
	$delete->delete();

	# assign servers
	foreach my $s_id (@server_ids) {
		my $insert = $self->db->resultset('DeliveryserviceServer')->create(
			{
				deliveryservice => $dsid,
				server          => $s_id,
			}
		);
		$insert->insert();
	}

	my $ds = $self->db->resultset('Deliveryservice')->search( { id => $dsid } )->single();
	&UI::DeliveryService::header_rewrite( $self, $ds->id, $ds->profile, $ds->xml_id, $ds->edge_header_rewrite, "edge" );

	my $response;
	$response->{xmlId} = $ds->xml_id;
	$response->{'serverNames'} = \@$svrs;

	return $self->success($response);
}

sub check_params {
	my $self = shift;
	my $params = shift;
	my $transformed_params = undef;

	if ( !defined($params) ) {
		return (undef, "parameters should in json format, please check!");
	}

	if ( !defined($params->{xmlId}) ) {
		return (undef, "parameter xmlId is must." );
	}

	if ( defined($params->{active}) ) {
		if ( $params->{active} eq "true" || $params->{active} == 1 ) {
			$transformed_params->{active} = 1;
		} elsif ( $params->{active} eq "false" || $params->{active} == 0 ) {
			$transformed_params->{active} = 0;
		} else {
			return (undef, "active must be true|false." );
		}
	} else {
		return (undef, "parameter active is must." );
	}

	if ( defined($params->{type}) ) {
		my $rs = $self->get_types("deliveryservice");
		if ( !exists $rs->{ $params->{type} } ) {
			return (undef, "type (" . $params->{type} . ") must be deliveryservice type." );
		}
		else {
			$transformed_params->{type} = $rs->{ $params->{type} };
		}
	} else {
		return (undef, "parameter type is must." );
	}

	if ( defined($params->{protocol}) ) {
		if ( !( ( $params->{protocol} eq "0" ) || ( $params->{protocol} eq "1" ) || ( $params->{protocol} eq "2" ) ) ) {
			return (undef, "protocol must be 0|1|2." );
		}
	} else {
		return (undef, "parameter protocol is must." );
	}

	if ( defined($params->{profileName}) ) {
		my $ccr_profiles;
		my @ccrprofs = $self->db->resultset('Profile')->search( { name => { -like => 'CCR%' } } )->get_column('id')->all();
		my $rs = $self->db->resultset('ProfileParameter')->search(
				{ profile => { -in => \@ccrprofs }, 'parameter.name' => 'domain_name', 'parameter.config_file' => 'CRConfig.json' },
				{ prefetch => [ 'parameter', 'profile' ] }
		);
		while ( my $row = $rs->next ) {
			$ccr_profiles->{ $row->profile->name } = $row->profile->id;
		}
		if ( !exists $ccr_profiles->{ $params->{profileName} } ) {
			return (undef, "profileName (" . $params->{profileName} . ") must be CCR profiles." );
		}
		else {
			$transformed_params->{ profile_id } = $ccr_profiles->{ $params->{profileName} };
		}
	} else {
		return (undef, "parameter profileName is must." );
	}

	if ( defined($params->{cdnName}) ) {
		my $cdn_id = $self->db->resultset('Cdn')->search( { name => $params->{cdnName} } )->get_column('id')->single();
		if ( !defined $cdn_id ) {
			return (undef, "cdnName (" . $params->{cdnName} . ") does not exists." );
		} else {
			$transformed_params->{ cdn_id } = $cdn_id;
		}
	} else {
		return (undef, "parameter cdnName is must." );
	}

	if ( defined($params->{matchList}) ) {
		my $patterns     = $params->{matchList};
		my $patterns_len = @$patterns;
		if ( $patterns_len == 0 ) {
			return (undef, "At least have 1 pattern in matchList.");
		}
	} else {
		return (undef, "parameter matchList is must." );
	}

	if ( defined($params->{multiSiteOrigin}) ) {
		if ( !( ( $params->{multiSiteOrigin} eq "0" ) || ( $params->{multiSiteOrigin} eq "1" ) ) ) {
			return (undef, "multiSiteOrigin must be 0|1." );
		}
	} else {
		return (undef, "parameter multiSiteOrigin is must." );
	}

	if ( !defined($params->{displayName}) ) {
		return (undef, "parameter displayName is must." );
	}

	if ( defined($params->{orgServerFqdn}) ) {
		if ( $params->{orgServerFqdn} !~ /^https?:\/\// ) {
			return (undef, "orgServerFqdn must start with http(s)://" );
		}
	} else {
		return (undef, "parameter orgServerFqdn is must." );
	}

	if ( defined($params->{logsEnabled}) ) {
		if ( $params->{logsEnabled} eq "true" || $params->{logsEnabled} == 1 ) {
			$transformed_params->{logsEnabled} = 1;
		} elsif ( $params->{logsEnabled} eq "false" || $params->{logsEnabled} == 0 ) {
			$transformed_params->{logsEnabled} = 0;
		} else {
			return (undef, "logsEnabled must be true|false." );
		}
	} else {
		$transformed_params->{logsEnabled} = 0;
	}

	return ($transformed_params, undef);
}

sub new_value {
	my $self = shift;
	my $params = shift;
	my $transformed_params = shift;

	my $value = {
			xml_id                 => $params->{xmlId},
			display_name           => $params->{displayName},
			dscp                   => $self->nodef_to_default( $params->{dscp}, 0 ),
			signed                 => $self->nodef_to_default( $params->{signed}, 0 ),
			qstring_ignore         => $params->{qstringIgnore},
			geo_limit              => $params->{geoLimit},
			geo_limit_countries    => $params->{geoLimitCountries},
			geo_provider           => $params->{geoProvider},
			http_bypass_fqdn       => $params->{httpBypassFqdn},
			dns_bypass_ip          => $params->{dnsBypassIp},
			dns_bypass_ip6         => $params->{dnsBypassIp6},
			dns_bypass_cname       => $params->{dnsBypassCname},
			dns_bypass_ttl         => $params->{dnsBypassTtl},
			org_server_fqdn        => $params->{orgServerFqdn},
			multi_site_origin      => $params->{multiSiteOrigin},
			ccr_dns_ttl            => $params->{ccrDnsTtl},
			type                   => $transformed_params->{type},
			profile                => $transformed_params->{profile_id},
			cdn_id                 => $transformed_params->{cdn_id},
			global_max_mbps        => $self->nodef_to_default( $params->{globalMaxMbps}, 0 ),
			global_max_tps         => $self->nodef_to_default( $params->{globalMaxTps}, 0 ),
			miss_lat               => $params->{missLat},
			miss_long              => $params->{missLong},
			long_desc              => $params->{longDesc},
			long_desc_1            => $params->{longDesc1},
			long_desc_2            => $params->{longDesc2},
			max_dns_answers        => $self->nodef_to_default( $params->{maxDnsAnswers}, 0 ),
			info_url               => $params->{infoUrl},
			check_path             => $params->{checkPath},
			active                 => $transformed_params->{active},
			protocol               => $params->{protocol},
			ipv6_routing_enabled   => $params->{ipv6RoutingEnabled},
			range_request_handling => $params->{rangeRequestHandling},
			edge_header_rewrite    => $params->{edgeHeaderRewrite},
			mid_header_rewrite     => $params->{midHeaderRewrite},
			regex_remap            => $params->{regexRemap},
			origin_shield          => $params->{originShield},
			cacheurl               => $params->{cacheurl},
			remap_text             => $params->{remapText},
			initial_dispersion     => $params->{initialDispersion},
			regional_geo_blocking  => $self->nodef_to_default($params->{regionalGeoBlocking}, 0),
			ssl_key_version        => $params->{sslKeyVersion},
			tr_request_headers     => $params->{trRequestHeaders},
			tr_response_headers    => $params->{trResponseHeaders},
			logs_enabled           => $transformed_params->{logsEnabled},
		};

	return $value;
}

sub get_response {
	my $self   = shift;
	my $ds_id  = shift;

	my $response;
	my $rs = $self->db->resultset('Deliveryservice')->find( { id => $ds_id } );
	if ( defined($rs) ) {
		my $cdn_name = $self->db->resultset('Cdn')->search( { id => $rs->cdn_id } )->get_column('name')->single();

		$response->{id}                     = $rs->id;
		$response->{xmlId}                  = $rs->xml_id;
		$response->{active}                 = $rs->active==1 ? "true" : "false";
		$response->{dscp}                   = $rs->dscp;
		$response->{signed}                 = $rs->signed;
		$response->{qstringIgnore}          = $rs->qstring_ignore;
		$response->{geoLimit}               = $rs->geo_limit;
		$response->{geoLimitCountries}      = $rs->geo_limit_countries;
		$response->{geoProvider}            = $rs->geo_provider;
		$response->{httpBypassFqdn}         = $rs->http_bypass_fqdn;
		$response->{dnsBypassIp}            = $rs->dns_bypass_ip;
		$response->{dnsBypassIp6}           = $rs->dns_bypass_ip6;
		$response->{dnsBypassTtl}           = $rs->dns_bypass_ttl;
		$response->{orgServerFqdn}          = $rs->org_server_fqdn;
		$response->{type}                   = $rs->type->name;
		$response->{profileName}            = $rs->profile->name;
		$response->{cdnName}                = $cdn_name;
		$response->{ccrDnsTtl}              = $rs->ccr_dns_ttl;
		$response->{globalMaxMbps}          = $rs->global_max_mbps;
		$response->{globalMaxTps}           = $rs->global_max_tps;
		$response->{longDesc}               = $rs->long_desc;
		$response->{longDesc1}              = $rs->long_desc_1;
		$response->{longDesc2}              = $rs->long_desc_2;
		$response->{maxDnsAnswers}          = $rs->max_dns_answers;
		$response->{infoUrl}                = $rs->info_url;
		$response->{missLat}                = $rs->miss_lat;
		$response->{missLong}               = $rs->miss_long;
		$response->{checkPath}              = $rs->check_path;
		$response->{protocol}               = $rs->protocol;
		$response->{sslKeyVersion}          = $rs->ssl_key_version;
		$response->{ipv6RoutingEnabled}     = $rs->ipv6_routing_enabled;
		$response->{rangeRequestHandling}   = $rs->range_request_handling;
		$response->{edgeHeaderRewrite}      = $rs->edge_header_rewrite;
		$response->{originShield}           = $rs->origin_shield;
		$response->{midHeaderRewrite}       = $rs->mid_header_rewrite;
		$response->{regexRemap}             = $rs->regex_remap;
		$response->{cacheurl}               = $rs->cacheurl;
		$response->{remapText}              = $rs->remap_text;
		$response->{multiSiteOrigin}        = $rs->multi_site_origin;
		$response->{displayName}            = $rs->display_name;
		$response->{trResponseHeaders}      = $rs->tr_response_headers;
		$response->{initialDispersion}      = $rs->initial_dispersion;
		$response->{dnsBypassCname}         = $rs->dns_bypass_cname;
		$response->{regionalGeoBlocking}    = $rs->regional_geo_blocking;
		$response->{trRequestHeaders}       = $rs->tr_request_headers;
		$response->{logsEnabled}            = $rs->logs_enabled==1 ? "true" : "false";
	}

	my @pats = ();
	$rs = $self->db->resultset('DeliveryserviceRegex')->search( { deliveryservice => $ds_id } );
	while ( my $row = $rs->next ) {
		push(
			@pats, {
				'pattern'   => $row->regex->pattern,
				'type'      => $row->regex->type->name,
				'setNumber' => $row->set_number,
			}
		);
	}
	$response->{matchList} = \@pats;

	return $response;
}

sub update {
	my $self   = shift;
	my $id     = $self->param('id');
	my $params = $self->req->json;

	if ( !&is_oper($self) ) {
		return $self->forbidden();
	}

	my $ds = $self->db->resultset('Deliveryservice')->find( { id => $id } );
	if ( !defined($ds) ) {
		return $self->not_found();
	}

	my ($transformed_params, $err) = (undef, undef);
	($transformed_params, $err) = $self->check_params($params);
	if ( defined($err) ) {
		return $self->alert($err);
	}

	my $existing = $self->db->resultset('Deliveryservice')->search( { xml_id => $params->{xmlId} } )->get_column('xml_id')->single();
	if ( $existing && $existing ne $ds->xml_id ) {
		$self->alert("a delivery service with xmlId " . $params->{xmlId} . " already exists." );
	}
	if ( $transformed_params->{ type } != $ds->type->id ) {
		return $self->alert("delivery service type can't be changed");
	}

	my $value=$self->new_value($params, $transformed_params);
	$ds->update($value);

	if ( defined($params->{matchList}) ) {
		my $patterns     = $params->{matchList};
		my $patterns_len = @$patterns;

		my $rs = $self->db->resultset('RegexesForDeliveryService')->search( {}, { bind => [$id] } );
		my $last_number = $rs->count;

		my $row = $rs->next;
		my $update_number;
		my $re;
		for ( $update_number=0; $update_number < $last_number && $update_number < $patterns_len; $update_number++ ) {
			$re = @$patterns[$update_number];
			my $type = $self->db->resultset('Type')->search( { name => $re->{type} } )->get_column('id')->single();
			my $update = $self->db->resultset('Regex')->find( { id => $row->id } );
			$update->update(
				{
					pattern => $re->{pattern},
					type    => $type,
				}
			);
			$update = $self->db->resultset('DeliveryserviceRegex')->find( { deliveryservice => $id, regex => $row->id } );
			$update->update( { set_number => defined($re->{setNumber}) ? $re->{setNumber} : 0 } );
			$row = $rs->next;
		}

		if ( $patterns_len > $last_number ) {
			for ( ; $update_number < $patterns_len; $update_number++ ) {
				$re = @$patterns[$update_number];
				my $type = $self->db->resultset('Type')->search( { name => $re->{type} } )->get_column('id')->single();
				my $insert = $self->db->resultset('Regex')->create(
					{
						pattern => $re->{pattern},
						type    => $type,
					}
				);
				$insert->insert();
				my $new_re_id = $insert->id;
				my $de_re_insert = $self->db->resultset('DeliveryserviceRegex')->create(
					{
						regex           => $new_re_id,
						deliveryservice => $id,
						set_number      => defined($re->{setNumber}) ? $re->{setNumber} : 0,
					}
				);
				$de_re_insert->insert();
			}
		}

		while ( $row ) {
			my $delete_re = $self->db->resultset('Regex')->search( { id => $row->id } );
			$delete_re->delete();
			$row = $rs->next;
		}
	}

	my $profile_id=$transformed_params->{ profile_id };
	$self->update_profileparameter($id, $profile_id, $params);

	&log( $self, "Update deliveryservice with xml_id: " . $params->{xmlId}, " APICHANGE" );

	my $response = $self->get_response($id);
	return $self->success($response, "Delivery service was updated: " . $id);
}

sub delete {
	my $self   = shift;
	my $id     = $self->param('id');

	if ( !&is_oper($self) ) {
		return $self->forbidden();
	}

	my $ds = $self->db->resultset('Deliveryservice')->find( { id => $id } );
	if ( !defined($ds) ) {
		return $self->not_found();
	}

	my @regexp_id_list = $self->db->resultset('DeliveryserviceRegex')->search( { deliveryservice => $id } )->get_column('regex')->all();

	my $dsname = $self->db->resultset('Deliveryservice')->search( { id => $id } )->get_column('xml_id')->single();
	my $delete = $self->db->resultset('Deliveryservice')->search( { id => $id } );
	$delete->delete();

	my $delete_re = $self->db->resultset('Regex')->search( { id => { -in => \@regexp_id_list } } );
	$delete_re->delete();

	my @cfg_prefixes = ("hdr_rw_", "hdr_rw_mid_", "regex_remap_", "cacheurl_");
	foreach my $cfg_prefix (@cfg_prefixes) {
		my $cfg_file = $cfg_prefix . $ds->xml_id . ".config";
		&UI::DeliveryService::delete_cfg_file($self, $cfg_file);
	}
 
	&log( $self, "Delete deliveryservice with id: " . $id . " and name " . $dsname, " APICHANGE" );

	return $self->success_message("Delivery service was deleted.");
}

1;
