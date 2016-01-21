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
use UI::Topology;

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
	my $current_user = $self->current_user()->{username};

	my $rs;
	my $tm_user_id;
	my $forbidden;
	if ( defined($id) ) {
		( $forbidden, $rs, $tm_user_id ) = $self->get_delivery_service_by_id( $current_user, $id );
	}
	else {
		( $rs, $tm_user_id ) = $self->get_delivery_services($current_user);
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
					"id"                   => $row->id,
					"xmlId"                => $row->xml_id,
					"displayName"          => $row->display_name,
					"dscp"                 => $row->dscp,
					"signed"               => \$row->signed,
					"qstringIgnore"        => $row->qstring_ignore,
					"geoLimit"             => $row->geo_limit,
					"httpBypassFqdn"       => $row->http_bypass_fqdn,
					"dnsBypassIp"          => $row->dns_bypass_ip,
					"dnsBypassIp6"         => $row->dns_bypass_ip6,
					"dnsBypassCname"       => $row->dns_bypass_cname,
					"dnsBypassTtl"         => $row->dns_bypass_ttl,
					"orgServerFqdn"        => $row->org_server_fqdn,
					"multiSiteOrigin"      => $row->multi_site_origin,
					"ccrDnsTtl"            => $row->ccr_dns_ttl,
					"type"                 => $row->type->name,
					"profileName"          => $row->profile->name,
					"profileDescription"   => $row->profile->description,
					"cdnName"              => $cdn_name,
					"globalMaxMbps"        => $row->global_max_mbps,
					"globalMaxTps"         => $row->global_max_tps,
					"headerRewrite"        => $row->edge_header_rewrite,
					"edgeHeaderRewrite"    => $row->edge_header_rewrite,
					"midHeaderRewrite"     => $row->mid_header_rewrite,
					"trResponseHeaders"    => $row->tr_response_headers,
					"regexRemap"           => $row->regex_remap,
					"longDesc"             => $row->long_desc,
					"longDesc1"            => $row->long_desc_1,
					"longDesc2"            => $row->long_desc_2,
					"maxDnsAnswers"        => $row->max_dns_answers,
					"infoUrl"              => $row->info_url,
					"missLat"              => $row->miss_lat,
					"missLong"             => $row->miss_long,
					"checkPath"            => $row->check_path,
					"matchList"            => \@matchlist,
					"active"               => \$row->active,
					"protocol"             => $row->protocol,
					"ipv6RoutingEnabled"   => \$row->ipv6_routing_enabled,
					"rangeRequestHandling" => $row->range_request_handling,
					"cacheurl"             => $row->cacheurl,
					"remapText"            => $row->remap_text,
					"initialDispersion"    => $row->initial_dispersion,
					"exampleURLs"          => \@example_urls,
				}
			);
		}
	}

	return defined($forbidden) ? $self->forbidden() : $self->success(\@data);
}

sub get_delivery_services {
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

sub get_delivery_service_by_id {
	my $self         = shift;
	my $current_user = shift;
	my $id           = shift;

	my $tm_user_id;
	my $rs;
	my $forbidden;
	if ( &is_privileged($self) ) {
		my @ds_ids =
		$rs = $self->db->resultset('Deliveryservice')
			->search( { 'me.id' => $id }, { prefetch => [ 'cdn', 'deliveryservice_regexes' ], order_by => 'xml_id' } );
	}
	elsif ( $self->is_delivery_service_assigned($id) ) {
		my $tm_user = $self->db->resultset('TmUser')->search( { username => $current_user } )->single();
		$tm_user_id = $tm_user->id;

		my @ds_ids =
			$self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $tm_user_id, deliveryservice => $id } )->get_column('deliveryservice')->all();
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
			$self->forbidden();
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
			$self->forbidden();
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
			$self->forbidden();
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
			$self->forbidden();
		}
	}
	else {
		$self->not_found();
	}
}

sub request {
	my $self      = shift;
	my $email_to  = $self->req->json->{emailTo};
	my $details = $self->req->json->{details};

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
	my $self      = shift;
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

sub create{
    my $self = shift;
    my $params = $self->req->json;
    if (!defined($params)) {
        return $self->alert("parameters are json format, please check!");
    }
    $self->app->log->debug("create deliveryservice with: " . Dumper($params) );
    if ( !&is_oper($self) ) {
        return $self->alert("You must be an ADMIN or OPER to perform this operation!");
    }

    my $profile_id;
    my $Deliveryservices;
    my %xml_id;
    my %os_fqdn;
    my $rs = $self->db->resultset('Deliveryservice');
    while ( my $ds = $rs->next ) {
        $xml_id{ $ds->xml_id }       = $ds->id;
        $os_fqdn{ $ds->org_server_fqdn }  = $ds->id;
    }
    $Deliveryservices->{'xml_id'} = \%xml_id;
    $Deliveryservices->{'os_fqdn'} = \%os_fqdn;

    $self->app->log->debug("params = " . Dumper($params));
    #$self->app->log->debug("Deliveryservices = " . Dumper($Deliveryservices));

    if (exists $Deliveryservices->{xml_id}{$params->{xml_id}}) {
        return $self->alert("xml_id[". $params->{xml_id} . "] is already exist.");
    }
    if (exists $Deliveryservices->{'os_fqdn'}->{$params->{org_server_fqdn}}) {
        return $self->alert("org_server_fqdn[". $params->{org_server_fqdn} . "] is already used in deliveryservice [" . $Deliveryservices->{os_fqdn}->{$params->{org_server_fqdn}}."]");
    } 
    $rs = $self->get_types("deliveryservice");
    if (! exists $rs->{$params->{type}}) {
        return $self->alert("type[".$params->{type}."] must be deliveryservice type.");
    } else {
        $params->{type} = $rs->{$params->{type}};
        $self->app->log->debug("Deliveryservice type = " . $params->{type});
    }
    if (!(( $params->{protocol} eq "HTTP") || ($params->{protocol} eq "HTTPS") || ($params->{protocol} eq "HTTP+HTTPS"))) {
        return $self->alert("protocol[".$params->{protocol}."] must be HTTP|HTTPS|HTTP+HTTPS.");
    }

    my $CCR_profiles;
    my @ccrprofs = $self->db->resultset('Profile')->search( { name => { -like => 'CCR%' } } )->get_column('id')->all();
    $rs =$self->db->resultset('ProfileParameter')
            ->search( { profile => { -in => \@ccrprofs }, 'parameter.name' => 'domain_name', 'parameter.config_file' => 'CRConfig.json' },
                        { prefetch => [ 'parameter', 'profile' ] } );
    while ( my $row = $rs->next ) {
        $CCR_profiles->{$row->profile->name} = $row->profile->id;
    }
    if (!exists $CCR_profiles->{$params->{profile_name}}) {
        return $self->alert("profile [".$params->{profile_name}."] must be CCR profiles.");
    } else {
        $profile_id = $CCR_profiles->{$params->{profile_name}};
        $self->app->log->debug("Deliveryservice profile_id = " . $profile_id);
    }
    
    my $cdn_id = $self->db->resultset('Cdn')->search( { name => $params->{cdn_name} } )->get_column('id')->single();
    if (!defined $cdn_id) {
        return $self->alert("cdn_name [" . $params->{cdn_name} . "] does not exists.");
    }

    if (!exists $params->{matchlist}) {
        return $self->alert("No  matchlist found.");    
    }

    my $patterns = $params->{matchlist};
    my $patterns_len = @$patterns;
    #$self->app->log->debug("len of matchlist = " . $patterns_len);
    if ( $patterns_len == 0 ) {
        return $self->alert("At least have 1 pattern in matchlist.");
    }

    my $insert = $self->db->resultset('Deliveryservice')->create(
        {   
            xml_id       => $params->{xml_id},
            display_name => $params->{display_name},
            dscp         => $self->cdef($params->{dscp} eq "" , 0),
            signed            => $self->cdef($params->{signed}, 0),
            qstring_ignore    => $params->{qstring_ignore},
            geo_limit         => $params->{geo_limit},
            http_bypass_fqdn  => $params->{http_bypass_fqdn},
            dns_bypass_ip     => $params->{dns_bypass_ip},
            dns_bypass_ip6    => $params->{dns_bypass_ip6},
            dns_bypass_cname  => $params->{dns_bypass_cname},
            dns_bypass_ttl    => $params->{dns_bypass_ttl},
            org_server_fqdn   => $params->{org_server_fqdn},
            multi_site_origin => $params->{multi_site_origin},
            ccr_dns_ttl       => $params->{ccr_dns_ttl},
            type              => $params->{type},
            profile           => $profile_id,
            cdn_id            => $cdn_id,
            global_max_mbps   => $self->cdef($params->{global_max_mbps}, 0),
            global_max_tps => $self->cdef($params->{global_max_tps}, 0),
            miss_lat        => $params->{miss_lat},
            miss_long       => $params->{miss_long},
            long_desc       => $params->{long_desc},
            long_desc_1     => $params->{long_desc_1},
            long_desc_2     => $params->{long_desc_2},
            max_dns_answers => $self->cdef($params->{max_dns_answers},0),
            info_url   => $params->{info_url},
            check_path => $params->{check_path},
            active     => $self->cdef($params->{active}, 1),
            protocol   => $params->{protocol},
            ipv6_routing_enabled =>$params->{ipv6_routing_enabled},
            range_request_handling =>$params->{range_request_handling},
            edge_header_rewrite => $params->{edge_header_rewrite},
            mid_header_rewrite => $params->{mid_header_rewrite},
            regex_remap => $params->{regex_remap},
            origin_shield => $params->{origin_shield},
            cacheurl => $params->{cacheurl},
            remap_text => $params->{remap_text},
            initial_dispersion => $params->{initial_dispersion},
            #regional_geo_blocking =>$self->cdef($params->{regional_geo_blocking}, 0),
        }
    );
    $insert->insert();
    my $new_id = $insert->id;

    my $response;
    my $r;
    if ($new_id > 0) {
 
        $self->app->log->debug("deliveryservice created, id=". $new_id);
        my $order = 0;
        foreach my $re (@$patterns) {
            my $type = $self->db->resultset('Type')->search( { name=>$re->{type} } )->get_column('id')->single();
            my $regexp = $re->{pattern};

            my $insert = $self->db->resultset('Regex')->create(
                {
                    pattern => $regexp,
                    type    => $type,
                }
            );
            $insert->insert();
            my $new_re_id =$insert->id;

            my $de_re_insert = $self->db->resultset('DeliveryserviceRegex')->create(
                                {   regex           => $new_re_id,
                                    deliveryservice => $new_id,
                                    set_number      => $order,
                                }
                            );
            $de_re_insert->insert();
            $order++;
        }
 
        &UI::DeliveryService::header_rewrite(
                        $self,
                        $new_id,
                        $profile_id,
                        $params->{xml_id},
                        $params->{edge_header_rewrite}, "edge");
        &UI::DeliveryService::header_rewrite(
                        $self,
                        $new_id,
                        $profile_id,
                        $params->{xml_id},
                        $params->{mid_header_rewrite}, "mid");
        &UI::DeliveryService::regex_remap(
                        $self,
                        $profile_id,
                        $params->{xml_id},
                        $params->{regex_remap});
        &UI::DeliveryService::cacheurl(
                        $self,
                        $profile_id,
                        $params->{xml_id},
                        $params->{cacheurl});

        $rs = $self->db->resultset('Deliveryservice')->find( { id => $new_id } );
        if (defined($rs)) {
				$response->{id                    } = $rs->id                     ;
				$response->{xml_id                } = $rs->xml_id                 ;
				$response->{active                } = $rs->active                 ;
				$response->{dscp                  } = $rs->dscp                   ;
				$response->{signed                } = $rs->signed                 ;
				$response->{qstring_ignore        } = $rs->qstring_ignore         ;
				$response->{geo_limit             } = $rs->geo_limit              ;
				$response->{http_bypass_fqdn      } = $rs->http_bypass_fqdn       ;
				$response->{dns_bypass_ip         } = $rs->dns_bypass_ip          ;
				$response->{dns_bypass_ip6        } = $rs->dns_bypass_ip6         ;
				$response->{dns_bypass_ttl        } = $rs->dns_bypass_ttl         ;
				$response->{org_server_fqdn       } = $rs->org_server_fqdn        ;
                $response->{type                  } = $rs->type->id               ;
                $response->{profile               } = $rs->profile->id            ;
                $response->{profile_name          } = $params->{profile_name}          ;
                $response->{cdn_name              } = $params->{cdn_name}         ;
                $response->{cdn_id                } = $rs->cdn_id                 ;
				$response->{ccr_dns_ttl           } = $rs->ccr_dns_ttl            ;
				$response->{global_max_mbps       } = $rs->global_max_mbps        ;
				$response->{global_max_tps        } = $rs->global_max_tps         ;
				$response->{long_desc             } = $rs->long_desc              ;
				$response->{long_desc_1           } = $rs->long_desc_1            ;
				$response->{long_desc_2           } = $rs->long_desc_2            ;
				$response->{max_dns_answers       } = $rs->max_dns_answers        ;
				$response->{info_url              } = $rs->info_url               ;
				$response->{miss_lat              } = $rs->miss_lat               ;
				$response->{miss_long             } = $rs->miss_long              ;
				$response->{check_path            } = $rs->check_path             ;
				$response->{last_updated          } = $rs->last_updated           ;
				$response->{protocol              } = $rs->protocol               ;
				$response->{protocol_name         } = $params->{protocol}         ;
				$response->{ssl_key_version       } = $rs->ssl_key_version        ;
				$response->{ipv6_routing_enabled  } = $rs->ipv6_routing_enabled   ;
				$response->{range_request_handling} = $rs->range_request_handling ;
				$response->{edge_header_rewrite   } = $rs->edge_header_rewrite    ;
				$response->{origin_shield         } = $rs->origin_shield          ;
				$response->{mid_header_rewrite    } = $rs->mid_header_rewrite     ;
				$response->{regex_remap           } = $rs->regex_remap            ;
				$response->{cacheurl              } = $rs->cacheurl               ;
				$response->{remap_text            } = $rs->remap_text             ;
				$response->{multi_site_origin     } = $rs->multi_site_origin      ;
				$response->{display_name          } = $rs->display_name           ;
				$response->{tr_response_headers   } = $rs->tr_response_headers    ;
				$response->{initial_dispersion    } = $rs->initial_dispersion     ;
				$response->{dns_bypass_cname      } = $rs->dns_bypass_cname       ;
                #$response->{regional_geo_blocking } = $rs->regional_geo_blocking  ;
        }
            $self->app->log->debug("type = " . $rs->type->id . " profile = " . $rs->profile->id);

        my $patterns1;
        $rs = $self->db->resultset('DeliveryserviceRegex')->search( { deliveryservice => $new_id } );
        while ( my $row = $rs->next) {
            my $pat;
            $pat->{'pattern'} = $row->regex->pattern; 
            #$self->app->log->debug("pattern = " . Dumper($pat->{'pattern'}));
            $pat->{'type'} = $row->regex->type->name;
            #$self->app->log->debug("pattern_id = " . $row->regex->id . " set_number = " . $row->set_number. " type= " .$pat->{'type'});
            $patterns1->{$row->set_number} = $pat;
        }
        my @pats = ();
        foreach my $re ( sort keys %{$patterns1} ) {
            push(@pats, 
                    { 
                    'pattern' => $patterns1->{$re}->{'pattern'}, 
                    'type'    => $patterns1->{$re}->{'type'},
                    });
        }
        $response->{'matchlist'} = \@pats;
     
        #$self->app->log->debug("response = " . Dumper($response));
	    return $self->success($response);
    }

    $r = "Create Dilivery Service fail, insert to database failed.";
	return $self->alert($r);
}

sub cdef {
    my $self = shift;
    my $v = shift;
    my $default = shift;

    if (!defined($default)) {
        return $v;
    }
    if (!defined($v)) {
        return $default;
    }
    return $v;
}

sub get_types {
    my $self      = shift;
    my $use_in_table = shift;
    my $types;
    my $rs = $self->db->resultset('Type')->search( { use_in_table => $use_in_table } );
    while ( my $row = $rs->next) {
        $types->{$row->name} = $row->id;
    }
    return $types;
}

sub assign_servers{
    my $self = shift;
    my $params = $self->req->json;
    if (!defined($params)) {
        return $self->alert("parameters are json format, please check!");
    }
    $self->app->log->debug("deliveryservice assign server with: " . Dumper($params) );
    if ( !&is_oper($self) ) {
        return $self->alert("You must be an ADMIN or OPER to perform this operation!");
    }

    if (!exists($params->{xml_id})) {
        return $self->alert("Parameter 'xml_id' is required in Jason.");
    }
    if (!exists($params->{server_names})) {
        return $self->alert("Parameter 'server_names' is required Jason.");
    }
    
    my $dsid = $self->db->resultset('Deliveryservice')->search( { xml_id => $params->{xml_id} } )->get_column('id')->single();
    $self->app->log->debug("DeliveryService[" . $params->{xml_id} . "] id is [". $dsid . "]");
    if (!defined($dsid)) {
        return $self->alert("DeliveryService[" . $params->{xml_id}. "] is not found.");
    }

    my @server_ids;
    my $svrs = $params->{server_names};
    foreach my $svr (@$svrs) {
        $self->app->log->debug("Server[" . $svr . "]");
        my $svr_id = $self->db->resultset('Server')->search( { host_name => $svr } )->get_column('id')->single();
        $self->app->log->debug("Server[" . $svr . "] id is [". $svr_id . "]");
        if (!defined($svr_id)) {
            return $self->alert("Server[" . $svr. "] is not found in database.");
        }
        push(@server_ids, $svr_id);
    }

    # clean up
    my $delete = $self->db->resultset('DeliveryserviceServer')->search( { deliveryservice => $dsid } );
    $delete->delete();
    
    # assign servers
    foreach my $s_id (@server_ids) {
        my $insert = $self->db->resultset('DeliveryserviceServer')->create(
                        {   deliveryservice => $dsid,
                            server          => $s_id,
                        }   );
        $insert->insert();
    }
    
    my $ds = $self->db->resultset('Deliveryservice')->search( { id => $dsid } ) ->single();
    &UI::DeliveryService::header_rewrite( $self, $ds->id, $ds->profile, $ds->xml_id, $ds->edge_header_rewrite, "edge" );
    
    my $response;
    $response->{xml_id} = $ds->xml_id;
    $response->{'server_names'} = \@$svrs;

    return $self->success($response);
}

1;
