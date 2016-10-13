package API::Deliveryservice;
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
# a note about locations and cachegroups. This used to be "Location", before we had physical locations in 12M. Very confusing.
# What used to be called a location is now called a "cache group" and location is now a physical address, not a group of caches working together.
#

# JvD Note: you always want to put Utils as the first use. Sh*t don't work if it's after the Mojo lines.
use UI::Utils;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use JSON;
use MojoPlugins::Response;
use UI::DeliveryService;
use Validate::Tiny ':all';

sub index {
	my $self         = shift;
	my $orderby      = $self->param('orderby') || "xml_id";
	my $logs_enabled = $self->param('logsEnabled');
	my $current_user = $self->current_user()->{username};
	my @data;

	my %criteria;
	if ( defined $logs_enabled ) {
		$criteria{'logs_enabled'} = $logs_enabled ? 1 : 0;    # converts bool to 0|1
	}

	if ( !&is_privileged($self) ) {
		my $tm_user = $self->db->resultset('TmUser')->search( { username => $current_user } )->single();
		my @ds_ids = $self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $tm_user->id } )->get_column('deliveryservice')->all();
		$criteria{'me.id'} = { -in => \@ds_ids },;
	}

	my $rs_data = $self->db->resultset("Deliveryservice")->search( \%criteria, { order_by => 'me.' . $orderby } );
	while ( my $row = $rs_data->next ) {
		my $ds_regexes = $row->deliveryservice_regexes;
		my @matchlist  = ();

		while ( my $ds_regex = $ds_regexes->next ) {
			push(
				@matchlist, {
					type      => $ds_regex->regex->type->name,
					pattern   => $ds_regex->regex->pattern,
					setNumber => $ds_regex->set_number
				}
			);
		}

		my $cdn_domain   = $self->get_cdn_domain_by_ds_id( $row->id );
		my $regexp_set   = &UI::DeliveryService::get_regexp_set( $self, $row->id );
		my @example_urls = &UI::DeliveryService::get_example_urls( $self, $row->id, $regexp_set, $row, $cdn_domain, $row->protocol );

		push(
			@data, {
				"active"                   => \$row->active,
				"cacheurl"                 => $row->cacheurl,
				"ccrDnsTtl"                => $row->ccr_dns_ttl,
				"cdnId"                    => $row->cdn->id,
				"cdnName"                  => $row->cdn->name,
				"checkPath"                => $row->check_path,
				"displayName"              => $row->display_name,
				"dnsBypassCname"           => $row->dns_bypass_cname,
				"dnsBypassIp"              => $row->dns_bypass_ip,
				"dnsBypassIp6"             => $row->dns_bypass_ip6,
				"dnsBypassTtl"             => $row->dns_bypass_ttl,
				"dscp"                     => $row->dscp,
				"edgeHeaderRewrite"        => $row->edge_header_rewrite,
				"exampleURLs"              => \@example_urls,
				"geoLimitRedirectURL"      => $row->geolimit_redirect_url,
				"geoLimit"                 => $row->geo_limit,
				"geoLimitCountries"        => $row->geo_limit_countries,
				"geoProvider"              => $row->geo_provider,
				"globalMaxMbps"            => $row->global_max_mbps,
				"globalMaxTps"             => $row->global_max_tps,
				"httpBypassFqdn"           => $row->http_bypass_fqdn,
				"id"                       => $row->id,
				"infoUrl"                  => $row->info_url,
				"initialDispersion"        => $row->initial_dispersion,
				"ipv6RoutingEnabled"       => \$row->ipv6_routing_enabled,
				"lastUpdated"              => $row->last_updated,
				"logsEnabled"              => \$row->logs_enabled,
				"longDesc"                 => $row->long_desc,
				"longDesc1"                => $row->long_desc_1,
				"longDesc2"                => $row->long_desc_2,
				"matchList"                => \@matchlist,
				"maxDnsAnswers"            => $row->max_dns_answers,
				"midHeaderRewrite"         => $row->mid_header_rewrite,
				"missLat"                  => $row->miss_lat,
				"missLong"                 => $row->miss_long,
				"multiSiteOrigin"          => \$row->multi_site_origin,
				"multiSiteOriginAlgorithm" => $row->multi_site_origin_algorithm,
				"orgServerFqdn"            => $row->org_server_fqdn,
				"originShield"             => $row->origin_shield,
				"profileId"                => $row->profile->id,
				"profileName"              => $row->profile->name,
				"profileDescription"       => $row->profile->description,
				"protocol"                 => $row->protocol,
				"qstringIgnore"            => $row->qstring_ignore,
				"rangeRequestHandling"     => $row->range_request_handling,
				"regexRemap"               => $row->regex_remap,
				"regionalGeoBlocking"      => \$row->regional_geo_blocking,
				"remapText"                => $row->remap_text,
				"signed"                   => \$row->signed,
				"sslKeyVersion"            => $row->ssl_key_version,
				"trRequestHeaders"         => $row->tr_request_headers,
				"trResponseHeaders"        => $row->tr_response_headers,
				"type"                     => $row->type->name,
				"typeId"                   => $row->type->id,
				"xmlId"                    => $row->xml_id
			}
		);
	}
	$self->success( \@data );
}

sub show {
	my $self         = shift;
	my $id           = $self->param('id');
	my $current_user = $self->current_user()->{username};
	my @data;

	if ( !&is_privileged($self) ) {

		# check to see if deliveryservice is assigned to user, if not return forbidden
		my $tm_user = $self->db->resultset('TmUser')->search( { username => $current_user } )->single();
		my @ds_ids = $self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $tm_user->id } )->get_column('deliveryservice')->all();
		my %map = map { $_ => 1 } @ds_ids;    # turn the array of dsIds into a hash with dsIds as the keys
		return $self->forbidden() if ( !exists( $map{$id} ) );
	}

	my $rs = $self->db->resultset("Deliveryservice")->search( { id => $id } );
	while ( my $row = $rs->next ) {
		my $ds_regexes = $row->deliveryservice_regexes;
		my @matchlist  = ();

		while ( my $ds_regex = $ds_regexes->next ) {
			push(
				@matchlist, {
					type      => $ds_regex->regex->type->name,
					pattern   => $ds_regex->regex->pattern,
					setNumber => $ds_regex->set_number
				}
			);
		}

		my $cdn_domain   = $self->get_cdn_domain_by_ds_id( $row->id );
		my $regexp_set   = &UI::DeliveryService::get_regexp_set( $self, $row->id );
		my @example_urls = &UI::DeliveryService::get_example_urls( $self, $row->id, $regexp_set, $row, $cdn_domain, $row->protocol );

		push(
			@data, {
				"active"                   => \$row->active,
				"cacheurl"                 => $row->cacheurl,
				"ccrDnsTtl"                => $row->ccr_dns_ttl,
				"cdnId"                    => $row->cdn->id,
				"cdnName"                  => $row->cdn->name,
				"checkPath"                => $row->check_path,
				"displayName"              => $row->display_name,
				"dnsBypassCname"           => $row->dns_bypass_cname,
				"dnsBypassIp"              => $row->dns_bypass_ip,
				"dnsBypassIp6"             => $row->dns_bypass_ip6,
				"dnsBypassTtl"             => $row->dns_bypass_ttl,
				"dscp"                     => $row->dscp,
				"edgeHeaderRewrite"        => $row->edge_header_rewrite,
				"exampleURLs"              => \@example_urls,
				"geoLimitRedirectURL"      => $row->geolimit_redirect_url,
				"geoLimit"                 => $row->geo_limit,
				"geoLimitCountries"        => $row->geo_limit_countries,
				"geoProvider"              => $row->geo_provider,
				"globalMaxMbps"            => $row->global_max_mbps,
				"globalMaxTps"             => $row->global_max_tps,
				"httpBypassFqdn"           => $row->http_bypass_fqdn,
				"id"                       => $row->id,
				"infoUrl"                  => $row->info_url,
				"initialDispersion"        => $row->initial_dispersion,
				"ipv6RoutingEnabled"       => \$row->ipv6_routing_enabled,
				"lastUpdated"              => $row->last_updated,
				"logsEnabled"              => \$row->logs_enabled,
				"longDesc"                 => $row->long_desc,
				"longDesc1"                => $row->long_desc_1,
				"longDesc2"                => $row->long_desc_2,
				"matchList"                => \@matchlist,
				"maxDnsAnswers"            => $row->max_dns_answers,
				"midHeaderRewrite"         => $row->mid_header_rewrite,
				"missLat"                  => $row->miss_lat,
				"missLong"                 => $row->miss_long,
				"multiSiteOrigin"          => \$row->multi_site_origin,
				"multiSiteOriginAlgorithm" => $row->multi_site_origin_algorithm,
				"orgServerFqdn"            => $row->org_server_fqdn,
				"originShield"             => $row->origin_shield,
				"profileId"                => $row->profile->id,
				"profileName"              => $row->profile->name,
				"profileDescription"       => $row->profile->description,
				"protocol"                 => $row->protocol,
				"qstringIgnore"            => $row->qstring_ignore,
				"rangeRequestHandling"     => $row->range_request_handling,
				"regexRemap"               => $row->regex_remap,
				"regionalGeoBlocking"      => \$row->regional_geo_blocking,
				"remapText"                => $row->remap_text,
				"signed"                   => \$row->signed,
				"sslKeyVersion"            => $row->ssl_key_version,
				"trRequestHeaders"         => $row->tr_request_headers,
				"trResponseHeaders"        => $row->tr_response_headers,
				"type"                     => $row->type->name,
				"typeId"                   => $row->type->id,
				"xmlId"                    => $row->xml_id
			}
		);
	}
	$self->success( \@data );
}

sub update {
	my $self   = shift;
	my $id     = $self->param('id');
	my $params = $self->req->json;

	if ( !&is_oper($self) ) {
		return $self->forbidden();
	}

	my ( $is_valid, $result ) = $self->is_deliveryservice_valid($params);

	if ( !$is_valid ) {
		return $self->alert($result);
	}

	my $ds = $self->db->resultset('Deliveryservice')->find( { id => $id } );
	if ( !defined($ds) ) {
		return $self->not_found();
	}

	my $xml_id = $params->{xmlId};
	if ( $ds->xml_id ne $xml_id ) {
		my $existing = $self->db->resultset('Deliveryservice')->find( { xml_id => $xml_id } );
		if ($existing) {
			return $self->alert( "A deliveryservice with xmlId " . $xml_id . " already exists." );
		}
	}

	my $values = {
		active => $params->{active} ? 1 : 0,
		cacheurl                    => $params->{cacheurl},
		ccr_dns_ttl                 => $params->{ccrDnsTtl},
		cdn_id                      => $params->{cdnId},
		check_path                  => $params->{checkPath},
		display_name                => $params->{displayName},
		dns_bypass_cname            => $params->{dnsBypassCname},
		dns_bypass_ip               => $params->{dnsBypassIp},
		dns_bypass_ip6              => $params->{dnsBypassIp6},
		dns_bypass_ttl              => $params->{dnsBypassTtl},
		dscp                        => $params->{dscp},
		edge_header_rewrite         => $params->{edgeHeaderRewrite},
		geolimit_redirect_url       => $params->{geoLimitRedirectURL},
		geo_limit                   => $params->{geoLimit},
		geo_limit_countries         => $params->{geoLimitCountries},
		geo_provider                => $params->{geoProvider},
		global_max_mbps             => $params->{globalMaxMbps},
		global_max_tps              => $params->{globalMaxTps},
		http_bypass_fqdn            => $params->{httpBypassFqdn},
		info_url                    => $params->{infoUrl},
		initial_dispersion          => $params->{initialDispersion},
		ipv6_routing_enabled        => $params->{ipv6RoutingEnabled} ? 1 : 0,
		logs_enabled                => $params->{logsEnabled} ? 1 : 0,
		long_desc                   => $params->{longDesc},
		long_desc_1                 => $params->{longDesc1},
		long_desc_2                 => $params->{longDesc2},
		max_dns_answers             => $params->{maxDnsAnswers},
		mid_header_rewrite          => $params->{midHeaderRewrite},
		miss_lat                    => $params->{missLat},
		miss_long                   => $params->{missLong},
		multi_site_origin           => $params->{multiSiteOrigin} ? 1 : 0,
		multi_site_origin_algorithm => $params->{multiSiteOriginAlgorithm},
		org_server_fqdn             => $params->{orgServerFqdn},
		origin_shield               => $params->{originShield},
		profile                     => $params->{profileId},
		protocol                    => $params->{protocol},
		qstring_ignore              => $params->{qstringIgnore},
		range_request_handling      => $params->{rangeRequestHandling},
		regex_remap                 => $params->{regexRemap},
		regional_geo_blocking       => $params->{regionalGeoBlocking} ? 1 : 0,
		remap_text                  => $params->{remapText},
		signed                      => $params->{signed} ? 1 : 0,
		ssl_key_version             => $params->{sslKeyVersion},
		tr_request_headers          => $params->{trRequestHeaders},
		tr_response_headers         => $params->{trResponseHeaders},
		type                        => $params->{typeId},
		xml_id                      => $params->{xmlId}
	};

	my $rs = $ds->update($values);
	if ($rs) {
		my @response;
		push(
			@response, {
				"active"                   => \$rs->active,
				"cacheurl"                 => $rs->cacheurl,
				"ccrDnsTtl"                => $rs->ccr_dns_ttl,
				"cdnId"                    => $rs->cdn->id,
				"cdnName"                  => $rs->cdn->name,
				"checkPath"                => $rs->check_path,
				"displayName"              => $rs->display_name,
				"dnsBypassCname"           => $rs->dns_bypass_cname,
				"dnsBypassIp"              => $rs->dns_bypass_ip,
				"dnsBypassIp6"             => $rs->dns_bypass_ip6,
				"dnsBypassTtl"             => $rs->dns_bypass_ttl,
				"dscp"                     => $rs->dscp,
				"edgeHeaderRewrite"        => $rs->edge_header_rewrite,
				"geoLimitRedirectURL"      => $rs->geolimit_redirect_url,
				"geoLimit"                 => $rs->geo_limit,
				"geoLimitCountries"        => $rs->geo_limit_countries,
				"geoProvider"              => $rs->geo_provider,
				"globalMaxMbps"            => $rs->global_max_mbps,
				"globalMaxTps"             => $rs->global_max_tps,
				"httpBypassFqdn"           => $rs->http_bypass_fqdn,
				"id"                       => $rs->id,
				"infoUrl"                  => $rs->info_url,
				"initialDispersion"        => $rs->initial_dispersion,
				"ipv6RoutingEnabled"       => \$rs->ipv6_routing_enabled,
				"lastUpdated"              => $rs->last_updated,
				"logsEnabled"              => \$rs->logs_enabled,
				"longDesc"                 => $rs->long_desc,
				"longDesc1"                => $rs->long_desc_1,
				"longDesc2"                => $rs->long_desc_2,
				"maxDnsAnswers"            => $rs->max_dns_answers,
				"midHeaderRewrite"         => $rs->mid_header_rewrite,
				"missLat"                  => $rs->miss_lat,
				"missLong"                 => $rs->miss_long,
				"multiSiteOrigin"          => \$rs->multi_site_origin,
				"multiSiteOriginAlgorithm" => $rs->multi_site_origin_algorithm,
				"orgServerFqdn"            => $rs->org_server_fqdn,
				"originShield"             => $rs->origin_shield,
				"profileId"                => $rs->profile->id,
				"profileName"              => $rs->profile->name,
				"profileDescription"       => $rs->profile->description,
				"protocol"                 => $rs->protocol,
				"qstringIgnore"            => $rs->qstring_ignore,
				"rangeRequestHandling"     => $rs->range_request_handling,
				"regexRemap"               => $rs->regex_remap,
				"regionalGeoBlocking"      => \$rs->regional_geo_blocking,
				"remapText"                => $rs->remap_text,
				"signed"                   => \$rs->signed,
				"sslKeyVersion"            => $rs->ssl_key_version,
				"trRequestHeaders"         => $rs->tr_request_headers,
				"trResponseHeaders"        => $rs->tr_response_headers,
				"type"                     => $rs->type->name,
				"typeId"                   => $rs->type->id,
				"xmlId"                    => $rs->xml_id
			}
		);

		&log( $self, "Updated deliveryservice [ '" . $rs->xml_id . "' ] with id: " . $rs->id, "APICHANGE" );

		return $self->success( \@response, "Deliveryservice update was successful." );
	}
	else {
		return $self->alert("Deliveryservice update failed.");
	}
}

sub create {
	my $self   = shift;
	my $params = $self->req->json;

	if ( !&is_oper($self) ) {
		return $self->forbidden();
	}

	my ( $is_valid, $result ) = $self->is_deliveryservice_valid($params);

	if ( !$is_valid ) {
		return $self->alert($result);
	}

	my $xml_id = $params->{xmlId};
	my $existing = $self->db->resultset('Deliveryservice')->find( { xml_id => $xml_id } );
	if ($existing) {
		return $self->alert( "A deliveryservice with xmlId " . $xml_id . " already exists." );
	}

	my $values = {
		active => $params->{active} ? 1 : 0,
		cacheurl                    => $params->{cacheurl},
		ccr_dns_ttl                 => $params->{ccrDnsTtl},
		cdn_id                      => $params->{cdnId},
		check_path                  => $params->{checkPath},
		display_name                => $params->{displayName},
		dns_bypass_cname            => $params->{dnsBypassCname},
		dns_bypass_ip               => $params->{dnsBypassIp},
		dns_bypass_ip6              => $params->{dnsBypassIp6},
		dns_bypass_ttl              => $params->{dnsBypassTtl},
		dscp                        => $params->{dscp},
		edge_header_rewrite         => $params->{edgeHeaderRewrite},
		geolimit_redirect_url       => $params->{geoLimitRedirectURL},
		geo_limit                   => $params->{geoLimit},
		geo_limit_countries         => $params->{geoLimitCountries},
		geo_provider                => $params->{geoProvider},
		global_max_mbps             => $params->{globalMaxMbps},
		global_max_tps              => $params->{globalMaxTps},
		http_bypass_fqdn            => $params->{httpBypassFqdn},
		info_url                    => $params->{infoUrl},
		initial_dispersion          => $params->{initialDispersion},
		ipv6_routing_enabled        => $params->{ipv6RoutingEnabled} ? 1 : 0,
		logs_enabled                => $params->{logsEnabled} ? 1 : 0,
		long_desc                   => $params->{longDesc},
		long_desc_1                 => $params->{longDesc1},
		long_desc_2                 => $params->{longDesc2},
		max_dns_answers             => $params->{maxDnsAnswers},
		mid_header_rewrite          => $params->{midHeaderRewrite},
		miss_lat                    => $params->{missLat},
		miss_long                   => $params->{missLong},
		multi_site_origin           => $params->{multiSiteOrigin} ? 1 : 0,
		multi_site_origin_algorithm => $params->{multiSiteOriginAlgorithm},
		org_server_fqdn             => $params->{orgServerFqdn},
		origin_shield               => $params->{originShield},
		profile                     => $params->{profileId},
		protocol                    => $params->{protocol},
		qstring_ignore              => $params->{qstringIgnore},
		range_request_handling      => $params->{rangeRequestHandling},
		regex_remap                 => $params->{regexRemap},
		regional_geo_blocking       => $params->{regionalGeoBlocking} ? 1 : 0,
		remap_text                  => $params->{remapText},
		signed                      => $params->{signed} ? 1 : 0,
		ssl_key_version             => $params->{sslKeyVersion},
		tr_request_headers          => $params->{trRequestHeaders},
		tr_response_headers         => $params->{trResponseHeaders},
		type                        => $params->{typeId},
		xml_id                      => $params->{xmlId}
	};

	my $insert = $self->db->resultset('Deliveryservice')->create($values);
	my $rs     = $insert->insert();
	if ($rs) {
		my @response;
		push(
			@response, {
				"active"                   => \$rs->active,
				"cacheurl"                 => $rs->cacheurl,
				"ccrDnsTtl"                => $rs->ccr_dns_ttl,
				"cdnId"                    => $rs->cdn->id,
				"cdnName"                  => $rs->cdn->name,
				"checkPath"                => $rs->check_path,
				"displayName"              => $rs->display_name,
				"dnsBypassCname"           => $rs->dns_bypass_cname,
				"dnsBypassIp"              => $rs->dns_bypass_ip,
				"dnsBypassIp6"             => $rs->dns_bypass_ip6,
				"dnsBypassTtl"             => $rs->dns_bypass_ttl,
				"dscp"                     => $rs->dscp,
				"edgeHeaderRewrite"        => $rs->edge_header_rewrite,
				"geoLimitRedirectURL"      => $rs->geolimit_redirect_url,
				"geoLimit"                 => $rs->geo_limit,
				"geoLimitCountries"        => $rs->geo_limit_countries,
				"geoProvider"              => $rs->geo_provider,
				"globalMaxMbps"            => $rs->global_max_mbps,
				"globalMaxTps"             => $rs->global_max_tps,
				"httpBypassFqdn"           => $rs->http_bypass_fqdn,
				"id"                       => $rs->id,
				"infoUrl"                  => $rs->info_url,
				"initialDispersion"        => $rs->initial_dispersion,
				"ipv6RoutingEnabled"       => \$rs->ipv6_routing_enabled,
				"lastUpdated"              => $rs->last_updated,
				"logsEnabled"              => \$rs->logs_enabled,
				"longDesc"                 => $rs->long_desc,
				"longDesc1"                => $rs->long_desc_1,
				"longDesc2"                => $rs->long_desc_2,
				"maxDnsAnswers"            => $rs->max_dns_answers,
				"midHeaderRewrite"         => $rs->mid_header_rewrite,
				"missLat"                  => $rs->miss_lat,
				"missLong"                 => $rs->miss_long,
				"multiSiteOrigin"          => \$rs->multi_site_origin,
				"multiSiteOriginAlgorithm" => $rs->multi_site_origin_algorithm,
				"orgServerFqdn"            => $rs->org_server_fqdn,
				"originShield"             => $rs->origin_shield,
				"profileId"                => $rs->profile->id,
				"profileName"              => $rs->profile->name,
				"profileDescription"       => $rs->profile->description,
				"protocol"                 => $rs->protocol,
				"qstringIgnore"            => $rs->qstring_ignore,
				"rangeRequestHandling"     => $rs->range_request_handling,
				"regexRemap"               => $rs->regex_remap,
				"regionalGeoBlocking"      => \$rs->regional_geo_blocking,
				"remapText"                => $rs->remap_text,
				"signed"                   => \$rs->signed,
				"sslKeyVersion"            => $rs->ssl_key_version,
				"trRequestHeaders"         => $rs->tr_request_headers,
				"trResponseHeaders"        => $rs->tr_response_headers,
				"type"                     => $rs->type->name,
				"typeId"                   => $rs->type->id,
				"xmlId"                    => $rs->xml_id
			}
		);

		&log( $self, "Created deliveryservice [ '" . $rs->xml_id . "' ] with id: " . $rs->id, "APICHANGE" );

		return $self->success( \@response, "Deliveryservice creation was successful." );
	}
	else {
		return $self->alert("Deliveryservice creation failed.");
	}
}

sub delete {
	my $self = shift;
	my $id   = $self->param('id');

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

	my @cfg_prefixes = ( "hdr_rw_", "hdr_rw_mid_", "regex_remap_", "cacheurl_" );
	foreach my $cfg_prefix (@cfg_prefixes) {
		my $cfg_file = $cfg_prefix . $ds->xml_id . ".config";
		&UI::DeliveryService::delete_cfg_file( $self, $cfg_file );
	}

	&log( $self, "Delete deliveryservice with id: " . $id . " and name " . $dsname, " APICHANGE" );

	return $self->success_message("Delivery service was deleted.");
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

sub is_deliveryservice_valid {
	my $self   = shift;
	my $params = shift;

	if ( !$self->is_valid_deliveryservice_type( $params->{typeId} ) ) {
		return ( 0, "Invalid deliveryservice type" );
	}

	my $rules = {
		fields => [
			qw/active cacheurl ccrDnsTtl cdnId checkPath displayName dnsBypassCname dnsBypassIp dnsBypassIp6 dnsBypassTtl dscp edgeHeaderRewrite geoLimitRedirectURL geoLimit geoLimitCountries geoProvider globalMaxMbps globalMaxTps httpBypassFqdn infoUrl initialDispersion ipv6RoutingEnabled logsEnabled longDesc longDesc1 longDesc2 maxDnsAnswers midHeaderRewrite missLat missLong multiSiteOrigin multiSiteOriginAlgorithm orgServerFqdn originShield profileId protocol qstringIgnore rangeRequestHandling regexRemap regionalGeoBlocking remapText signed sslKeyVersion trRequestHeaders trResponseHeaders typeId xmlId/
		],

		# Validation checks to perform
		checks => [
			active               => [ is_required("is required") ],
			cdnId                => [ is_required("is required") ],
			displayName          => [ is_required("is required"), is_long_at_most( 48, 'too long' ) ],
			dscp                 => [ is_required("is required") ],
			geoLimit             => [ is_required("is required") ],
			geoProvider          => [ is_required("is required") ],
			initialDispersion    => [ is_required("is required") ],
			ipv6RoutingEnabled   => [ is_required("is required") ],
			logsEnabled          => [ is_required("is required") ],
			missLat              => [ \&is_valid_lat ],
			missLong             => [ \&is_valid_long ],
			multiSiteOrigin      => [ is_required("is required") ],
			orgServerFqdn        => [ is_required("is required"), is_like( qr/^(https?:\/\/)/, "must start with http:// or https://" ) ],
			profileId            => [ is_required("is required") ],
			protocol             => [ is_required("is required") ],
			qstringIgnore        => [ is_required("is required") ],
			rangeRequestHandling => [ is_required("is required") ],
			regionalGeoBlocking  => [ is_required("is required") ],
			signed               => [ is_required("is required") ],
			typeId               => [ is_required("is required") ],
			xmlId                => [ is_required("is required"), is_like( qr/^\S*$/, "no spaces" ), is_long_at_most( 48, 'too long' ) ],
		]
	};

	# Validate the input against the rules
	my $result = validate( $params, $rules );

	if ( $result->{success} ) {
		return ( 1, $result->{data} );
	}
	else {
		return ( 0, $result->{error} );
	}
}

sub is_valid_deliveryservice_type {
	my $self    = shift;
	my $type_id = shift;

	my $rs = $self->db->resultset("Type")->find( { id => $type_id } );
	if ( defined($rs) && ( $rs->use_in_table eq "deliveryservice" ) ) {
		return 1;
	}
	return 0;
}

sub is_valid_lat {
	my ( $value, $params ) = @_;

	if ( !defined $value or $value eq '' ) {
		return undef;
	}

	if ( !( $value =~ /^[-]*[0-9]+[.]*[0-9]*/ ) ) {
		return "invalid. Must be a float number.";
	}

	if ( abs $value > 90 ) {
		return "invalid. May not exceed +- 90.0.";
	}

	return undef;
}

sub is_valid_long {
	my ( $value, $params ) = @_;

	if ( !defined $value or $value eq '' ) {
		return undef;
	}

	if ( !( $value =~ /^[-]*[0-9]+[.]*[0-9]*/ ) ) {
		return "invalid. Must be a float number.";
	}

	if ( abs $value > 180 ) {
		return "invalid. May not exceed +- 180.0.";
	}

	return undef;
}

1;
