package UI::Cdn;

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
use UI::ConfigFiles;
use Date::Manip;
use JSON;

# Yes or no
my %yesno = ( 0 => "no", 1 => "yes", 2 => "no" );

sub aprofileparameter {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs;
	if ( defined( $self->param('filter') ) ) {
		my $col = $self->param('filter');
		my $val = $self->param('value');

		# print "col: $col and val: $val \n";
		my $p_id = &profile_id( $self, $val );
		$rs = $self->db->resultset('Parameter')->search(
			{ $col => $p_id },
			{
				join        => [ { 'profile_parameters' => 'parameter' }, { 'profile_parameters' => 'profile' }, ],
				'+select'   => ['profile.name'],
				'+as'       => ['profile_name'],
				'+order_by' => ['profile.name'],
				distinct    => 1,
			}
		);
	}
	else {
		$rs = $self->db->resultset('Parameter')->search(
			undef, {
				join        => [ { 'profile_parameters' => 'parameter' }, { 'profile_parameters' => 'profile' }, ],
				'+select'   => ['profile.name'],
				'+as'       => ['profile_name'],
				'+order_by' => ['profile.name'],
				distinct    => 1,
			}
		);

	}

	while ( my $row = $rs->next ) {
		my @line;
		@line = [ $row->id, $row->{_column_data}->{profile_name}, $row->name, $row->config_file, $row->value ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub aparameter {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $col = undef;
	my $val = undef;

	if ( defined( $self->param('filter') ) ) {
		$col = $self->param('filter');
		$val = $self->param('value');
	}

	my $rs = undef;
	if ( $col eq 'profile' and $val eq 'ORPHANS' ) {
		my $lindked_profile_rs    = $self->db->resultset('ProfileParameter')->search(undef);
		my $lindked_cachegroup_rs = $self->db->resultset('CachegroupParameter')->search(undef);
		$rs = $self->db->resultset('Parameter')->search(
			{
				-and => [
					id => { -not_in => $lindked_profile_rs->get_column('parameter')->as_query },
					id => { -not_in => $lindked_cachegroup_rs->get_column('parameter')->as_query }
				]
			}
		);
		while ( my $row = $rs->next ) {
			my @line = [ $row->id, "NONE", $row->name, $row->config_file, $row->value, "profile" ];
			push( @{ $data{'aaData'} }, @line );
		}
		$rs = undef;
	}
	elsif ( $col eq 'profile' && $val ne 'all' ) {
		my $p_id = &profile_id( $self, $val );
		$rs = $self->db->resultset('ProfileParameter')->search( { $col => $p_id }, { prefetch => [ { 'parameter' => undef }, { 'profile' => undef } ] } );
	}
	elsif ( !defined($col) || ( $col eq 'profile' && $val eq 'all' ) ) {
		$rs = $self->db->resultset('ProfileParameter')->search( undef, { prefetch => [ { 'parameter' => undef }, { 'profile' => undef } ] } );
	}

	if ( defined($rs) ) {
		while ( my $row = $rs->next ) {
			my @line = [ $row->parameter->id, $row->profile->name, $row->parameter->name, $row->parameter->config_file, $row->parameter->value, "profile" ];
			push( @{ $data{'aaData'} }, @line );
		}
	}

	$rs = undef;
	if ( $col eq 'cachegroup' && $val ne 'all' ) {
		my $l_id = $self->db->resultset('Cachegroup')->search( { short_name => $val } )->get_column('id')->single();
		$rs =
			$self->db->resultset('CachegroupParameter')
			->search( { $col => $l_id }, { prefetch => [ { 'parameter' => undef }, { 'cachegroup' => undef } ] } );
	}
	elsif ( !defined($col) || ( $col eq 'cachegroup' && $val eq 'all' ) ) {
		$rs = $self->db->resultset('CachegroupParameter')->search( undef, { prefetch => [ { 'parameter' => undef }, { 'cachegroup' => undef } ] } );
	}

	if ( defined($rs) ) {
		while ( my $row = $rs->next ) {
			my @line =
				[ $row->parameter->id, $row->cachegroup->name, $row->parameter->name, $row->parameter->config_file, $row->parameter->value, "cachegroup" ];
			push( @{ $data{'aaData'} }, @line );
		}
	}

	$self->render( json => \%data );
}

sub aserver {
	my $self          = shift;
	my $server_select = shift;
	my %data          = ( "aaData" => undef );

	my $rs = $self->db->resultset('Server')->search( undef, { prefetch => [ 'cachegroup', 'type', 'profile', 'status', 'phys_location' ] } );
	while ( my $row = $rs->next ) {

		my @line;
		if ($server_select) {
			@line = [ $row->id, $row->host_name, $row->domain_name, $row->ip_address, $row->type->name, $row->profile->name ];
		}
		else {
			my $aux_url = "";
			my $img     = "";

			if ( $row->type->name eq "MID" || $row->type->name eq "EDGE" ) {
				$aux_url = "/visualstatus/all:" . $row->cachegroup->name . ":" . $row->host_name;
				$img     = "graph.png";
			}
			elsif ( $row->type->name eq "CCR" ) {
				my $rs_param =
					$self->db->resultset('Parameter')
					->search( { 'profile_parameters.profile' => $row->profile->id, 'name' => 'api.port' }, { join => 'profile_parameters' } );
				my $r = $rs_param->single;
				my $port = ( defined($r) && defined( $r->value ) ) ? $r->value : 80;
				$aux_url = "http://" . $row->host_name . "." . $row->domain_name . ":" . $port . "/crs/stats";
				$img     = "info.png";
			}
			elsif ( $row->type->name eq "RASCAL" ) {
				$aux_url = "http://" . $row->host_name . "." . $row->domain_name . "/";
				$img     = "info.png";
			}
			elsif ( $row->type->name eq "REDIS" ) {
				$aux_url = "/redis/info/" . $row->host_name;
				$img     = "info.png";
			}

			@line = [
				$row->id,                  $row->host_name,       $row->domain_name, "dummy",            $row->cachegroup->name,
				$row->phys_location->name, $row->ip_address,      $row->ip6_address, $row->status->name, $row->profile->name,
				$row->ilo_ip_address,      $row->mgmt_ip_address, $row->type->name,  $aux_url,           $img
			];
		}
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub aasn {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs = $self->db->resultset('Asn')->search( undef, { prefetch => [ { 'cachegroup' => 'cachegroups' }, ] } );

	while ( my $row = $rs->next ) {

		my @line = [ $row->id, $row->cachegroup->name, $row->asn, $row->last_updated ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub aphys_location {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs = $self->db->resultset('PhysLocation')->search( undef, { prefetch => ['region'] } );

	while ( my $row = $rs->next ) {

		next if $row->short_name eq 'UNDEF';

		my @line = [ $row->id, $row->name, $row->short_name, $row->address, $row->city, $row->state, $row->region->name, $row->last_updated ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub adeliveryservice {
	my $self       = shift;
	my %data       = ( "aaData" => undef );
	my %geo_limits = ( 0 => "none", 1 => "CZF", 2 => "CZF + US" );
	my %protocol   = ( 0 => "http", 1 => "https", 2 => "http/https" );

	my $rs = $self->db->resultset('Deliveryservice')->search(
		{ 'parameter.name' => 'CDN_name' },
		{
			prefetch => [ 'type', { profile               => { profile_parameters => 'parameter' } } ],
			join     => { profile => { profile_parameters => 'parameter' } },
			distinct => 1
		}
	);

	while ( my $row = $rs->next ) {

		my $related_rs = $row->profile->profile_parameters->related_resultset('parameter');
		my $related    = $related_rs->next;
		my @line       = [
			$row->id,                    $row->xml_id,                         $row->org_server_fqdn,        $related->value,
			$row->profile->name,         $row->ccr_dns_ttl,                    $yesno{ $row->active },       $row->type->name,
			$row->dscp,                  $yesno{ $row->signed },               $row->qstring_ignore,         $geo_limits{ $row->geo_limit },
			$protocol{ $row->protocol }, $yesno{ $row->ipv6_routing_enabled }, $row->range_request_handling, $row->http_bypass_fqdn,
			$row->dns_bypass_ip,         $row->dns_bypass_ip6,                 $row->dns_bypass_cname,       $row->dns_bypass_ttl,
			$row->miss_lat,              $row->miss_long,                      $row->initial_dispersion,
		];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub ahwinfo {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs;
	if ( defined( $self->param('filter') ) && defined( $self->param('value') ) && $self->param('value') ne "all" ) {
		my $col = $self->param('filter');
		my $val = $self->param('value');
		$rs = $self->db->resultset('Hwinfo')->search( { $col => $val }, { prefetch => ['serverid'] } );
	}
	else {
		$rs = $self->db->resultset('Hwinfo')->search( undef, { prefetch => ['serverid'] } );
	}
	while ( my $row = $rs->next ) {
		my @line = [ $row->serverid->id, $row->serverid->host_name . "." . $row->serverid->domain_name, $row->description, $row->val, $row->last_updated ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub ajob {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs =
		$self->db->resultset('Job')
		->search( undef, { prefetch => [ { 'ext_user' => undef }, { agent => undef }, { status => undef } ], order_by => { -desc => 'me.entered_time' } } );

	while ( my $row = $rs->next ) {

		my @line = [ $row->id, $row->ext_user->name, $row->asset_url, $row->asset_type, $row->entered_time, $row->status->name, $row->last_updated ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub aextuser {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs = $self->db->resultset('ExtUser');

	while ( my $row = $rs->next ) {

		my @line = [ $row->id, $row->username, $row->company, $row->name, $row->email, $row->phone, $row->last_updated ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub alog {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $interval = "> now() - interval '30 day'";    # postgres
	if ( $self->db->storage->isa("DBIx::Class::Storage::DBI::mysql") ) {
		$interval = "> now() - interval 30 day";
	}
	my $rs = $self->db->resultset('Log')->search( { 'me.last_updated' => \$interval },
		{ prefetch => [ { 'tm_user' => undef } ], order_by => { -desc => 'me.last_updated' }, rows => 1000 } );

	while ( my $row = $rs->next ) {

		my @line = [ $row->last_updated, $row->level, $row->message, $row->tm_user->username, $row->ticketnum ];
		push( @{ $data{'aaData'} }, @line );
	}

	# setting cookie here, because the HTML page is often cached.
	my $date_string = `date "+%Y-%m-%d% %H:%M:%S"`;
	chomp($date_string);
	$self->cookie( last_seen_log => $date_string, { path => "/", max_age => 604800 } );    # expires in a week.
	$self->render( json => \%data );
}

sub acachegroup {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my %id_to_name = ();
	my $rs = $self->db->resultset('Cachegroup')->search( undef, { prefetch => [ { 'type' => undef } ] } );
	while ( my $row = $rs->next ) {
		$id_to_name{ $row->id } = $row->name;
	}

	$rs = $self->db->resultset('Cachegroup')->search( undef, { prefetch => [ { 'type' => undef } ] } );

	while ( my $row = $rs->next ) {
		my @line = [
			$row->id, $row->name, $row->short_name, $row->type->name, $row->latitude, $row->longitude,
			defined( $row->parent_cachegroup_id ) ? $id_to_name{ $row->parent_cachegroup_id } : undef,
			$row->last_updated
		];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub auser {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs = $self->db->resultset('TmUser')->search( undef, { prefetch => [ { 'role' => undef } ] } );

	while ( my $row = $rs->next ) {

		my @line = [
			$row->id,           $row->username, $row->role->name, $row->full_name,  $row->company,  $row->email,
			$row->phone_number, $row->uid,      $row->gid,        $row->local_user, $row->new_user, $row->last_updated
		];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub aprofile {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs = $self->db->resultset('Profile')->search(undef);

	while ( my $row = $rs->next ) {

		my @line = [ $row->id, $row->name, $row->name, $row->description, $row->last_updated ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub atype {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs = $self->db->resultset('Type')->search(undef);

	while ( my $row = $rs->next ) {
		my @line = [ $row->id, $row->name, $row->description, $row->use_in_table, $row->last_updated ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub adivision {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs = $self->db->resultset('Division')->search(undef);

	while ( my $row = $rs->next ) {
		my @line = [ $row->id, $row->name, $row->last_updated ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

sub aregion {
	my $self = shift;
	my %data = ( "aaData" => undef );

	my $rs = $self->db->resultset('Region')->search( undef, { prefetch => [ { 'division' => undef } ] } );

	while ( my $row = $rs->next ) {
		my @line = [ $row->id, $row->name, $row->division->name, $row->last_updated ];
		push( @{ $data{'aaData'} }, @line );
	}
	$self->render( json => \%data );
}

# TODO JvD: should really make all these lower case URLs. Mixed case URLs suck.
sub aadata {
	my $self  = shift;
	my $table = $self->param('table');

	if ( $table eq 'Serverstatus' ) {
		&aserverstatus($self);
	}
	elsif ( $table eq 'ProfileParameter' ) {
		&aprofileparameter($self);
	}
	elsif ( $table eq 'Server' ) {
		&aserver( $self, 0 );
	}
	elsif ( $table eq 'Asn' ) {
		&aasn($self);
	}
	elsif ( $table eq 'Deliveryservice' ) {
		&adeliveryservice($self);
	}
	elsif ( $table eq 'Hwinfo' ) {
		&ahwinfo($self);
	}
	elsif ( $table eq 'ServerSelect' ) {
		&aserver( $self, 1 );
	}
	elsif ( $table eq 'Log' ) {
		&alog($self);
	}
	elsif ( $table eq 'Extuser' ) {
		&aextuser($self);
	}
	elsif ( $table eq 'Job' ) {
		&ajob($self);
	}
	elsif ( $table eq 'Cachegroup' ) {
		&acachegroup($self);
	}
	elsif ( $table eq 'Type' ) {
		&atype($self);
	}
	elsif ( $table eq 'User' ) {
		&auser($self);
	}
	elsif ( $table eq 'Profile' ) {
		&aprofile($self);
	}
	elsif ( $table eq 'Parameter' ) {
		&aparameter($self);
	}
	elsif ( $table eq 'Physlocation' ) {
		&aphys_location($self);
	}
	elsif ( $table eq 'Division' ) {
		&adivision($self);
	}
	elsif ( $table eq 'Region' ) {
		&aregion($self);
	}

	else {
		$self->render( text => "Traffic Ops error, something is not configured properly." );
	}
}

sub snapshot_crconfig {
	my $self          = shift;
	my $cdn_name      = $self->param('cdnname');
	my $crconfig_path = "../public/CRConfig-Snapshots/$cdn_name";
	my $prev_crconfig = "$crconfig_path/CRConfig.xml";
	my $tm_text;

	if ( !( -d $crconfig_path ) ) {
		`mkdir -p $crconfig_path`;
		if ( !( -d $crconfig_path ) ) {
			$self->render( text => "Directory $crconfig_path still doesn't exist! " );
		}
	}
	my $cdnname_param_id = $self->db->resultset('Parameter')->search( { name => 'CDN_name', value => $cdn_name } )->get_column('id')->single();
	if ( defined($cdnname_param_id) ) {
		my @profiles = $self->db->resultset('ProfileParameter')->search( { parameter => $cdnname_param_id } )->get_column('profile')->all();
		if ( scalar(@profiles) ) {
			my $ccr_profile_id =
				$self->db->resultset('Profile')->search( { id => { -in => \@profiles }, name => { -like => 'CCR%' } } )->get_column('id')->single();
			if ( defined($ccr_profile_id) ) {
				$tm_text = Configfiles::gen_ccr_xml_file( $self, $ccr_profile_id );
				if ( !( -e $prev_crconfig ) ) {
					open my $fh, '>', "$crconfig_path/CRConfig.xml" || $self->render( text => "Could not open file: $crconfig_path/CRConfig.xml" );
					print $fh $tm_text;
					close $fh;
				}
			}
			else {
				$self->render( text => "No CCR profile found in profile IDs: @profiles " );
			}
		}
		else {
			$self->render( text => "No profiles found for CDN_name: " . $cdn_name );
		}
	}
	else {
		$self->render( text => "Parameter ID not found for CDN_name: " . $cdn_name );
	}

	my $prev_crconfig_text = "";
	my $ccr_profile_id;
	open my $prev_fh, '<', $prev_crconfig || die $self->render( text => "Previous CRConfig $prev_crconfig doesn't exist! " );
	$prev_crconfig_text = do { local $/; <$prev_fh> };
	close($prev_fh);

	my $diff .= Configfiles::diff_ccr_files( $self, $tm_text, $prev_crconfig_text );
	( my @diff_lines ) = split( /\n/, $diff );
	my @clean_lines;
	foreach my $line (@diff_lines) {
		$line =~ s/<b>//g;
		$line =~ s/<\/b>//g;
		push( @clean_lines, $line );
	}
	$self->stash(
		diff     => \@clean_lines,
		cdn_name => $cdn_name,
		tm_text  => $tm_text,
	);
}

#### JvD Start new UI stuff
sub loginpage {
	my $self = shift;
	$self->render( layout => undef );
}

# don't call this logout... recurses
sub logoutclicked {
	my $self = shift;

	$self->logout();
	return $self->redirect_to('/loginpage');
}

sub login {
	my $self = shift;

	my ( $u, $p ) = ( $self->req->param('u'), $self->req->param('p') );
	my $result = $self->authenticate( $u, $p );

	if ($result) {
		my $referer = $self->req->headers->header('referer');
		if ( !defined($referer) ) {
			$referer = '/';
		}
		if ( $referer =~ /\/login/ ) {
			$referer = '/edge_health';
		}
		return $self->redirect_to($referer);
	}
	else {
		$self->flash( login_msg => "Invalid username or password, please try again." );
		return $self->redirect_to('/loginpage');
	}
}

sub options {
	my $self = shift;

	# this essentially serves a blank page; options are in the HTTP header in Cdn.pm
	$self->res->headers->content_type("text/plain");
	$self->render( template => undef, layout => undef, text => "", status => 200 );
}

1;
