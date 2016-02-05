package TrafficOps;

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

use Mojo::Base 'Mojolicious';
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Base 'Mojolicious::Plugin::Config';

use base 'DBIx::Class::Core';
use Schema;
use Data::Dumper;
use Digest::SHA1 qw(sha1_hex);
use JSON;
use Cwd;

use Mojolicious::Plugins;
use Mojolicious::Plugin::Authentication;
use Mojolicious::Plugin::AccessLog;
use Mojolicious::Plugin::FormFields;
use Mojolicious::Plugin::Mail;
use Mojolicious::Static;
use Net::LDAP;
use Data::GUID;
use File::Stat qw/:stat/;
use User::pwent;
use POSIX qw(strftime);
use Utils::JsonConfig;
use MojoX::Log::Log4perl;
use File::Find;
use File::Basename;
use Env qw(PERL5LIB);
use Utils::Helper::TrafficOpsRoutesLoader;
use File::Path qw(make_path);
use IO::Compress::Gzip 'gzip';

use Utils::Helper::Version;

use constant SESSION_TIMEOUT => 14400;
my $logging_root_dir;
my $app_root_dir;
my $mode;
my $config;

local $/;    #Enable 'slurp' mode

has schema => sub { return Schema->connect_to_database };
has watch  => sub { [qw(lib templates)] };
has inactivity_timeout => sub {
	$ENV{MOJO_INACTIVITY_TIMEOUT} // $config->{60};    # or undef for default
};

if ( !defined $ENV{MOJO_CONFIG} ) {

	$ENV{MOJO_CONFIG} = find_conf_path('cdn.conf');
	print( "Loading config from " . $ENV{MOJO_CONFIG} . "\n" );
}
else {
	print( "MOJO_CONFIG overridden: " . $ENV{MOJO_CONFIG} . "\n" );
}

my $ldap_conf_path = find_conf_path('ldap.conf');
my $ldap_info      = 0;
my $host;
my $admin_dn;
my $admin_pass;
my $search_base;
if ( -e $ldap_conf_path ) {
	$ldap_info   = Utils::JsonConfig->new($ldap_conf_path);
	$host        = $ldap_info->{host};
	$admin_dn    = $ldap_info->{admin_dn};
	$admin_pass  = $ldap_info->{admin_pass};
	$search_base = $ldap_info->{search_base};
}

# This method will run once at server start
sub startup {
	my $self = shift;
	$mode = $self->mode;
	$self->app->types->type( iso => 'application/octet-stream' );

	$self->setup_logging($mode);
	$self->validate_cdn_conf();
	$self->setup_mojo_plugins();
	$self->set_secrets();

	$self->log->info("-------------------------------------------------------------");
	$self->log->info( "TrafficOps version: " . Utils::Helper::Version->current() . " is starting." );
	$self->log->info("-------------------------------------------------------------");

	$self->sessions->default_expiration(SESSION_TIMEOUT);
	my $access_control_allow_origin;
	my $portal_base_url;

	# Set/override app defaults
	$self->defaults( layout => 'jquery' );

	#Static Files
	my $static = Mojolicious::Static->new;
	push @{ $static->paths }, 'public';

	if ( $mode ne 'test' ) {
		$access_control_allow_origin = $config->{'cors'}{'access_control_allow_origin'};
		if ( defined($access_control_allow_origin) ) {
			$self->app->log->info( "Allowed origins : " . $config->{'cors'}{'access_control_allow_origin'} );
		}

		$portal_base_url = $config->{'portal'}{'base_url'};
		if ( defined($portal_base_url) ) {
			$self->app->log->info( "Portal Base Url : " . $portal_base_url );
		}
	}

	if ($ldap_info) {
		$self->log->info("Found $ldap_conf_path, LDAP is now enabled.\n");
	}

	$self->hook(
		before_render => sub {
			my ( $self, $args ) = @_;

			# Make sure we are rendering the exception template
			return unless my $template = $args->{template};
			return unless $template eq 'exception';

			$self->app->log->error( $self->stash(" exception ") );

			# Switch to JSON rendering if content negotiation allows it
			$args->{json} = { alerts => [ { "level" => "error", "text" => "An error occurred. Please contact your administrator." } ] }
				if $self->accepts('json');
		}
	);

	if ( defined($access_control_allow_origin) ) {

		# Coors Light header (CORS)
		$self->hook(
			before_dispatch => sub {
				my $self = shift;
				$self->res->headers->header( 'Access-Control-Allow-Origin'      => $config->{'cors'}{'access_control_allow_origin'} );
				$self->res->headers->header( 'Access-Control-Allow-Headers'     => 'Origin, X-Requested-With, Content-Type, Accept' );
				$self->res->headers->header( 'Access-Control-Allow-Methods'     => 'POST,GET,OPTIONS,PUT,DELETE' );
				$self->res->headers->header( 'Access-Control-Allow-Credentials' => 'true' );
				$self->res->headers->header( 'Cache-Control'                    => 'no-cache, no-store, max-age=0, must-revalidate' );
			}
		);
	}

	$self->hook(
		after_render => sub {
			my ( $c, $output, $format ) = @_;

			# Check if user agent accepts gzip compression
			return unless ( $c->req->headers->accept_encoding // '' ) =~ /gzip/i;
			$c->res->headers->append( Vary => 'Accept-Encoding' );

			# Compress content with gzip
			$c->res->headers->content_encoding('gzip');
			gzip $output, \my $compressed;
			$$output = $compressed;
		}
	);

	my $r = $self->routes;

	# Look in the PERL5LIB for any TrafficOpsRoutes.pm files and load them as well
	# Router
	my $rh = new Utils::Helper::TrafficOpsRoutesLoader($r);
	$rh->load();

}

sub setup_logging {
	my $self = shift;
	my $mode = shift;

	# This check prevents startup from blowing up if no conf/log4perl.conf
	# can be found, the Mojo defaults pattern/appender will kick in.
	if ( $mode eq 'production' ) {
		$logging_root_dir = "/var/log/traffic_ops";
		$app_root_dir     = "/opt/traffic_ops/app";
	}
	else {
		my $pwd = cwd();
		$logging_root_dir = "$pwd/log";
		$app_root_dir     = ".";
		make_path( $logging_root_dir, { verbose => 1, } );
	}
	my $log4perl_conf = find_conf_path("$mode/log4perl.conf");
	if ( -e $log4perl_conf ) {
		$self->log( MojoX::Log::Log4perl->new($log4perl_conf) );
	}
	else {
		print( "Warning cannot locate " . $log4perl_conf . ", using defaults\n" );
		$self->log( MojoX::Log::Log4perl->new() );
	}
	print("Reading log4perl config from $log4perl_conf \n");

}

sub setup_mojo_plugins {
	my $self = shift;

	$self->helper( db => sub { $self->schema } );
	$config = $self->plugin('Config');

	$self->plugin(
		'authentication', {
			autoload_user => 1,
			load_user     => sub {
				my ( $app, $username ) = @_;

				my $user_data = $self->db->resultset('TmUser')->search( { username => $username } )->single;
				my $role      = "read-only";
				my $priv      = 10;
				if ( defined($user_data) ) {
					$role       = $user_data->role->name;
					$priv       = $user_data->role->priv_level;
				}

				if ( $role eq 'disallowed' ) {
					return undef;
				}

				return {
					'username'   => $username,
					'role'       => $role,
					'priv'       => $priv,
				};
			},
			validate_user => sub {
				my ( $app, $username, $pass, $options ) = @_;

				my $logged_in_user;
				my $is_authenticated;

				# Check the Token Flow
				my $token = $options->{'token'};
				if ( defined($token) ) {
					$self->app->log->debug("Token was passed, now validating...");
					$logged_in_user = $self->check_token($token);
				}

				# Check the User/Password flow
				else {

					# Check Local User (in the database)
					( $logged_in_user, $is_authenticated ) = $self->check_local_user( $username, $pass );

					# Check LDAP if conf/ldap.conf is defined.
					if ( $ldap_info && ( !$logged_in_user || !$is_authenticated ) ) {
						$logged_in_user = $self->check_ldap_user( $username, $pass );
					}

				}
				return $logged_in_user;
			},
		}
	);

	# Custom TO Plugins
	my $mojo_plugins_dir;
	foreach my $dir (@INC) {
		$mojo_plugins_dir = sprintf( "%s/MojoPlugins", $dir );
		if ( -e $mojo_plugins_dir ) {
			last;
		}
	}
	my $plugins = Mojolicious::Plugins->new;

	my @file_list;
	find(
		sub {
			return unless -f;         #Must be a file
			return unless /\.pm$/;    #Must end with `.pl` suffix
			push @file_list, $File::Find::name;
		},
		$mojo_plugins_dir
	);

	#print join "\n", @file_list;
	foreach my $file (@file_list) {
		open my $fn, '<', $file;
		my $first_line = <$fn>;
		my ( $package_keyword, $package_name ) = ( $first_line =~ m/(package )(.*);/ );
		close $fn;

		#print("Loading:  $package_name\n");
		$plugins->load_plugin($package_name);
		$self->plugin($package_name);
	}

	my $to_email_from = $config->{'to'}{'email_from'};
	if ( defined($to_email_from) ) {

		$self->plugin(
			mail => {
				from => $to_email_from,
				type => 'text/html',
			}
		);

		if ( $mode ne 'test' ) {

			$self->app->log->info("...");
			$self->app->log->info( "Traffic Ops Email From: " . $to_email_from );
		}
	}

	$self->plugin( AccessLog => { log => "$logging_root_dir/access.log" } );
	$self->plugin('ParamExpand', max_array => 256);

	#FormFields
	$self->plugin('FormFields');

}

sub check_token {
	my $self  = shift;
	my $token = shift;
	$self->app->log->debug( "Locating user with token : " . $token . " \n " );
	my $tm_user = $self->db->resultset('TmUser')->find( { token => $token } );
	if ( defined($tm_user) ) {
		my $token_user = $self->db->resultset('TmUser')->find( { token => $token } );
		my $username = $token_user->username;
		$self->app->log->debug( "Token matched username : " . $username . " \n " );
		return $username;
	}
	else {
		$self->app->log->debug("Failed, could not find a matching token from tm_user. \n ");
		return undef;
	}
}

sub check_ldap_user {
	my $self     = shift;
	my $username = shift;
	my $pass     = shift;
	$self->app->log->debug( "Checking LDAP user: " . $username . "\n" );

	# If user is not found in local tm_user, assume it's an LDAP username, and give RO privs.
	my $user_dn = $self->find_username_in_ldap($username);
	my $is_logged_in = &login_to_ldap( $user_dn, $pass );
	if ( defined($user_dn) && $is_logged_in ) {
		$self->app->log->info( "Successful LDAP logged in : " . $username );
		return $username;
	}
	return undef;
}

sub find_conf_path {
	my $req_conf  = shift;
	my $mod_path  = $INC{ __PACKAGE__ . '.pm' };
	my $conf_path = join( '/', dirname( dirname($mod_path) ), 'conf', $req_conf );
	return $conf_path;
}

sub find_username_in_ldap {
	my $self     = shift;
	my $username = shift;
	my $dn;

	$self->app->log->debug( "Searching LDAP for: " . $username );
	my $ldap = Net::LDAP->new( $host, verify => 'none', timeout => 20 ) or die "$@ ";
	$self->app->log->debug("Binding...");
	my $mesg = $ldap->bind( $admin_dn, password => "$admin_pass" );
	$mesg->code && return undef;
	$mesg = $ldap->search( base => $search_base, filter => "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$username))" );
	$mesg->code && return undef;
	my $entry = $mesg->shift_entry;

	if ($entry) {
		$dn = $entry->dn;
	}
	else {
		$self->app->log->info( "Cannot find " . $username . " in LDAP." );
		return undef;
	}
	$ldap->unbind;
	return $dn;
}

# Lookup user in database
sub check_local_user {
	my $self             = shift;
	my $username         = shift;
	my $pass             = shift;
	my $local_user       = undef;
	my $is_authenticated = 0;

	my $db_user = $self->db->resultset('TmUser')->find( { username => $username } );
	if ( defined($db_user) && defined( $db_user->local_passwd ) ) {
		$self->app->log->info( $username . " was found in the database. " );
		my $db_local_passwd         = $db_user->local_passwd;
		my $db_confirm_local_passwd = $db_user->confirm_local_passwd;
		my $hex_pw_string           = sha1_hex($pass);
		if ( $db_local_passwd eq $hex_pw_string ) {
			$local_user = $username;
			$self->app->log->debug("Password matched.");
			$is_authenticated = 1;
		}
		else {
			$self->app->log->debug("Passwords did not match.");
			$local_user = 0;
		}
	}
	else {
		$self->app->log->info( "Could not find database user : " . $username );
		$local_user = 0;
	}
	return ( $local_user, $is_authenticated );
}

sub login_to_ldap {
	my $ldap;
	my $user_dn = shift;
	my $pass    = shift;
	$ldap = Net::LDAP->new( $host, verify => 'none' ) or die "$@ ";
	my $mesg = $ldap->bind( $user_dn, password => $pass );
	if ( $mesg->code ) {
		$ldap->unbind;
		return 0;
	}
	else {
		$ldap->unbind;
		return 1;
	}
}

sub load_conf {
	my $self      = shift;
	my $conf_file = shift;

	open( my $in, '<', $conf_file ) || die("$conf_file $!\n");
	local $/;
	my $conf_info = eval <$in>;
	undef $in;
	return $conf_info;
}

# Validates the conf/cdn.conf for certain criteria to
# avoid admin mistakes.
sub validate_cdn_conf {
	my $self = shift;

	my $cdn_info = $self->load_conf( $ENV{MOJO_CONFIG} );
	my $user;
	if ( !exists( $cdn_info->{secrets} ) ) {
		print("WARNING: no secrets found in $ENV{MOJO_CONFIG}.\n");
	}

	if ( exists( $cdn_info->{hypnotoad}{user} ) ) {
		for my $u ( $cdn_info->{hypnotoad}{user} ) {
			$u =~ s/.*?\?(.*)$/$1/;

			$user = $u;
		}
	}

	my $group;
	if ( exists( $cdn_info->{hypnotoad}{group} ) ) {
		for my $g ( $cdn_info->{hypnotoad}{group} ) {
			$g =~ s/.*?\?(.*)$/$1/;

			$group = $g;
		}
	}

	if ( exists( $cdn_info->{hypnotoad}{listen} ) ) {
		for my $listen ( @{ $cdn_info->{hypnotoad}{listen} } ) {
			$listen =~ s/.*?\?(.*)$/$1/;
			if ( $listen !~ /^#/ ) {

				for my $part ( split( /&/, $listen ) ) {
					my ( $k, $v ) = split( /=/, $part );

					if ( $k eq "cert" || $k eq "key" ) {

						my @fstats = stat($v);
						my $uid    = $fstats[4];
						if ( defined($uid) ) {

							my $gid = $fstats[5];

							my $file_owner = getpwuid($uid)->name;

							my $file_group = getgrgid($gid);
							if ( ( $file_owner !~ /$user/ ) || ( $file_group !~ /$group/ ) ) {
								print( "WARNING: " . $v . " is not owned by " . $user . ":" . $group . ".\n" );
							}
						}
					}
				}
			}
		}
	}
}

sub set_secrets {
	my $self = shift;

	# Set secret / disable annoying log message
	# The following commit details the change from secret to secrets in 4.63
	# https://github.com/kraih/mojo/commit/57e5129436bf3d717a13e092dd972217938e29b5
	my $cdn_info = $self->load_conf( $ENV{MOJO_CONFIG} );

	# for backward compatability -- keep old secret if not found in cdn.conf
	my $secrets = $cdn_info->{secrets} // ['mONKEYDOmONKEYSEE.'];
	if ( ref $secrets ne 'ARRAY' ) {
		my $e = Mojo::Exception->throw("Invalid 'secrets' entry in cdn.conf");
	}
	if ( $Mojolicious::VERSION >= 4.63 ) {
		$self->secrets($secrets);    # for Mojolicious 4.67, Top Hat
	}
	else {
		$self->secret( $secrets->[0] );    # for Mojolicious 3.x
	}
}

1;
