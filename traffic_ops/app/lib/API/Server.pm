package API::Server;
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
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use POSIX qw(strftime);
use Time::Local;
use LWP;
use UI::ConfigFiles;
use UI::Tools;
use MojoPlugins::Response;
use MojoPlugins::Job;
use Utils::Helper::ResponseHelper;
use String::CamelCase qw(decamelize);

sub index {
	my $self         = shift;
	my $current_user = $self->current_user()->{username};
	my $ds_id        = $self->param('dsId');
	my $type         = $self->param('type');

	my $servers;
	my $forbidden;
	if ( defined $ds_id ) {
		( $forbidden, $servers ) = $self->get_servers_by_dsid( $current_user, $ds_id );
	}
	elsif ( defined $type ) {
		$servers = $self->get_servers_by_type( $current_user, $type );
	}
	else {
		$servers = $self->get_servers($current_user);
	}

	my @data;
	if ( defined($servers) ) {
		while ( my $row = $servers->next ) {
			my $cdn_name = defined( $row->cdn_id ) ? $row->cdn->name : "";

			push(
				@data, {
					"id"             => $row->id,
					"hostName"       => $row->host_name,
					"domainName"     => $row->domain_name,
					"tcpPort"        => $row->tcp_port,
					"interfaceName"  => $row->interface_name,
					"ipAddress"      => $row->ip_address,
					"ipNetmask"      => $row->ip_netmask,
					"ipGateway"      => $row->ip_gateway,
					"ip6Address"     => $row->ip6_address,
					"ip6Gateway"     => $row->ip6_gateway,
					"interfaceMtu"   => $row->interface_mtu,
					"cachegroup"     => $row->cachegroup->name,
					"physLocation"   => $row->phys_location->name,
					"rack"           => $row->rack,
					"type"           => $row->type->name,
					"status"         => $row->status->name,
					"profile"        => $row->profile->name,
					"cdnName"        => $cdn_name,
					"mgmtIpAddress"  => $row->mgmt_ip_address,
					"mgmtIpNetmask"  => $row->mgmt_ip_netmask,
					"mgmtIpGateway"  => $row->mgmt_ip_gateway,
					"iloIpAddress"   => $row->ilo_ip_address,
					"iloIpNetmask"   => $row->ilo_ip_netmask,
					"iloIpGateway"   => $row->ilo_ip_gateway,
					"iloUsername"    => $row->ilo_username,
					"iloPassword"    => &is_admin($self) ? $row->ilo_password : "********",
					"routerHostName" => $row->router_host_name,
					"routerPortName" => $row->router_port_name,
					"lastUpdated"    => $row->last_updated,

				}
			);
		}
	}

	return defined($forbidden) ? $self->forbidden() : $self->success(\@data);
}

sub get_servers {
	my $self              = shift;
	my $current_user      = shift;
	my $orderby           = $self->param('orderby') || "hostName";
	my $orderby_snakecase = lcfirst( decamelize($orderby) );

	my $servers;
	if ( &is_privileged($self) ) {
		$servers = $self->db->resultset('Server')->search(
			undef, {
				prefetch => [ 'cdn', 'cachegroup', 'type', 'profile', 'status', 'phys_location' ],
				order_by => 'me.' . $orderby_snakecase,
			}
		);
	}
	else {
		my $tm_user = $self->db->resultset('TmUser')->search( { username => $current_user } )->single();
		my @ds_ids = $self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $tm_user->id } )->get_column('deliveryservice')->all();

		my @ds_servers =
			$self->db->resultset('DeliveryserviceServer')->search( { deliveryservice => { -in => \@ds_ids } } )->get_column('server')->all();

		$servers = $self->db->resultset('Server')->search(
			{ 'me.id' => { -in => \@ds_servers } },
			{
				prefetch => [ 'cdn', 'cachegroup', 'type', 'profile', 'status', 'phys_location' ],
				order_by => 'me.' . $orderby_snakecase,
			}
		);
	}

	return $servers;
}

sub get_servers_by_dsid {
	my $self              = shift;
	my $current_user      = shift;
	my $dsId              = shift;
	my $orderby           = $self->param('orderby') || "hostName";
	my $orderby_snakecase = lcfirst( decamelize($orderby) );
	my $helper            = new Utils::Helper( { mojo => $self } );

	my @ds_servers;
	my $forbidden;
	if ( &is_privileged($self) ) {
		@ds_servers = $self->db->resultset('DeliveryserviceServer')->search( { deliveryservice => $dsId } )->get_column('server')->all();
	}
	elsif ( $self->is_delivery_service_assigned($dsId) ) {
		my $tm_user = $self->db->resultset('TmUser')->search( { username => $current_user } )->single();
		my $ds_id =
			$self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $tm_user->id, deliveryservice => $dsId } )
			->get_column('deliveryservice')->single();

		@ds_servers = $self->db->resultset('DeliveryserviceServer')->search( { deliveryservice => $ds_id } )->get_column('server')->all();
	}
	elsif ( !$self->is_delivery_service_assigned($dsId) ) {
		$forbidden = "true";
	}

	my $servers;
	if ( scalar(@ds_servers) ) {
		my $ds = $self->db->resultset('Deliveryservice')->search( { 'me.id' => $dsId }, { prefetch => ['type'] } )->single();
		my @criteria = [ { 'me.id' => { -in => \@ds_servers } } ];

		my @types_no_mid = qw( HTTP_NO_CACHE HTTP_LIVE DNS_LIVE );    # currently these are the ds types that bypass the mids
		if ( !grep { $_ eq $ds->type->name } @types_no_mid ) {
			push( @criteria, { 'type.name' => "MID", 'me.cdn_id' => $ds->cdn_id } );
		}

		$servers = $self->db->resultset('Server')->search(
			[@criteria], {
				prefetch => [ 'cdn', 'cachegroup', 'type', 'profile', 'status', 'phys_location' ],
				order_by => 'me.' . $orderby_snakecase,
			}
		);
	}

	return ( $forbidden, $servers );
}

sub get_servers_by_type {
	my $self              = shift;
	my $current_user      = shift;
	my $type              = shift;
	my $orderby           = $self->param('orderby') || "hostName";
	my $orderby_snakecase = lcfirst( decamelize($orderby) );

	my $servers;
	if ( &is_privileged($self) ) {
		$servers = $self->db->resultset('Server')->search(
			{ 'type.name' => $type },
			{
				prefetch => [ 'cdn', 'cachegroup', 'type', 'profile', 'status', 'phys_location' ],
				order_by => 'me.' . $orderby_snakecase,
			}
		);
	}
	else {
		my $tm_user = $self->db->resultset('TmUser')->search( { username => $current_user } )->single();
		my @ds_ids = $self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $tm_user->id } )->get_column('deliveryservice')->all();

		my @ds_servers =
			$self->db->resultset('DeliveryserviceServer')->search( { deliveryservice => { -in => \@ds_ids } } )->get_column('server')->all();

		$servers = $self->db->resultset('Server')->search(
			{ 'me.id' => { -in => \@ds_servers }, 'type.name' => $type },
			{
				prefetch => [ 'cdn', 'cachegroup', 'type', 'profile', 'status', 'phys_location' ],
				order_by => 'me.' . $orderby_snakecase,
			}
		);
	}

	return $servers;
}

sub totals {
	my $self = shift;

	my @data;
	my @rs = $self->db->resultset('ServerTypes')->search();
	foreach my $rs (@rs) {
		my $type_name = $rs->name;
		my $count     = $self->get_count_by_type($type_name);
		push(
			@data, {
				"type"  => $rs->name,
				"count" => $count,
			}
		);
	}

	return $self->success( \@data );

}

sub get_count_by_type {
	my $self      = shift;
	my $type_name = shift;
	return $self->db->resultset('Server')->search( { 'type.name' => $type_name }, { join => 'type' } )->count();
}

sub details_v11 {
	my $self = shift;
	my @data;
	my $isadmin   = &is_admin($self);
	my $host_name = $self->param('name');
	my $rs_data   = $self->db->resultset('Server')->search( { host_name => $host_name },
		{ prefetch => [ 'cachegroup', 'type', 'profile', 'status', 'phys_location', 'hwinfos', 'deliveryservice_servers' ], } );
	while ( my $row = $rs_data->next ) {

		my $serv = {
			"id"             => $row->id,
			"hostName"       => $row->host_name,
			"domainName"     => $row->domain_name,
			"tcpPort"        => $row->tcp_port,
			"xmppId"         => $row->xmpp_id,
			"xmppPasswd"     => $isadmin ? $row->xmpp_passwd : "********",
			"interfaceName"  => $row->interface_name,
			"ipAddress"      => $row->ip_address,
			"ipNetmask"      => $row->ip_netmask,
			"ipGateway"      => $row->ip_gateway,
			"ip6Address"     => $row->ip6_address,
			"ip6Gateway"     => $row->ip6_gateway,
			"interfaceMtu"   => $row->interface_mtu,
			"cachegroup"     => $row->cachegroup->name,
			"physLocation"   => $row->phys_location->name,
			"rack"           => $row->rack,
			"type"           => $row->type->name,
			"status"         => $row->status->name,
			"profile"        => $row->profile->name,
			"mgmtIpAddress"  => $row->mgmt_ip_address,
			"mgmtIpNetmask"  => $row->mgmt_ip_netmask,
			"mgmtIpGateway"  => $row->mgmt_ip_gateway,
			"iloIpAddress"   => $row->ilo_ip_address,
			"iloIpNetmask"   => $row->ilo_ip_netmask,
			"iloIpGateway"   => $row->ilo_ip_gateway,
			"iloUsername"    => $row->ilo_username,
			"iloPassword"    => $isadmin ? $row->ilo_password : "********",
			"routerHostName" => $row->router_host_name,
			"routerPortName" => $row->router_port_name,
		};
		my $hw_rs = $row->hwinfos;
		while ( my $hwinfo_row = $hw_rs->next ) {
			$serv->{hardwareInfo}->{ $hwinfo_row->description } = $hwinfo_row->val;
		}

		my $rs_ds_data = $row->deliveryservice_servers;
		while ( my $dsrow = $rs_ds_data->next ) {
			push( @{ $serv->{deliveryservices} }, $dsrow->deliveryservice->id );
		}

		push( @data, $serv );
	}
	$self->success(@data);
}

sub details {
	my $self              = shift;
	my $orderby           = $self->param('orderby') || "hostName";
	my $orderby_snakecase = lcfirst( decamelize($orderby) );
	my $limit             = $self->param('limit') || 1000;
	my @data;
	my $isadmin          = &is_admin($self);
	my $phys_location_id = $self->param('physLocationID');
	my $host_name        = $self->param('hostName');

	if ( !defined($phys_location_id) && !defined($host_name) ) {
		return $self->alert("Missing required fields: 'hostName' or 'physLocationID'");
	}

	my $rs_data = $self->db->resultset('Server')->search(
		[ { host_name => $host_name }, { phys_location => $phys_location_id } ], {
			prefetch => [ 'cachegroup', 'type', 'profile', 'status', 'phys_location', 'hwinfos', 'deliveryservice_servers' ],
			order_by => 'me.' . $orderby_snakecase
		}
	);

	if ( $rs_data->count() > 0 ) {

		while ( my $row = $rs_data->next ) {

			my $serv = {
				"id"             => $row->id,
				"hostName"       => $row->host_name,
				"domainName"     => $row->domain_name,
				"tcpPort"        => $row->tcp_port,
				"xmppId"         => $row->xmpp_id,
				"xmppPasswd"     => $isadmin ? $row->xmpp_passwd : "********",
				"interfaceName"  => $row->interface_name,
				"ipAddress"      => $row->ip_address,
				"ipNetmask"      => $row->ip_netmask,
				"ipGateway"      => $row->ip_gateway,
				"ip6Address"     => $row->ip6_address,
				"ip6Gateway"     => $row->ip6_gateway,
				"interfaceMtu"   => $row->interface_mtu,
				"cachegroup"     => $row->cachegroup->name,
				"physLocation"   => $row->phys_location->name,
				"rack"           => $row->rack,
				"type"           => $row->type->name,
				"status"         => $row->status->name,
				"profile"        => $row->profile->name,
				"mgmtIpAddress"  => $row->mgmt_ip_address,
				"mgmtIpNetmask"  => $row->mgmt_ip_netmask,
				"mgmtIpGateway"  => $row->mgmt_ip_gateway,
				"iloIpAddress"   => $row->ilo_ip_address,
				"iloIpNetmask"   => $row->ilo_ip_netmask,
				"iloIpGateway"   => $row->ilo_ip_gateway,
				"iloUsername"    => $row->ilo_username,
				"routerHostName" => $row->router_host_name,
				"routerPortName" => $row->router_port_name,
			};
			my $hw_rs = $row->hwinfos;
			while ( my $hwinfo_row = $hw_rs->next ) {
				$serv->{hardwareInfo}->{ $hwinfo_row->description } = $hwinfo_row->val;
			}

			my $rs_ds_data = $row->deliveryservice_servers;
			while ( my $dsrow = $rs_ds_data->next ) {
				push( @{ $serv->{deliveryservices} }, $dsrow->deliveryservice->id );
			}

			push( @data, $serv );
		}
		my $size = @data;
		$self->success( \@data, $orderby, $limit, $size );
	}
	else {
		$self->success( [] );
	}
}

sub check_server_params {
    my $self = shift;
    my $json = shift;
    my $flag_create = shift;
    my %params = %{$json};
    my $err = undef;

    if ( defined( $json->{'interface_mtu'} ) ) {
        if ( $json->{'interface_mtu'} != '1500' && $json->{'interface_mtu'} != '9000' )
        {
            return (\%params, "'interface_mtu' '$json->{'interface_mtu'}' not equal to 1500 or 9000!");
        }
    }

    if ( defined( $json->{'tcp_port'} ) ) {
        $params{'tcp_port'} = int( $json->{'tcp_port'} );
    }
    elsif ($flag_create) {
        $params{'tcp_port'} = 80;
    }

    if ( defined( $json->{'cachegroup'} ) ) {
        eval {
            $params{'cachegroup'} = $self->db->resultset('Cachegroup')->search( { name => $json->{'cachegroup'} } )->get_column('id')->single();
        };
        if ($@ || (!defined($params{'cachegroup'}))) {
            return (\%params, "'cachegroup' $json->{'cachegroup'} not found!");
        }
    }
    elsif ($flag_create) {
        return (\%params, "'cachegroup' not specified!");
    }

    if ( defined( $json->{'cdn_name'} ) ) {
        eval {
            $params{'cdn_id'} = $self->db->resultset('Cdn')->search( { name => $json->{'cdn_name'} } )->get_column('id')->single();
        }
    }
    elsif ($flag_create) {
        return (\%params, "'cdn_name' not specified!");
    }

    if ( defined( $json->{'type'} ) ) {
        eval {
            $params{'type'} = &type_id( $self, $json->{'type'});
        };
        if ($@ || (!defined($params{'type'}))) {
            return (\%params, "'type' $json->{'type'} not found!");
        }
    }
    elsif ($flag_create) {
        return (\%params, "'type' not specified!");
    }

    if ( defined( $json->{'profile'} ) ) {
        eval {
            $params{'profile'} = &profile_id( $self, $json->{'profile'});
        };
        if ($@ || (!defined($params{'profile'}))) {
            return (\%params, "'profile' $json->{'profile'} not found!");
        }
    }
    elsif ($flag_create) {
        return (\%params, "'profile' not specified!");
    }

    if ( defined( $json->{'phys_location'} ) ) {
        eval {
            $params{'phys_location'} = $self->db->resultset('PhysLocation')->search( { name => $json->{'phys_location'} } )->get_column('id')->single();
        };
        if ($@ || (!defined($params{'phys_location'}))) {
            return (\%params, "'phys_location' $json->{'phys_location'} not found!");
        }
    }
    elsif ($flag_create) {
        return (\%params, "'phys_location' not specified!");
    }

    return (\%params, $err);
}

sub get_server_by_id {
    my $self = shift;
    my $id = shift;
    my $row;
    my $isadmin = &is_admin($self);
    eval {
        $row = $self->db->resultset('Server')->find( { id => $id } );
    };
    if ($@) {
        $self->app->log->error( "Fail to get server id = $id: $@" );
        return (undef, "Fail to get server id = $id: $@")
    }
    my $data = {
        "id"             => $row->id,
        "hostName"       => $row->host_name,
        "domainName"     => $row->domain_name,
        "tcpPort"        => $row->tcp_port,
        "xmppId"         => $row->xmpp_id,
        "xmppPasswd"     => "**********",
        "interfaceName"  => $row->interface_name,
        "ipAddress"      => $row->ip_address,
        "ipNetmask"      => $row->ip_netmask,
        "ipGateway"      => $row->ip_gateway,
        "ip6Address"     => $row->ip6_address,
        "ip6Gateway"     => $row->ip6_gateway,
        "interfaceMtu"   => $row->interface_mtu,
        "cachegroup"     => $row->cachegroup->name,
        "cdn_id"         => $row->cdn_id,
        "physLocation"   => $row->phys_location->name,
        "rack"           => $row->rack,
        "type"           => $row->type->name,
        "status"         => $row->status->name,
        "profile"        => $row->profile->name,
        "mgmtIpAddress"  => $row->mgmt_ip_address,
        "mgmtIpNetmask"  => $row->mgmt_ip_netmask,
        "mgmtIpGateway"  => $row->mgmt_ip_gateway,
        "iloIpAddress"   => $row->ilo_ip_address,
        "iloIpNetmask"   => $row->ilo_ip_netmask,
        "iloIpGateway"   => $row->ilo_ip_gateway,
        "iloUsername"    => $row->ilo_username,
        "iloPassword"    => $isadmin ? $row->ilo_password : "********",
        "routerHostName" => $row->router_host_name,
        "routerPortName" => $row->router_port_name,
        "lastUpdated"    => $row->last_updated,

    };
    return ($data, undef);
}

sub create {
    my ($params, $data, $err) = (undef, undef, undef);
    my $self = shift;

    my $json = $self->req->json;
    if ( !&is_oper($self) ) {
        return $self->alert("You must be an ADMIN or OPER to perform this operation!");
    }

    ($params, $err) = $self->check_server_params($json, 1);
    if( defined($err) ) {
        return $self->alert(
            { Error => $err }
        );
    }

    my $new_id = -1;
    my $xmpp_passwd = "BOOGER";
    my $insert;
    if ( defined( $json->{'ip6_address'} )
        && $json->{'ip6_address'} ne "" )
    {
        eval { $insert = $self->db->resultset('Server')->create(
                {
                    host_name        => $json->{'host_name'},
                    domain_name      => $json->{'domain_name'},
                    tcp_port         => $params->{'tcp_port'},
                    xmpp_id          => $json->{'host_name'},           # TODO JvD remove me later.
                    xmpp_passwd      => $xmpp_passwd,
                    interface_name   => $json->{'interface_name'},
                    ip_address       => $json->{'ip_address'},
                    ip_netmask       => $json->{'ip_netmask'},
                    ip_gateway       => $json->{'ip_gateway'},
                    ip6_address      => $json->{'ip6_address'},
                    ip6_gateway      => $json->{'ip6_gateway'},
                    interface_mtu    => $json->{'interface_mtu'},
                    cachegroup       => $params->{'cachegroup'},
                    cdn_id           => $params->{'cdn_id'},
                    phys_location    => $params->{'phys_location'},
                    rack             => $json->{'rack'},
                    type             => $params->{'type'},
                    status           => &admin_status_id( $self, $json->{'type'} eq "EDGE" ? "REPORTED" : "ONLINE" ),
                    profile          => $params->{'profile'},
                    mgmt_ip_address  => $json->{'mgmt_ip_address'},
                    mgmt_ip_netmask  => $json->{'mgmt_ip_netmask'},
                    mgmt_ip_gateway  => $json->{'mgmt_ip_gateway'},
                    ilo_ip_address   => $json->{'ilo_ip_address'},
                    ilo_ip_netmask   => $json->{'ilo_ip_netmask'},
                    ilo_ip_gateway   => $json->{'ilo_ip_gateway'},
                    ilo_username     => $json->{'ilo_username'},
                    ilo_password     => $json->{'ilo_password'},
                    router_host_name => $json->{'router_host_name'},
                    router_port_name => $json->{'router_port_name'},
                }
            ); 
        };
        if ($@) {
            $self->app->log->error( "Fail to create server: $@" );
            return $self->alert(
                { Error => "Fail to create server: $@" }
            );
        }
    }
    else {
        eval { $insert = $self->db->resultset('Server')->create(
                {
                    host_name        => $json->{'host_name'},
                    domain_name      => $json->{'domain_name'},
                    tcp_port         => $params->{'tcp_port'},
                    xmpp_id          => $json->{'host_name'},           # TODO JvD remove me later.
                    xmpp_passwd      => $xmpp_passwd,
                    interface_name   => $json->{'interface_name'},
                    ip_address       => $json->{'ip_address'},
                    ip_netmask       => $json->{'ip_netmask'},
                    ip_gateway       => $json->{'ip_gateway'},
                    interface_mtu    => $json->{'interface_mtu'},
                    cachegroup       => $params->{'cachegroup'},
                    cdn_id           => $params->{'cdn_id'},
                    phys_location    => $params->{'phys_location'},
                    rack             => $json->{'rack'},
                    type             => $params->{'type'},
                    status           => &admin_status_id( $self, $json->{'type'} eq "EDGE" ? "REPORTED" : "ONLINE" ),
                    profile          => $params->{'profile'},
                    mgmt_ip_address  => $json->{'mgmt_ip_address'},
                    mgmt_ip_netmask  => $json->{'mgmt_ip_netmask'},
                    mgmt_ip_gateway  => $json->{'mgmt_ip_gateway'},
                    ilo_ip_address   => $json->{'ilo_ip_address'},
                    ilo_ip_netmask   => $json->{'ilo_ip_netmask'},
                    ilo_ip_gateway   => $json->{'ilo_ip_gateway'},
                    ilo_username     => $json->{'ilo_username'},
                    ilo_password     => $json->{'ilo_password'},
                    router_host_name => $json->{'router_host_name'},
                    router_port_name => $json->{'router_port_name'},
                }
            );
        };
        if ($@) {
            $self->app->log->error( "Fail to create server: $@" );
            return $self->alert(
                { Error => "Fail to create server: $@" }
            );
        }
    }
    $insert->insert();
    $new_id = $insert->id;
    if (   $json->{'type'} eq "EDGE"
        || $json->{'type'} eq "MID" )
    {
        $insert = $self->db->resultset('Servercheck')->create( { server => $new_id, } );
        $insert->insert();
    }

    # if the insert has failed, we don't even get here, we go to the exception page.
    &log( $self, "Create server with hostname:" . $json->{'host_name'}, "UICHANGE" );

    ($data, $err) = $self->get_server_by_id($new_id);
    if( defined($err) ) {
        return $self->alert(
            { Error => $err }
        );
    }
    $self->success($data);
}

sub update {
    my ($params, $data, $err) = (undef, undef, undef);
    my $self = shift;

    my $json = $self->req->json;
    if ( !&is_oper($self) ) {
        return $self->alert("You must be an ADMIN or OPER to perform this operation!");
    }

    my $id   = $self->param('id');

    ($params, $err) = $self->check_server_params($json, 0);
    if( defined($err) ) {
        return $self->alert(
            { Error => $err }
        );
    }

    # get resultset for original and one to be updated.  Use to examine diffs to propagate the effects of the change.
    my $org_server = $self->db->resultset('Server')->find( { id => $id } );
    if( !defined($org_server) ) {
        return $self->alert(
            { Error => "Fail to find server id = $id" }
        );
    }
    my $update     = $self->db->resultset('Server')->find( { id => $id } );
    eval { 
        $update->update(
            {
                host_name        => defined($params->{'host_name'}) ? $params->{'host_name'} : $update->host_name,
                domain_name      => defined($params->{'domain_name'}) ? $params->{'domain_name'} : $update->domain_name,
                tcp_port         => defined($params->{'tcp_port'}) ? $params->{'tcp_port'} : $update->tcp_port,
                interface_name   => defined($params->{'interface_name'}) ? $params->{'interface_name'} : $update->interface_name,
                ip_address       => defined($params->{'ip_address'}) ? $params->{'ip_address'} : $update->ip_address,
                ip_netmask       => defined($params->{'ip_netmask'}) ? $params->{'ip_netmask'} : $update->ip_netmask,
                ip_gateway       => defined($params->{'ip_gateway'}) ? $params->{'ip_gateway'} : $update->ip_gateway,
                ip6_address      => defined($params->{'ip6_address'}) ? $params->{'ip6_address'} : $update->ip6_address,
                ip6_gateway      => defined($params->{'ip6_gateway'}) ? $params->{'ip6_gateway'} : $update->ip6_gateway,
                interface_mtu    => defined($params->{'interface_mtu'}) ? $params->{'interface_mtu'} : $update->interface_mtu,
                cachegroup       => defined($params->{'cachegroup'}) ? $params->{'cachegroup'} : $update->cachegroup->id,
                cdn_id           => defined($params->{'cdn_id'}) ? $params->{'cdn_id'} : $update->cdn_id,
                phys_location    => defined($params->{'phys_location'}) ? $params->{'phys_location'} : $update->phys_location->id,
                rack             => defined($params->{'rack'}) ? $params->{'rack'} : $update->rack,
                type             => defined($params->{'type'}) ? $params->{'type'} : $update->type->id,
                status           => defined($params->{'status'}) ? $params->{'status'} : $update->status->id,
                profile          => defined($params->{'profile'}) ? $params->{'profile'} : $update->profile->id,
                mgmt_ip_address  => defined($params->{'mgmt_ip_address'}) ? $params->{'mgmt_ip_address'} : $update->mgmt_ip_address,
                mgmt_ip_netmask  => defined($params->{'mgmt_ip_netmask'}) ? $params->{'mgmt_ip_netmask'} : $update->mgmt_ip_netmask,
                mgmt_ip_gateway  => defined($params->{'mgmt_ip_gateway'}) ? $params->{'mgmt_ip_gateway'} : $update->mgmt_ip_gateway,
                ilo_ip_address   => defined($params->{'ilo_ip_address'}) ? $params->{'ilo_ip_address'} : $update->ilo_ip_address,
                ilo_ip_netmask   => defined($params->{'ilo_ip_netmask'}) ? $params->{'ilo_ip_netmask'} : $update->ilo_ip_netmask,
                ilo_ip_gateway   => defined($params->{'ilo_ip_gateway'}) ? $params->{'ilo_ip_gateway'} : $update->ilo_ip_gateway,
                ilo_username     => defined($params->{'ilo_username'}) ? $params->{'ilo_username'} : $update->ilo_username,
                ilo_password     => defined($params->{'ilo_password'}) ? $params->{'ilo_password'} : $update->ilo_password,
                router_host_name => defined($params->{'router_host_name'}) ? $params->{'router_host_name'} : $update->router_host_name,
                router_port_name => defined($params->{'router_port_name'}) ? $params->{'router_port_name'} : $update->router_port_name,
            }
        ); 
    };
    if ($@) {
        $self->app->log->error( "Fail to update server id = $id: $@" );
        return $self->alert(
            { Error => "Fail to update server: $@" }
        );
    }
    $update->update();

    if ( $org_server->profile->id != $update->profile->id ) {
        my $param =
        $self->db->resultset('ProfileParameter')
        ->search(
            { -and => [ profile => $org_server->profile->id, 'parameter.config_file' => 'rascal-config.txt', 'parameter.name' => 'CDN_name' ] },
            { prefetch => [ { parameter => undef }, { profile => undef } ] } )->single();
        my $org_cdn_name = "";
        if ( defined($param) ) {
            $org_cdn_name = $param->parameter->value;
        }

        $param =
        $self->db->resultset('ProfileParameter')
        ->search( { -and => [ profile => $update->profile->id, 'parameter.config_file' => 'rascal-config.txt', 'parameter.name' => 'CDN_name' ] },
            { prefetch => [ { parameter => undef }, { profile => undef } ] } )->single();
        my $upd_cdn_name = "";
        if ( defined($param) ) {
            $upd_cdn_name = $param->parameter->value;
        }

        if ( $upd_cdn_name ne $org_cdn_name ) {
            my $delete = $self->db->resultset('DeliveryserviceServer')->search( { server => $id } );
            $delete->delete();
            &log( $self, $update->host_name . " profile change assigns server to new CDN - deleting all DS assignments", "UICHANGE" );
        }
        if ( $org_server->type->id != $update->type->id ) {
            my $delete = $self->db->resultset('DeliveryserviceServer')->search( { server => $id } );
            $delete->delete();
            &log( $self, $update->host_name . " profile change changes cache type - deleting all DS assignments", "UICHANGE" );
        }
    }

    if ( $org_server->type->id != $update->type->id ) {

        # server type changed:  servercheck entry required for EDGE and MID, but not others. Add or remove servercheck entry accordingly
        my %need_servercheck = map { &type_id( $self, $_ ) => 1 } qw{ EDGE MID };
        my $newtype_id       = $update->type->id;
        my $servercheck      = $self->db->resultset('Servercheck')->search( { server => $id } );
        if ( $servercheck != 0 && !$need_servercheck{$newtype_id} ) {

            # servercheck entry found but not needed -- delete it
            $servercheck->delete();
            &log( $self, $update->host_name . " cache type change - deleting servercheck", "UICHANGE" );
        }
        elsif ( $servercheck == 0 && $need_servercheck{$newtype_id} ) {

            # servercheck entry not found but needed -- insert it
            $servercheck = $self->db->resultset('Servercheck')->create( { server => $id } );
            $servercheck->insert();
            &log( $self, $update->host_name . " cache type changed - adding servercheck", "UICHANGE" );
        }
    }

    # this just creates the log string for the log table / tab.
    my $lstring = "Update server " . $update->host_name . " ";
    foreach my $col ( keys %{ $org_server->{_column_data} } ) {
        if ( defined( $params->{$col} )
            && $params->{$col} ne ( $org_server->{_column_data}->{$col} // "" ) )
        {
            if ( $col eq 'ilo_password' || $col eq 'xmpp_passwd' ) {
                $lstring .= $col . "-> ***********";
            }
            else {
                $lstring .= $col . "->" . $params->{$col} . " ";
            }
        }
    }

    # if the update has failed, we don't even get here, we go to the exception page.
    &log( $self, $lstring, "UICHANGE" );

    ($data, $err) = $self->get_server_by_id($id);
    if( defined($err) ) {
        return $self->alert(
            { Error => $err }
        );
    }
    $self->success($data);
}

1;
