package API::User;
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
use Digest::SHA1 qw(sha1_hex);
use Mojolicious::Validator;
use Mojolicious::Validator::Validation;
use Data::Dumper;
use Test::More;
use Email::Valid;
use Utils::Helper::ResponseHelper;
use Validate::Tiny ':all';
use UI::ConfigFiles;
use UI::Tools;

sub login {
	my $self    = shift;
	my $options = shift;

	my $u     = $self->req->json->{u};
	my $p     = $self->req->json->{p};
	my $token = $options->{'token'};

	my $result = $self->authenticate( $u, $p, $options );
	if ($result) {
		return $self->success_message("Successfully logged in.");
	}
	elsif ( defined($token) ) {
		return $self->invalid_token;
	}
	else {
		return $self->invalid_username_or_password;
	}
}

sub token_login {
	my $self = shift;

	my $token = $self->req->json->{t};
	return $self->login( { token => $token } );
}

# Read
sub index {
	my $self = shift;
	my @data;
	my $orderby = "username";
	$orderby = $self->param('orderby') if ( defined $self->param('orderby') );
	my $dbh = $self->db->resultset("TmUser")->search( undef, { prefetch => [ { 'role' => undef } ], order_by => 'me.' . $orderby } );
	while ( my $row = $dbh->next ) {
		push(
			@data, {
				"id"              => $row->id,
				"username"        => $row->username,
				"role"            => $row->role->id,
				"uid"             => $row->uid,
				"gid"             => $row->gid,
				"rolename"        => $row->role->name,
				"company"         => $row->company,
				"email"           => $row->email,
				"fullName"        => $row->full_name,
				"newUser"         => \$row->new_user,
				"localUser"       => \1,
				"addressLine1"    => $row->address_line1,
				"addressLine2"    => $row->address_line2,
				"city"            => $row->city,
				"stateOrProvince" => $row->state_or_province,
				"phoneNumber"     => $row->phone_number,
				"postalCode"      => $row->postal_code,
				"country"         => $row->country,
			}
		);
	}
	$self->render( json => \@data );
}

# Reset the User Profile password
sub reset_password {
	my $self     = shift;
	my $email_to = $self->req->json->{email};
	my $dbh      = $self->db->resultset('TmUser')->find( { email => $email_to } );
	if ( defined($dbh) ) {

		my $email_notice = 'Successfully sent reset password to: ' . $email_to;
		$self->app->log->info($email_notice);

		my $token = Data::GUID->new;
		if ( $self->send_password_reset_email( $email_to, $token ) ) {
			$self->update_user_token( $email_to, $token );
		}

		return $self->success_message( "Successfully sent password reset to email '" . $email_to . "'" );
	}
	else {
		return $self->alert( { "Email not found " => "'" . $email_to . "'" } );
	}

}

sub get_available_deliveryservices {
	my $self = shift;
	my @data;
	my $id = $self->param('id');
	my %dsids;
	my %takendsids;

	my $rs_takendsids = undef;
	$rs_takendsids = $self->db->resultset("DeliveryserviceTmuser")->search( { 'tm_user_id' => $id } );

	while ( my $row = $rs_takendsids->next ) {
		$takendsids{ $row->deliveryservice->id } = undef;
	}

	my $rs_links = $self->db->resultset("Deliveryservice")->search( undef, { order_by => "xml_id" } );
	while ( my $row = $rs_links->next ) {
		if ( !exists( $takendsids{ $row->id } ) ) {
			push( @data, { "id" => $row->id, "xmlId" => $row->xml_id } );
		}
	}

	$self->success( \@data );
}

# Read the current user profile and produce the result
sub current {
	my $self = shift;
	my @data;
	my $current_username = $self->current_user()->{username};

	if ( &is_ldap($self) ) {
		my $role = $self->db->resultset('Role')->search( { name => "read-only" } )->get_column('id')->single;
		push(
			@data, {
				"id"              => "0",
				"username"        => $current_username,
				"role"            => $role,
				"uid"             => "0",
				"gid"             => "0",
				"company"         => "",
				"email"           => "",
				"fullName"        => "",
				"newUser"         => \0,
				"localUser"       => \0,
				"addressLine1"    => "",
				"addressLine2"    => "",
				"city"            => "",
				"stateOrProvince" => "",
				"phoneNumber"     => "",
				"postalCode"      => "",
				"country"         => "",
			}
		);

		return $self->success( @data );
	}
	else {
		my $dbh = $self->db->resultset('TmUser')->search( { username => $current_username } );
		while ( my $row = $dbh->next ) {
			push(
				@data, {
					"id"              => $row->id,
					"username"        => $row->username,
					"role"            => $row->role->id,
					"uid"             => $row->uid,
					"gid"             => $row->gid,
					"company"         => $row->company,
					"email"           => $row->email,
					"fullName"        => $row->full_name,
					"newUser"         => \$row->new_user,
					"localUser"       => \1,
					"addressLine1"    => $row->address_line1,
					"addressLine2"    => $row->address_line2,
					"city"            => $row->city,
					"stateOrProvince" => $row->state_or_province,
					"phoneNumber"     => $row->phone_number,
					"postalCode"      => $row->postal_code,
					"country"         => $row->country,
				}
			);
		}
		return $self->success(@data);
	}
}

# Update
sub update_current {
	my $self = shift;

	my $user = $self->req->json->{user};
	if ( &is_ldap($self) ) {
		return $self->alert("Profile cannot be updated because '" . $user->{username} ."' is logged in as LDAP.");
	}

	my $db_user;

	# Prevent these from getting updated
	# Do not modify the localPasswd if it comes across as blank.
	my $local_passwd = $user->{"localPasswd"};
	if ( defined($local_passwd) && ( $local_passwd eq '' ) ) {
		delete( $user->{"localPasswd"} );
	}

	# Do not modify the confirmLocalPasswd if it comes across as blank.
	my $confirm_local_passwd = $user->{"confirmLocalPasswd"};
	if ( defined($confirm_local_passwd) && ( $confirm_local_passwd eq '' ) ) {
		delete( $user->{"confirmLocalPasswd"} );
	}

	my ( $is_valid, $result ) = $self->is_valid($user);

	if ($is_valid) {
		my $username = $self->current_user()->{username};
		my $dbh = $self->db->resultset('TmUser')->find( { username => $username } );

		# Updating a user implies it is no longer new
		$db_user->{"new_user"} = 0;

		# These if "defined" checks allow for partial user updates, otherwise the entire
		# user would need to be passed through.
		if ( defined($local_passwd) && $local_passwd ne '' ) {
			$db_user->{"local_passwd"} = sha1_hex($local_passwd);
		}
		if ( defined($confirm_local_passwd) && $confirm_local_passwd ne '' ) {
			$db_user->{"confirm_local_passwd"} = sha1_hex($confirm_local_passwd);
		}
		if ( defined( $user->{"id"} ) ) {
			$db_user->{"id"} = $user->{"id"};
		}
		if ( defined( $user->{"username"} ) ) {
			$db_user->{"username"} = $user->{"username"};
		}
		if ( &is_admin($self) && defined( $user->{"role"} ) ) {
			$db_user->{"role"} = $user->{"role"};
		}
		if ( defined( $user->{"uid"} ) ) {
			$db_user->{"uid"} = $user->{"uid"};
		}
		if ( defined( $user->{"gid"} ) ) {
			$db_user->{"gid"} = $user->{"gid"};
		}
		if ( defined( $user->{"company"} ) ) {
			$db_user->{"company"} = $user->{"company"};
		}
		if ( defined( $user->{"email"} ) ) {
			$db_user->{"email"} = $user->{"email"};
		}
		if ( defined( $user->{"fullName"} ) ) {
			$db_user->{"full_name"} = $user->{"fullName"};
		}
		if ( defined( $user->{"newUser"} ) ) {
			$db_user->{"new_user"} = $user->{"newUser"};
		}
		if ( defined( $user->{"addressLine1"} ) ) {
			$db_user->{"address_line1"} = $user->{"addressLine1"};
		}
		if ( defined( $user->{"addressline2"} ) ) {
			$db_user->{"address_line2"} = $user->{"addressLine2"};
		}
		if ( defined( $user->{"city"} ) ) {
			$db_user->{"city"} = $user->{"city"};
		}
		if ( defined( $user->{"stateOrProvince"} ) ) {
			$db_user->{"state_or_province"} = $user->{"stateOrProvince"};
		}
		if ( defined( $user->{"phoneNumber"} ) ) {
			$db_user->{"phone_number"} = $user->{"phoneNumber"};
		}
		if ( defined( $user->{"postalCode"} ) ) {
			$db_user->{"postal_code"} = $user->{"postalCode"};
		}
		if ( defined( $user->{"country"} ) ) {
			$db_user->{"country"} = $user->{"country"};
		}
		$dbh->update($db_user);
		return $self->success_message("UserProfile was successfully updated.");
	}
	else {
		return $self->alert($result);
	}
}

sub is_valid {
	my $self = shift;
	my $user = shift;

	my $rules = {
		fields => [
			qw/fullName username email role uid gid localPasswd confirmLocalPasswd company newUser addressLine1 addressLine2 city stateOrProvince phoneNumber postalCode country/
		],

		# Checks to perform on all fields
		checks => [

			# All of these are required
			[qw/full_name username email/] => is_required("is required"),

			# pass2 must be equal to pass
			localPasswd => sub {
				my $value  = shift;
				my $params = shift;
				if ( defined( $params->{'localPasswd'} ) ) {
					return $self->is_good_password( $value, $params );
				}
			},

			# pass2 must be equal to pass
			email => sub {
				my $value  = shift;
				my $params = shift;
				if ( defined( $params->{'email'} ) ) {
					return $self->is_email_taken( $value, $params );
				}
			},

			# custom sub validates an email address
			email => sub {
				my ( $value, $params ) = @_;
				Email::Valid->address($value) ? undef : 'email is not a valid format';
			},

			# pass2 must be equal to pass
			username => sub {
				my $value  = shift;
				my $params = shift;
				if ( defined( $params->{'username'} ) ) {
					return $self->is_username_taken( $value, $params );
				}
			},

		]
	};

	# Validate the input against the rules
	my $result = validate( $user, $rules );

	if ( $result->{success} ) {

		#print "success: " . dump( $result->{data} );
		return ( 1, $result->{data} );
	}
	else {
		#print "failed " . Dumper( $result->{error} );
		return ( 0, $result->{error} );
	}

}

sub is_username_taken {
	my $self     = shift;
	my $username = shift;
	my $params   = shift;

	my $dbh = $self->db->resultset('TmUser')->search( { username => $username } );
	my $user_data = $dbh->single;
	if ( defined($user_data) ) {
		my $user_id = $user_data->id;

		# Allow the current user to be modified
		my $current_user = $self->db->resultset('TmUser')->search( { username => $self->current_user()->{username} } )->single;
		my $current_userid = $current_user->id;

		my %condition = ( -and => [ { username => $username }, { id => { '!=' => $current_userid } } ] );
		my $count = $self->db->resultset('TmUser')->search( \%condition )->count();

		if ( $count > 0 ) {
			return "is already taken";
		}
	}

	return undef;
}

sub is_email_taken {
	my $self   = shift;
	my $email  = shift;
	my $params = shift;

	my $dbh = $self->db->resultset('TmUser')->search( { email => $email } );
	my $user_data = $dbh->single;
	if ( defined($user_data) ) {
		my $user_id = $user_data->id;

		# Allow the current user to be modified
		my $current_user = $self->db->resultset('TmUser')->search( { username => $self->current_user()->{username} } )->single;
		my $current_userid = $current_user->id;

		my %condition = ( -and => [ { email => $email }, { id => { '!=' => $current_userid } } ] );
		my $count = $self->db->resultset('TmUser')->search( \%condition )->count();

		if ( $count > 0 ) {
			return "is already taken";
		}
	}

	return undef;
}

sub is_good_password {
	my $self   = shift;
	my $value  = shift;
	my $params = shift;
	if ( !defined $value or $value eq '' ) {
		return undef;
	}

	if ( $value ne $params->{'confirmLocalPasswd'} ) {
		return "Your 'New Password' must match the 'Confirm New Password'.";
	}

	if ( $value eq $params->{'username'} ) {
		return "Your password cannot be the same as your username.";
	}

	if ( ( $value ne '' ) && $value !~ qr/^.{8,100}$/ ) {
		return "Password must be greater than 7 chars.";
	}

	# At this point we're happy with the password
	return undef;
}

1;
