package UI::Server;

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
use UI::Status;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

sub index {
	my $self = shift;

	&navbarpage($self);
}

sub view {
	my $self      = shift;
	my $mode      = $self->param('mode');
	my $id        = $self->param('id');
	my $rs_server = $self->db->resultset('Server')->search( { id => $id } );

	if ( $mode eq "view" ) {
		&stash_role($self);

		my $data = $rs_server->single;

		# don't send the passwds over the wire if the user doesn't have at least Ops privs.
		if ( $self->stash('priv_level') < 20 ) {
			$data->{_column_data}->{ilo_password} = "*********";
			$data->{_column_data}->{xmpp_passwd}  = "*********";
		}

		# Get list of ds ids associated with server
		$self->stash( server_data => $data );

		my @ds_ids = $self->db->resultset('DeliveryserviceServer')->search( { server => $id } )->get_column('deliveryservice')->all;

		my $service_tag =
			$self->db->resultset('Hwinfo')->search( { -and => [ serverid => $id, description => 'ServiceTag' ] } )->get_column('val')->single();
		$self->stash( service_tag => $service_tag );
		my %delivery_services;
		for my $ds_id (@ds_ids) {
			my $desc = $self->db->resultset('Deliveryservice')->search( { id => $ds_id } )->get_column('xml_id')->single;
			$delivery_services{$ds_id} = $desc;
		}
		$self->stash( delivery_services => \%delivery_services );
		$self->stash( fbox_layout       => 1 );
	}
}

sub server_by_id {
	my $self     = shift;
	my $serverid = $self->param('id');
	my $server_row =
		$self->db->resultset("Server")->search( { id => $serverid } )->single;
	if ( defined($server_row) ) {
		my %data = (
			"id"             => $server_row->id,
			"host_name"      => $server_row->host_name,
			"domain_name"    => $server_row->domain_name,
			"guid"           => $server_row->guid,
			"tcp_port"       => $server_row->tcp_port,
			"xmpp_id"        => $server_row->xmpp_id,
			"xmpp_passwd"    => $server_row->xmpp_passwd,
			"interface_name" => $server_row->interface_name,
			"ip_address"     => $server_row->ip_address,
			"ip_netmask"     => $server_row->ip_netmask,
			"ip_gateway"     => $server_row->ip_gateway,
			"ip6_address"    => $server_row->ip6_address,
			"ip6_gateway"    => $server_row->ip6_gateway,
			"interface_mtu"  => $server_row->interface_mtu,
		);
		$self->render( json => \%data );
	}
	else {
		$self->render( json => { Error => "Server '$serverid' not found}" } );
	}

}

# Read
sub index_response {
	my $self = shift;
	my $data = getserverdata($self);
	$self->render( json => $data );
}

sub getserverdata {
	my $self = shift;
	my @data;
	my $orderby = "host_name";
	$orderby = $self->param('orderby') if ( defined $self->param('orderby') );
	my $rs_data = $self->db->resultset('Server')->search(
		undef, {
			prefetch => [ 'cdn', 'cachegroup', 'type', 'profile', 'status', 'phys_location' ],
			order_by => 'me.' . $orderby,
		}
	);
	while ( my $row = $rs_data->next ) {
		my $cdn_name = defined( $row->cdn_id ) ? $row->cdn->name : "";

		push(
			@data, {
				"id"               => $row->id,
				"host_name"        => $row->host_name,
				"domain_name"      => $row->domain_name,
				"tcp_port"         => $row->tcp_port,
				"xmpp_id"          => $row->xmpp_id,
				"xmpp_passwd"      => "**********",
				"interface_name"   => $row->interface_name,
				"ip_address"       => $row->ip_address,
				"ip_netmask"       => $row->ip_netmask,
				"ip_gateway"       => $row->ip_gateway,
				"ip6_address"      => $row->ip6_address,
				"ip6_gateway"      => $row->ip6_gateway,
				"interface_mtu"    => $row->interface_mtu,
				"cdn"              => $cdn_name,
				"cachegroup"       => $row->cachegroup->name,
				"phys_location"    => $row->phys_location->name,
				"guid"             => $row->guid,
				"rack"             => $row->rack,
				"type"             => $row->type->name,
				"status"           => $row->status->name,
				"profile"          => $row->profile->name,
				"mgmt_ip_address"  => $row->mgmt_ip_address,
				"mgmt_ip_netmask"  => $row->mgmt_ip_netmask,
				"mgmt_ip_gateway"  => $row->mgmt_ip_gateway,
				"ilo_ip_address"   => $row->ilo_ip_address,
				"ilo_ip_netmask"   => $row->ilo_ip_netmask,
				"ilo_ip_gateway"   => $row->ilo_ip_gateway,
				"ilo_username"     => $row->ilo_username,
				"ilo_password"     => "**********",
				"router_host_name" => $row->router_host_name,
				"router_port_name" => $row->router_port_name,
				"last_updated"     => $row->last_updated,

			}

		);
	}

	return ( \@data );
}

sub serverdetail {
	my $self = shift;
	my @data;
	my $select = undef;
	$select = $self->param('select') if ( defined $self->param('select') );
	my $rs_data = $self->db->resultset('Server')->search(
		undef, {
			prefetch => [ 'cdn', 'cachegroup', 'type', 'profile', 'status', 'phys_location' ],
		}
	);
	while ( my $row = $rs_data->next ) {
		my $cdn_name = defined( $row->cdn_id ) ? $row->cdn->name : "";
		my $fqdn = $row->host_name . "." . $row->domain_name;
		if ( defined($select) && $fqdn !~ /$select/ ) { next; }
		my $serv = {
			"id"               => $row->id,
			"host_name"        => $row->host_name,
			"domain_name"      => $row->domain_name,
			"tcp_port"         => $row->tcp_port,
			"xmpp_id"          => $row->xmpp_id,
			"xmpp_passwd"      => $row->xmpp_passwd,
			"interface_name"   => $row->interface_name,
			"ip_address"       => $row->ip_address,
			"ip_netmask"       => $row->ip_netmask,
			"ip_gateway"       => $row->ip_gateway,
			"ip6_address"      => $row->ip6_address,
			"ip6_gateway"      => $row->ip6_gateway,
			"interface_mtu"    => $row->interface_mtu,
			"cdn"              => $cdn_name,
			"cachegroup"       => $row->cachegroup->name,
			"phys_location"    => $row->phys_location->name,
			"guid"             => $row->guid,
			"rack"             => $row->rack,
			"type"             => $row->type->name,
			"status"           => $row->status->name,
			"profile"          => $row->profile->name,
			"mgmt_ip_address"  => $row->mgmt_ip_address,
			"mgmt_ip_netmask"  => $row->mgmt_ip_netmask,
			"mgmt_ip_gateway"  => $row->mgmt_ip_gateway,
			"ilo_ip_address"   => $row->ilo_ip_address,
			"ilo_ip_netmask"   => $row->ilo_ip_netmask,
			"ilo_ip_gateway"   => $row->ilo_ip_gateway,
			"ilo_username"     => $row->ilo_username,
			"ilo_password"     => $row->ilo_password,
			"router_host_name" => $row->router_host_name,
			"router_port_name" => $row->router_port_name,
		};
		my $id = $row->id;
		my $rs_hwinfo_data =
			$self->db->resultset('Hwinfo')->search( { 'serverid' => $id } );
		while ( my $hwinfo_row = $rs_hwinfo_data->next ) {
			$serv->{ $hwinfo_row->description } = $hwinfo_row->val;
		}
		push( @data, $serv );
	}
	$self->render( json => \@data );
}

sub edge_ds_status {
	my $self          = shift;
	my $ds_id         = $self->param('dsid');
	my $profile_id    = $self->param('profileid');
	my $cachegroup_id = $self->param('cachegroupid');
	my @data;

	my %servers_in_cg = ();
	my %servers_in_ds = ();
	my @etypes        = &type_ids( $self, 'EDGE%', 'server' );
	my $rs_servers_cg = $self->db->resultset('Server')->search(
		{
			cachegroup => $cachegroup_id,
			profile    => $profile_id,
			type       => { -in => \@etypes }
		}
	);

	while ( my $row = $rs_servers_cg->next ) {
		$servers_in_cg{ $row->host_name } = $row->id;

	}

	my $rs_servers_ds =
		$self->db->resultset('DeliveryserviceServer')
		->search( { deliveryservice => $ds_id }, { prefetch => [ { deliveryservice => undef }, { server => undef } ] } );
	while ( my $row = $rs_servers_ds->next ) {
		$servers_in_ds{ $row->server->host_name } = $row->id;
	}

	my $id = 0;
	foreach my $server ( sort keys(%servers_in_cg) ) {
		push(
			@data, {
				"id"     => $id,
				"name"   => $server,
				"active" => defined( $servers_in_ds{$server} ) ? 1 : 0,
			}
		);
		$id++;
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
		my $delete = $self->db->resultset('Server')->search( { id => $id } );
		my $host_name = $delete->get_column('host_name')->single();
		$delete->delete();
		$delete =
			$self->db->resultset('Servercheck')->search( { server => $id } );
		$delete->delete();
		&log( $self, "Delete server with id:" . $id . " named " . $host_name, "UICHANGE" );
	}
	return $self->redirect_to('/close_fancybox.html');
}

sub check_server_input_cgi {
	my $self         = shift;
	my $paramHashRef = {};
	my $err          = undef;
	foreach my $requiredParam (qw/host_name domain_name ip_address ip_netmask ip_gateway interface_mtu interface_name cdn cachegroup type profile/) {
		$paramHashRef->{$requiredParam} = $self->param($requiredParam);
	}
	foreach my $optionalParam (
		qw/ilo_ip_address ilo_ip_netmask ilo_ip_gateway mgmt_ip_address mgmt_ip_netmask mgmt_ip_gateway ip6_address ip6_gateway tcp_port/)
	{
		$paramHashRef->{$optionalParam} = $self->param($optionalParam);
	}

	$paramHashRef = &trim_whitespace($paramHashRef);

	$err = &check_server_input( $self, $paramHashRef );
	return $err;
}

sub check_server_input {
	my $self              = shift;
	my $paramHashRef      = shift;
	my $sep               = "__NEWLINE__";    # the line separator sub that with \n in the .ep javascript
	my $err               = '';
	my $errorCSVLineDelim = '';

	# First, check permissions
	if ( !&is_oper($self) ) {
		$err .= "You do not have enough privileges to modify this." . $sep;
		if ( defined( $paramHashRef->{'csv_line_number'} ) ) {
			$err = '</li><li>' . $errorCSVLineDelim . '[LINE #:' . $paramHashRef->{'csv_line_number'} . ']:  ' . $err . '\n';
		}
		return $err;
	}

	# then, check the mandatory parameters for 'existence'. The error may be a bit cryptic to the user, but
	# I don't want to write too much code around it.
	foreach my $param (qw/host_name domain_name ip_address ip_netmask ip_gateway interface_mtu interface_name cdn cachegroup type profile/) {

		#print "$param -> " . $paramHashRef->{$param} . "\n";
		if ( !defined( $paramHashRef->{$param} )
			|| $paramHashRef->{$param} eq "" )
		{
			$err .= $param . " is a required field.";
			if ( defined( $paramHashRef->{'csv_line_number'} ) ) {
				$err = '</li><li>' . $errorCSVLineDelim . '[LINE #:' . $paramHashRef->{'csv_line_number'} . ']:  ' . $err . '\n';
			}
			return $err;
		}
	}

	# in order of the form
	if ( !&is_hostname( $paramHashRef->{'host_name'} ) ) {
		$err .= $paramHashRef->{'host_name'} . " is not a valid hostname (rfc1123)" . $sep;
	}
	my $dname = $paramHashRef->{'domain_name'};
	if ( !&is_hostname($dname) ) {
		$err .= $dname . " is not a valid domain name (rfc1123)" . $sep;
	}

	# IP address checks
	foreach my $ipstr (
		$paramHashRef->{'ip_address'},      $paramHashRef->{'ip_netmask'},      $paramHashRef->{'ip_gateway'},
		$paramHashRef->{'ilo_ip_address'},  $paramHashRef->{'ilo_ip_netmask'},  $paramHashRef->{'ilo_ip_gateway'},
		$paramHashRef->{'mgmt_ip_address'}, $paramHashRef->{'mgmt_ip_netmask'}, $paramHashRef->{'mgmt_ip_gateway'}
		)
	{
		if ( !defined($ipstr) || $ipstr eq "" ) {
			next;
		}    # already checked for mandatory.
		if ( !&is_ipaddress($ipstr) ) {
			$err .= $ipstr . " is not a valid IPv4 address or netmask" . $sep;
		}
	}

	if ( !&is_netmask( $paramHashRef->{'ip_netmask'} ) ) {
		$err .= $paramHashRef->{'ip_netmask'} . " is not a valid netmask (I think... ;-)" . $sep;
	}
	if ( $paramHashRef->{'ilo_ip_netmask'} ne ""
		&& !&is_netmask( $paramHashRef->{'ilo_ip_netmask'} ) )
	{
		$err .= $paramHashRef->{'ilo_ip_netmask'} . " is not a valid netmask (I think... ;-). $sep";
	}
	if ( $paramHashRef->{'mgmt_ip_netmask'} ne ""
		&& !&is_netmask( $paramHashRef->{'mgmt_ip_netmask'} ) )
	{
		$err .= $paramHashRef->{'mgmt_ip_netmask'} . " is not a valid netmask (I think... ;-). $sep";
	}
	my $ipstr1 = $paramHashRef->{'ip_address'} . "/" . $paramHashRef->{'ip_netmask'};
	my $ipstr2 = $paramHashRef->{'ip_gateway'} . "/" . $paramHashRef->{'ip_netmask'};
	if ( !&in_same_net( $ipstr1, $ipstr2 ) ) {
		$err .= $paramHashRef->{'ip_address'} . " and " . $paramHashRef->{'ip_gateway'} . " are not in same network" . $sep;
	}

	if (
		( defined( $paramHashRef->{'ip6_address'} ) && $paramHashRef->{'ip6_address'} ne "" )
		|| ( defined( $paramHashRef->{'ip6_gateway'} )
			&& $paramHashRef->{'ip6_gateway'} ne "" )
		)
	{
		if ( !&is_ip6address( $paramHashRef->{'ip6_address'} ) ) {
			$err .= "Address " . $paramHashRef->{'ip6_address'} . " is not a valid IPv6 address " . $sep;
		}
		if ( !&is_ip6address( $paramHashRef->{'ip6_gateway'} ) ) {
			$err .= "Gateway " . $paramHashRef->{'ip6_gateway'} . " is not a valid IPv6 address " . $sep;
		}
		if ( !&in_same_net( $paramHashRef->{'ip6_address'}, $paramHashRef->{'ip6_gateway'} ) ) {
			$err .= $paramHashRef->{'ip6_address'} . " and " . $paramHashRef->{'ip6_gateway'} . " are not in same network" . $sep;
		}
	}

	$ipstr1 = $paramHashRef->{'ilo_ip_address'} . "/" . $paramHashRef->{'ilo_ip_netmask'};
	$ipstr2 = $paramHashRef->{'ilo_ip_gateway'} . "/" . $paramHashRef->{'ilo_ip_netmask'};
	if ( $paramHashRef->{'ilo_ip_gateway'} ne ""
		&& !&in_same_net( $ipstr1, $ipstr2 ) )
	{
		$err .= $paramHashRef->{'ilo_ip_address'} . " and " . $paramHashRef->{'ilo_ip_gateway'} . " are not in same network" . $sep;
	}

	if ( defined( $paramHashRef->{'mgmt_ip_address'} ) ) {
		$ipstr1 = $paramHashRef->{'mgmt_ip_address'} . "/" . $paramHashRef->{'mgmt_ip_netmask'};
		$ipstr2 = $paramHashRef->{'mgmt_ip_gateway'} . "/" . $paramHashRef->{'mgmt_ip_netmask'};
		if ( $paramHashRef->{'mgmt_ip_gateway'} ne ""
			&& !&in_same_net( $ipstr1, $ipstr2 ) )
		{
			$err .= $paramHashRef->{'mgmt_ip_address'} . " and " . $paramHashRef->{'mgmt_ip_gateway'} . " are not in same network" . $sep;
		}
	}

	if ( $paramHashRef->{'tcp_port'} !~ /\d+/ ) {
		$err .= $paramHashRef->{'tcp_port'} . " is not a valid tcp port" . $sep;
	}

	# RFC5952 checks (lc)

	if ( defined( $paramHashRef->{'csv_line_number'} ) && length($err) > 0 ) {
		$err = '</li><li>' . $errorCSVLineDelim . '[LINE #:' . $paramHashRef->{'csv_line_number'} . ']:  ' . $err . '\n';
	}
	return $err;
}

# Update
sub update {
	my $self         = shift;
	my $paramHashRef = shift;

	#===
	# foreach my $f ($self->param) {
	# 	print $f . " => " . $self->param($f) . "\n";
	# }
	#===

	if ( !defined( $paramHashRef->{'csv_line_number'} ) ) {
		$paramHashRef = &cgi_params_to_param_hash_ref($self);
	}
	my $id = $paramHashRef->{'id'};

	$paramHashRef = &trim_whitespace($paramHashRef);

	my $err = &check_server_input_cgi($self);
	if ( defined($err) && length($err) > 0 ) {
		$self->flash( alertmsg => "update():  " . $err );
	}
	else {

		# get resultset for original and one to be updated.  Use to examine diffs to propagate the effects of the change.
		my $org_server = $self->db->resultset('Server')->search( { 'me.id' => $id }, { prefetch => 'cdn' } )->single();
		my $update     = $self->db->resultset('Server')->search( { 'me.id' => $id }, { prefetch => 'cdn' } )->single();

		$update->update(
			{
				host_name        => $paramHashRef->{'host_name'},
				domain_name      => $paramHashRef->{'domain_name'},
				tcp_port         => $paramHashRef->{'tcp_port'},
				interface_name   => $paramHashRef->{'interface_name'},
				ip_address       => $paramHashRef->{'ip_address'},
				ip_netmask       => $paramHashRef->{'ip_netmask'},
				ip_gateway       => $paramHashRef->{'ip_gateway'},
				ip6_address      => $self->paramAsScalar( 'ip6_address', undef ),
				ip6_gateway      => $paramHashRef->{'ip6_gateway'},
				interface_mtu    => $paramHashRef->{'interface_mtu'},
				cdn_id           => $paramHashRef->{'cdn'},
				cachegroup       => $paramHashRef->{'cachegroup'},
				phys_location    => $paramHashRef->{'phys_location'},
				guid             => $paramHashRef->{'guid'},
				rack             => $paramHashRef->{'rack'},
				type             => $paramHashRef->{'type'},
				status           => $paramHashRef->{'status'},
				profile          => $paramHashRef->{'profile'},
				mgmt_ip_address  => $paramHashRef->{'mgmt_ip_address'},
				mgmt_ip_netmask  => $paramHashRef->{'mgmt_ip_netmask'},
				mgmt_ip_gateway  => $paramHashRef->{'mgmt_ip_gateway'},
				ilo_ip_address   => $paramHashRef->{'ilo_ip_address'},
				ilo_ip_netmask   => $paramHashRef->{'ilo_ip_netmask'},
				ilo_ip_gateway   => $paramHashRef->{'ilo_ip_gateway'},
				ilo_username     => $paramHashRef->{'ilo_username'},
				ilo_password     => $paramHashRef->{'ilo_password'},
				router_host_name => $paramHashRef->{'router_host_name'},
				router_port_name => $paramHashRef->{'router_port_name'},
			}
		);
		$update->update();

		if ( $org_server->profile->id != $update->profile->id ) {
			my $org_cdn_name = $org_server->cdn->name;
			my $upd_cdn_name = $update->cdn->name;

			if ( $upd_cdn_name ne $org_cdn_name ) {
				my $delete = $self->db->resultset('DeliveryserviceServer')->search( { server => $id } );
				$delete->delete();
				&log( $self, $self->param('host_name') . " profile change assigns server to new CDN - deleting all DS assignments", "UICHANGE" );
				$self->flash( alertmsg => "update():  CDN change - all delivery service assignments have been deleted." );
			}
			if ( $org_server->type->id != $update->type->id ) {
				my $delete = $self->db->resultset('DeliveryserviceServer')->search( { server => $id } );
				$delete->delete();
				&log( $self, $self->param('host_name') . " profile change changes cache type - deleting all DS assignments", "UICHANGE" );
				$self->flash( alertmsg => "update():  Type change - all delivery service assignments have been deleted." );
			}
		}

		if ( $org_server->type->id != $update->type->id ) {

			# server type changed:  servercheck entry required for EDGE and MID, but not others. Add or remove servercheck entry accordingly
			my @types;
			push( @types, &type_ids( $self, 'EDGE%', 'server' ) );
			push( @types, &type_ids( $self, 'MID%',  'server' ) );
			my %need_servercheck = map { $_ => 1 } @types;
			my $newtype_id = $update->type->id;
			my $servercheck =
				$self->db->resultset('Servercheck')->search( { server => $id } );
			if ( $servercheck != 0 && !$need_servercheck{$newtype_id} ) {

				# servercheck entry found but not needed -- delete it
				$servercheck->delete();
				&log( $self, $self->param('host_name') . " cache type change - deleting servercheck", "UICHANGE" );
			}
			elsif ( $servercheck == 0 && $need_servercheck{$newtype_id} ) {

				# servercheck entry not found but needed -- insert it
				$servercheck = $self->db->resultset('Servercheck')->create( { server => $id } );
				$servercheck->insert();
				&log( $self, $self->param('host_name') . " cache type changed - adding servercheck", "UICHANGE" );
			}
		}

		# this just creates the log string for the log table / tab.
		my $lstring = "Update server " . $self->param('host_name') . " ";
		foreach my $col ( keys %{ $org_server->{_column_data} } ) {
			if ( defined( $self->param($col) )
				&& $self->param($col) ne ( $org_server->{_column_data}->{$col} // "" ) )
			{
				if ( $col eq 'ilo_password' || $col eq 'xmpp_passwd' ) {
					$lstring .= $col . "-> ***********";
				}
				else {
					$lstring .= $col . "->" . $self->param($col) . " ";
				}
			}
		}

		# if the update has failed, we don't even get here, we go to the exception page.
		&log( $self, $lstring, "UICHANGE" );
	}

	# $self->flash( alertmsg => "Success!" );
	my $referer = $self->req->headers->header('referer');
	return $self->redirect_to($referer);
}

sub updatestatus {
	my $self   = shift;
	my $id     = $self->param('id');
	my $status = $self->param('status');

	my $statstring = undef;
	if ( $status !~ /^\d$/ ) {    # if it is a string like "REPORTED", look up the id in the db.
		$statstring = $status;
		$status = $self->db->resultset('Status')->search( { name => $statstring } )->get_column('id')->single();
	}
	else {
		$statstring = $self->db->resultset('Status')->search( { id => $status } )->get_column('name')->single();
	}
	my $update = $self->set_serverstatus( $id, $status );
	my $fqdn = $update->host_name . "." . $update->domain_name;

	my $lstring = "Update server $fqdn new status = $statstring";
	&log( $self, $lstring, "UICHANGE" );

	my $referer = $self->req->headers->header('referer');
	return $self->redirect_to($referer);
}

sub set_serverstatus {
	my $self = shift;

	# instead of using $self->param, grab method arguments due to the fact that
	# we can't use :status as a placeholder in our rest call -jse
	my $id     = shift;
	my $status = shift;

	my $update = $self->db->resultset('Server')->find( { id => $id } );
	$update->update( { status => $status, } );
	$update->update();

	return ($update);
}

sub cgi_params_to_param_hash_ref {
	my $self         = shift;
	my $paramHashRef = {};
	foreach my $requiredParam (
		qw/host_name domain_name ip_address ip_netmask ip_gateway interface_mtu interface_name cdn cachegroup type profile phys_location/)
	{
		$paramHashRef->{$requiredParam} = $self->param($requiredParam);
	}
	foreach my $optionalParam (
		qw/ilo_ip_address ilo_ip_netmask ilo_ip_gateway mgmt_ip_address mgmt_ip_netmask mgmt_ip_gateway ip6_address ip6_gateway tcp_port
		ilo_username ilo_password router_host_name router_port_name status rack guid id/
		)
	{
		$paramHashRef->{$optionalParam} = $self->param($optionalParam);
	}
	return $paramHashRef;
}

# Create
sub create {
	my $self         = shift;
	my $paramHashRef = shift;
	if ( !defined( $paramHashRef->{'csv_line_number'} ) ) {
		$paramHashRef = &cgi_params_to_param_hash_ref($self);
	}
	return $self->redirect_to("/modify_error") if !&is_oper($self);

	my $new_id = -1;
	my $err    = '';
	if ( !defined( $paramHashRef->{'csv_line_number'} ) ) {
		$err = &check_server_input_cgi($self);
	}

	$paramHashRef = &trim_whitespace($paramHashRef);

	my $xmpp_passwd = "BOOGER";
	if ( defined($err) && length($err) > 0 ) {
		$self->flash( alertmsg => "create():  [" . length($err) . "] " . $err );
	}
	else {
		my $insert;
		if ( defined( $paramHashRef->{'ip6_address'} )
			&& $paramHashRef->{'ip6_address'} ne "" )
		{
			$insert = $self->db->resultset('Server')->create(
				{
					host_name        => $paramHashRef->{'host_name'},
					domain_name      => $paramHashRef->{'domain_name'},
					tcp_port         => $paramHashRef->{'tcp_port'},
					xmpp_id          => $paramHashRef->{'host_name'},           # TODO JvD remove me later.
					xmpp_passwd      => $xmpp_passwd,
					interface_name   => $paramHashRef->{'interface_name'},
					ip_address       => $paramHashRef->{'ip_address'},
					ip_netmask       => $paramHashRef->{'ip_netmask'},
					ip_gateway       => $paramHashRef->{'ip_gateway'},
					ip6_address      => $paramHashRef->{'ip6_address'},
					ip6_gateway      => $paramHashRef->{'ip6_gateway'},
					interface_mtu    => $paramHashRef->{'interface_mtu'},
					cdn_id           => $paramHashRef->{'cdn'},
					cachegroup       => $paramHashRef->{'cachegroup'},
					phys_location    => $paramHashRef->{'phys_location'},
					guid             => $paramHashRef->{'guid'},
					rack             => $paramHashRef->{'rack'},
					type             => $paramHashRef->{'type'},
					status           => &admin_status_id( $self, "OFFLINE" ),
					profile          => $paramHashRef->{'profile'},
					mgmt_ip_address  => $paramHashRef->{'mgmt_ip_address'},
					mgmt_ip_netmask  => $paramHashRef->{'mgmt_ip_netmask'},
					mgmt_ip_gateway  => $paramHashRef->{'mgmt_ip_gateway'},
					ilo_ip_address   => $paramHashRef->{'ilo_ip_address'},
					ilo_ip_netmask   => $paramHashRef->{'ilo_ip_netmask'},
					ilo_ip_gateway   => $paramHashRef->{'ilo_ip_gateway'},
					ilo_username     => $paramHashRef->{'ilo_username'},
					ilo_password     => $paramHashRef->{'ilo_password'},
					router_host_name => $paramHashRef->{'router_host_name'},
					router_port_name => $paramHashRef->{'router_port_name'},
				}
			);
		}
		else {
			$insert = $self->db->resultset('Server')->create(
				{
					host_name        => $paramHashRef->{'host_name'},
					domain_name      => $paramHashRef->{'domain_name'},
					tcp_port         => $paramHashRef->{'tcp_port'},
					xmpp_id          => $paramHashRef->{'host_name'},           # TODO JvD remove me later.
					xmpp_passwd      => $xmpp_passwd,
					interface_name   => $paramHashRef->{'interface_name'},
					ip_address       => $paramHashRef->{'ip_address'},
					ip_netmask       => $paramHashRef->{'ip_netmask'},
					ip_gateway       => $paramHashRef->{'ip_gateway'},
					interface_mtu    => $paramHashRef->{'interface_mtu'},
					cdn_id           => $paramHashRef->{'cdn'},
					cachegroup       => $paramHashRef->{'cachegroup'},
					phys_location    => $paramHashRef->{'phys_location'},
					guid             => $paramHashRef->{'guid'},
					rack             => $paramHashRef->{'rack'},
					type             => $paramHashRef->{'type'},
					status           => &admin_status_id( $self, "OFFLINE" ),
					profile          => $paramHashRef->{'profile'},
					mgmt_ip_address  => $paramHashRef->{'mgmt_ip_address'},
					mgmt_ip_netmask  => $paramHashRef->{'mgmt_ip_netmask'},
					mgmt_ip_gateway  => $paramHashRef->{'mgmt_ip_gateway'},
					ilo_ip_address   => $paramHashRef->{'ilo_ip_address'},
					ilo_ip_netmask   => $paramHashRef->{'ilo_ip_netmask'},
					ilo_ip_gateway   => $paramHashRef->{'ilo_ip_gateway'},
					ilo_username     => $paramHashRef->{'ilo_username'},
					ilo_password     => $paramHashRef->{'ilo_password'},
					router_host_name => $paramHashRef->{'router_host_name'},
					router_port_name => $paramHashRef->{'router_port_name'},
				}
			);
		}
		$insert->insert();
		$new_id = $insert->id;
		if (   scalar( grep { $paramHashRef->{'type'} eq $_ } &type_ids( $self, 'EDGE%', 'server' ) )
			|| scalar( grep { $paramHashRef->{'type'} eq $_ } &type_ids( $self, 'MID%', 'server' ) ) )
		{
			$insert = $self->db->resultset('Servercheck')->create( { server => $new_id, } );
			$insert->insert();
		}

		# if the insert has failed, we don't even get here, we go to the exception page.
		&log( $self, "Create server with hostname:" . $paramHashRef->{'host_name'}, "UICHANGE" );
	}

	if ( !defined( $paramHashRef->{'csv_line_number'} ) ) {
		if ( $new_id == -1 ) {
			my $referer = $self->req->headers->header('referer');
			my $qstring = "?";
			my @params  = $self->param;
			foreach my $field (@params) {

				#print ">". $self->param($field) . "<\n";
				if ( $self->param($field) ne "" ) {
					$qstring .= "$field=" . $self->param($field) . "\&";
				}
			}
			if ( defined($referer) ) {
				chop($qstring);
				my $stripped = ( split( /\?/, $referer ) )[0];
				return $self->redirect_to( $stripped . $qstring );
			}
			else {
				return $self->render(
					text   => "ERR = " . $err,
					layout => undef
				);    # for testing - $referer is not defined there.
			}
		}
		else {
			$self->flash( alertmsg => "Success!" );
			return $self->redirect_to("/server/$new_id/view");
		}
	}
}

# for the add server view
sub add {
	my $self = shift;

	my $default_port = 80;
	$self->stash(
		fbox_layout      => 1,
		default_tcp_port => $default_port,
	);
	my @params = $self->param;
	foreach my $field (@params) {
		$self->stash( $field => $self->param($field) );
	}
}

sub rest_update_server_status {
	my $self = shift;
	my $response;
	my $host_name = $self->param("name");
	my $status    = $self->param("state");

	$response->{result} = "FAILED";

	if ( &is_admin($self) ) {
		if ( defined($host_name) && defined($status) ) {
			my $row = $self->db->resultset("Server")->search( { host_name => $host_name } )->single;

			if ( defined($row) && defined( $row->id ) ) {
				my $status_id = UI::Status::is_valid_status( $self, $status );

				if ($status_id) {
					$self->set_serverstatus( $row->id, $status_id );
					$response->{result}  = "SUCCESS";
					$response->{message} = "Successfully set status of $host_name to $status";
					my $fqdn    = $row->host_name . "." . $row->domain_name;
					my $lstring = "Update server $fqdn status=$status";
					&log( $self, $lstring, "APICHANGE" );
				}
				else {
					$response->{message} = "Status $status is invalid";
				}
			}
			else {
				$response->{message} = "Unable to find server ID for $host_name";
			}
		}
		else {
			if ( !defined($host_name) ) {
				$response->{message} = "Hostname is undefined";
			}
			elsif ( !defined($status) ) {
				$response->{message} = "Status is undefined";
			}
			else {
				$response->{message} = "Insufficient data to proceed";
			}
		}
	}
	else {
		$response->{message} = "You must be an admin to perform this function";
	}
	$self->render( json => $response );
}

sub get_server_status {
	my $self      = shift;
	my $host_name = $self->param("name");
	my $response  = {};

	if ( &is_admin($self) && defined($host_name) ) {
		my $row = $self->db->resultset("Server")->search( { host_name => $host_name } )->single;

		if ( defined($row) && defined( $row->id ) ) {
			$response->{status} = $row->status->name;
		}
	}

	$self->render( json => $response );
}

sub readupdate {
	my $self = shift;
	my @data;
	my $host_name = $self->param("host_name");

	my $rs_servers;
	my %parent_pending = ();
	if ( $host_name =~ m/^all$/ ) {
		$rs_servers = $self->db->resultset("Server")->search(undef);
	}
	else {
		$rs_servers =
			$self->db->resultset("Server")->search( { host_name => $host_name } );
		my $count = $rs_servers->count();
		if ( $count > 0 ) {
			if ( $rs_servers->single->type->name =~ m/^EDGE/ ) {
				my $parent_cg =
					$self->db->resultset('Cachegroup')->search( { id => $rs_servers->single->cachegroup->id } )->get_column('parent_cachegroup_id')->single;
				my $rs_parents = $self->db->resultset('Server')->search( { cachegroup => $parent_cg } );
				while ( my $prow = $rs_parents->next ) {
					if (   $prow->upd_pending == 1
						&& $prow->status->name ne "OFFLINE" )
					{
						$parent_pending{ $rs_servers->single->host_name } = 1;
					}
				}
			}
		}
	}

	while ( my $row = $rs_servers->next ) {
		if ( $parent_pending{ $row->host_name } ) {
			push(
				@data, {
					host_name      => $row->host_name,
					upd_pending    => $row->upd_pending,
					host_id        => $row->id,
					status         => $row->status->name,
					parent_pending => "1"
				}
			);
		}
		else {
			push(
				@data, {
					host_name      => $row->host_name,
					upd_pending    => $row->upd_pending,
					host_id        => $row->id,
					status         => $row->status->name,
					parent_pending => "0"
				}
			);
		}
	}

	$self->render( json => \@data );
}

sub postupdate {

	my $self      = shift;
	my $updated   = $self->param("updated");
	my $host_name = $self->param("host_name");
	if ( !&is_admin($self) ) {
		$self->render_text( "Unauthorized.", status => 401, layout => undef );
		return;
	}

	if ( !defined($updated) ) {
		$self->render_text(
			"Failed request.  Must provide updated status",
			status => 500,
			layout => undef
		);
		return;
	}

	# resolve server id
	my $serverid = $self->db->resultset("Server")->search( { host_name => $host_name } )->get_column('id')->single;
	if ( !defined $serverid ) {
		$self->render_text(
			"Failed request.  Unknown server",
			status => 500,
			layout => undef
		);
		return;
	}

	my $update_server =
		$self->db->resultset('Server')->search( { id => $serverid } );
	if ( defined $updated ) {
		$update_server->update( { upd_pending => $updated } );
	}

	# $self->render_text("Success", layout=>undef);

}

sub postupdatequeue {
	my $self       = shift;
	my $setqueue   = $self->param("setqueue");
	my $status     = $self->param("status");
	my $host       = $self->param("id");
	my $cdn        = $self->param("cdn");
	my $cachegroup = $self->param("cachegroup");
	my $wording    = ( $setqueue == 1 ) ? "Queue Updates" : "Unqueue Updates";

	if ( !&is_admin($self) && !&is_oper($self) ) {
		$self->flash( alertmsg => "No can do. Get more privs." );
		return;
	}

	if ( defined($host) ) {
		my $update;
		my $message;

		if ( $host eq "all" ) {
			$update  = $self->db->resultset('Server')->search(undef);
			$message = "all servers";
		}
		elsif (defined($status)) {
			my $server = $self->db->resultset('Server')->search( { id => $host, } )->single();
			my @edge_cache_groups = $self->db->resultset('Cachegroup')->search( { parent_cachegroup_id => $server->cachegroup->id } )->all();
			my @cg_ids = map { $_->id } @edge_cache_groups;
			$update = $self->db->resultset('Server')->search( { cachegroup => { -in => \@cg_ids }, cdn_id => $server->cdn_id } );
			$message = "children of " . $server->host_name . " in the following cachegroups: " . join( ", ", map { $_->name } @edge_cache_groups );
		} else {
			$update = $self->db->resultset('Server')->search( { id => $host } );
			$message = $host;
		}
		$update->update( { upd_pending => $setqueue } );
		&log( $self, "Flip Update bit ($wording) for " . $message, "OPER" );
	}
	elsif ( defined($cdn) && defined($cachegroup) ) {
		my @profiles;
		if ( $cdn ne "all" ) {
			@profiles = $self->db->resultset('Server')->search(
				{ 'cdn.name' => $cdn },
				{
					prefetch => 'cdn',
					select   => 'me.profile',
					distinct => 1
				}
			)->get_column('profile')->all();
		}
		else {
			@profiles = $self->db->resultset('Profile')->search(undef)->get_column('id')->all;
		}
		my @cachegroups;
		if ( $cachegroup ne "all" ) {
			@cachegroups = $self->db->resultset('Cachegroup')->search( { name => $cachegroup } )->get_column('id')->all;
		}
		else {
			@cachegroups = $self->db->resultset('Cachegroup')->search(undef)->get_column('id')->all;
		}
		my $update = $self->db->resultset('Server')->search(
			{
				-and => [
					cachegroup => { -in => \@cachegroups },
					profile    => { -in => \@profiles }
				]
			}
		);

		if ( $update->count() > 0 ) {
			$update->update( { upd_pending => $setqueue } );
			$self->app->log->debug("Flip Update bit ($wording) for servers in CDN: $cdn, Cachegroup: $cachegroup");
			&log( $self, "Flip Update bit ($wording) for servers in CDN:" . $cdn . " cachegroup:" . $cachegroup, "OPER" );
		}
		else {
			$self->app->log->debug("No Queue Updates for servers in CDN: $cdn, Cachegroup: $cachegroup");
		}
	}

	return;
}

1;
