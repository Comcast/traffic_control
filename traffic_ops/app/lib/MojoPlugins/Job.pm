package MojoPlugins::Job;

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
use Mojo::Base 'Mojolicious::Plugin';
use Data::Dumper;
use Carp qw(cluck confess);
use Data::Dumper;
use POSIX qw(strftime);
use UI::Utils;

use constant PENDING   => 1;
use constant PROGRESS  => 2;
use constant COMPLETED => 3;
use constant CANCELLED => 4;

sub register {
	my ( $self, $app, $conf ) = @_;

	$app->renderer->add_helper(
		snapshot_regex_revalidate => sub {
			my $self = shift;

			my $rs =
				$self->db->resultset('Server')
				->search( undef,
				{ prefetch => [ { 'cdn' => undef }, { 'cachegroup' => undef }, { 'type' => undef }, { 'profile' => undef }, { 'status' => undef } ], } );

			my $m_scheme         = $self->req->url->base->scheme;
			my $m_host           = $self->req->url->base->host;
			my $m_port           = $self->req->url->base->port;
			my $re_reval_cfg_url = $m_scheme . "://" . $m_host . ":" . $m_port . "/genfiles/view/__SVR__/regex_revalidate.config";
			my %cdn_domain;

			while ( my $row = $rs->next ) {
				next unless $row->status->name eq 'REPORTED';

				my $cdn_name = $row->cdn->name;
				if ( defined( $cdn_domain{$cdn_name} ) ) {
					next;
				}
				$cdn_domain{$cdn_name} = 1;
				my $text = UI::ConfigFiles::regex_revalidate_dot_config( $self, $row->id, "regex_revalidate.config" );

				my $snapshot_rs =
					$self->db->resultset('Parameter')->search( { name => "snapshot_dir" }, { config_file => "regex_revalidate.config" } )->single();
				my $dir = $snapshot_rs->value . $cdn_name;
				if ( !-d $dir ) {
					`mkdir -p $dir`;
				}
				my $config_file = $dir . "/regex_revalidate.config";
				open my $fh, '>', $config_file;
				if ( $! && $! !~ m/Inappropriate ioctl for device/ ) {
					my $e = Mojo::Exception->throw("$! when opening $config_file");
				}
				print $fh $text;
				close($fh);
			}
		}
	);

	$app->renderer->add_helper(

		# set the update bit for all the Caches in the CDN of this delivery service.
		set_update_server_bits => sub {
			my $self  = shift;
			my $ds_id = shift;

			my $cdn_id = $self->db->resultset('Deliveryservice')->search( { 'me.id' => $ds_id } )->get_column('cdn_id')->single();

			my @offstates;
			my $offline = $self->db->resultset('Status')->search( { 'name' => 'OFFLINE' } )->get_column('id')->single();
			if ($offline) {
				push( @offstates, $offline );
			}
			my $pre_prod = $self->db->resultset('Status')->search( { 'name' => 'PRE_PROD' } )->get_column('id')->single();
			if ($pre_prod) {
				push( @offstates, $pre_prod );
			}

			my $update_server_bit_rs = $self->db->resultset('Server')->search(
				{
					'me.cdn_id' => $cdn_id,
					-and        => { status => { 'not in' => \@offstates } }
				}
			);
			my $result = $update_server_bit_rs->update( { upd_pending => 1 } );
			&log( $self, "Set upd_pending = 1 for all applicable caches", "OPER" );
		}
	);

	$app->renderer->add_helper(
		job_data => sub {
			my $self = shift;
			my $dbh  = shift;

			my @data;
			while ( my $row = $dbh->next ) {
				push(
					@data, {
						id           => $row->id,
						agent        => $row->agent->name,
						object_type  => $row->object_type,
						object_name  => $row->object_name,
						entered_time => $row->entered_time,
						keyword      => $row->keyword,
						parameters   => $row->parameters,
						asset_url    => $row->asset_url,
						asset_type   => $row->asset_type,
						status       => $row->status->name,
						username     => $row->job_user->username,
						start_time   => $row->start_time,
					}
				);
			}
			return \@data;
		}
	);

	$app->renderer->add_helper(
		job_ds_data => sub {
			my $self = shift;
			my $dbh  = shift;

			my @data;
			while ( my $row = $dbh->next ) {
				push(
					@data, {
						id           => $row->id,
						agent        => $row->agent->name,
						object_type  => $row->object_type,
						object_name  => $row->object_name,
						entered_time => $row->entered_time,
						keyword      => $row->keyword,
						parameters   => $row->parameters,
						asset_url    => $row->asset_url,
						asset_type   => $row->asset_type,
						status       => $row->status->name,
						username     => $row->job_user->username,
						start_time   => $row->start_time,
						ds_id        => $row->job_deliveryservice->id,
						ds_xml_id    => $row->job_deliveryservice->xml_id,
					}
				);
			}
			return \@data;
		}
	);

	$app->renderer->add_helper(
		create_new_job => sub {
			my $self       = shift;
			my $ds_id      = shift;
			my $regex      = shift;
			my $start_time = shift;
			my $ttl        = shift || '';
			my $keyword    = shift || 'PURGE';
			my $urgent     = shift;

			# Defaulted parameters
			my $parameters  = shift;
			my $asset_type  = shift || 'file';
			my $status      = shift || 1;
			my $object_type = shift;
			my $object_name = shift;

			if ( !defined($parameters) || $parameters eq "" ) {
				if ( defined($ttl) && $ttl =~ m/^\d/ ) {
					$parameters = "TTL:" . $ttl . 'h';
				}
			}

			## Calculate start time
			# Convert to unix time and give a default value if not specified
			if ( !defined($start_time) || $start_time eq "" ) {
				$start_time = time();
			}
			else {
				my $dh = new Utils::Helper::DateHelper();
				$start_time = $dh->date_to_epoch($start_time);
			}

			# add 60s if not urgent
			if ( !defined $urgent ) {
				$start_time = $start_time + 60;
			}
			my $start_time_gmt = strftime( "%Y-%m-%d %H:%M:%S", gmtime($start_time) );
			my $entered_time   = strftime( "%Y-%m-%d %H:%M:%S", gmtime() );

			my $org_server_fqdn = $self->db->resultset("Deliveryservice")->search( { id => $ds_id } )->get_column('org_server_fqdn')->single();

			my $tm_user_id = $self->db->resultset('TmUser')->search( { username => $self->current_user()->{username} } )->get_column('id')->single();

			$regex =~ m/(^\/.+)/ ? $org_server_fqdn = $org_server_fqdn . "/$regex" : $org_server_fqdn = $org_server_fqdn . "$regex";
			my $insert = $self->db->resultset('Job')->create(
				{
					agent               => 1,
					object_type         => $object_type,
					object_name         => $object_name,
					entered_time        => $entered_time,
					keyword             => $keyword,
					parameters          => $parameters,
					asset_url           => $org_server_fqdn,
					asset_type          => $asset_type,
					status              => $status,
					job_user            => $tm_user_id,
					start_time          => $start_time_gmt,
					job_deliveryservice => $ds_id,
				}
			);

			my $new_record = $insert->insert();

			&log( $self, "Created new Purge Job " . $ds_id . " forced new regex_revalidate.config snapshot", "APICHANGE" );
			$self->snapshot_regex_revalidate();
			$self->set_update_server_bits($ds_id);
			return $new_record->id;
		}
	);

	$app->renderer->add_helper(
		check_job_auth => sub {
			my $self       = shift;
			my $tm_user_id = shift;
			my $asset      = shift;
			if ( &is_admin($self) ) {
				return 1;
			}
			else {

				my $rs_ds_ids = $self->db->resultset('DeliveryserviceTmuser')->search( { tm_user_id => $tm_user_id } );
				my $rs_ds = $self->db->resultset('Deliveryservice')->search( { id => { -in => $rs_ds_ids->get_column('deliveryservice')->as_query } } );

				my ( $scheme, $asset_hostname, $path, $query, $fragment ) = $asset =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;

				while ( my $ds_row = $rs_ds->next ) {
					my $org_server_fqdn = $ds_row->org_server_fqdn;
					if ( defined($org_server_fqdn) && $asset =~ /$org_server_fqdn/ ) {
						return 1;    # Success
					}
				}
				return 0;            # Fail
			}
		}
	);
}

1;
