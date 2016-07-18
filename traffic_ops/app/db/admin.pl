#!/usr/bin/env perl
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
use strict;
use warnings;
use English;
use Getopt::Long;
use FileHandle;
use DBI;
use Cwd;
use Data::Dumper;
use Schema;
use CPAN::Meta;
use File::Find::Rule;

use YAML;
use YAML qw(LoadFile);
use DBIx::Class::Schema::Loader qw/make_schema_at/;

my $usage = "\n"
	. "Usage:  $PROGRAM_NAME [--env (development|test|production|integration)] [arguments]\t\n\n"
	. "Example:  $PROGRAM_NAME --env=test reset\n\n"
	. "Purpose:  This script is used to manage database. The environments are\n"
	. "          defined in the dbconf.yml, as well as the database names.\n\n"
	. "arguments:   \n\n"
	. "createdb  - Execute db 'createdb' the database for the current environment.\n"
	. "dropdb  - Execute db 'dropdb' on the database for the current environment.\n"
	. "down  - Roll back a single migration from the current version.\n"
	. "createuser  - Execute 'createuser' the user for the current environment.\n"
	. "dropuser  - Execute 'dropuser' the user for the current environment.\n"
	. "showusers  - Execute sql to show all of the user for the current environment.\n"
	. "redo  - Roll back the most recently applied migration, then run it again.\n"
	. "reset  - Execute db 'dropdb', 'createdb', load_schema, migrate on the database for the current environment.\n"
	. "reverse_schema  - Reverse engineer the lib/Schema/Result files from the environment database.\n"
	. "seed  - Execute sql from db/seeds.sql for loading static data.\n"
	. "setup  - Execute db dropdb, createdb, load_schema, migrate, seed on the database for the current environment.\n"
	. "status  - Print the status of all migrations.\n"
	. "upgrade  - Execute migrate then seed on the database for the current environment.\n";

my $environment = 'development';
my $db_protocol;

# This is defaulted to 'to_development' so
# you don't have to specify --env=development for dev workstations
my $db_name     = 'to_development';
my $db_username = 'to_user';
my $db_password = '';
my $host_ip     = '';
my $host_port   = '';
GetOptions( "env=s" => \$environment );
$ENV{'MOJO_MODE'} = $environment;

parse_dbconf_yml_pg_driver();

STDERR->autoflush(1);
my $argument = shift(@ARGV);
if ( defined($argument) ) {
	if ( $argument eq 'createdb' ) {
		createdb();
	}
	elsif ( $argument eq 'dropdb' ) {
		dropdb();
	}
	elsif ( $argument eq 'createuser' ) {
		createuser();
	}
	elsif ( $argument eq 'dropuser' ) {
		dropuser();
	}
	elsif ( $argument eq 'showusers' ) {
		showusers();
	}
	elsif ( $argument eq 'reset' ) {
		dropdb();
		createdb();
		load_schema();
		migrate('up');
	}
	elsif ( $argument eq 'upgrade' ) {
		migrate('up');
		seed();
	}
	elsif ( $argument eq 'setup' ) {
		dropdb();
		createdb();
		load_schema();
		migrate('up');
		seed();
	}
	elsif ( $argument eq 'migrate' ) {
		migrate('up');
	}
	elsif ( $argument eq 'down' ) {
		migrate('down');
	}
	elsif ( $argument eq 'redo' ) {
		migrate('redo');
	}
	elsif ( $argument eq 'status' ) {
		migrate('status');
	}
	elsif ( $argument eq 'dbversion' ) {
		migrate('dbversion');
	}
	elsif ( $argument eq 'seed' ) {
		seed();
	}
	elsif ( $argument eq 'load_schema' ) {
		load_schema();
	}
	elsif ( $argument eq 'reverse_schema' ) {
		reverse_schema();
	}
}
else {
	print $usage;
}

exit(0);

sub parse_dbconf_yml_pg_driver {
	my $db_conf 			= LoadFile('db/dbconf.yml');
	my $db_connection = $db_conf->{$environment};
	$db_protocol 			= $db_connection->{driver};
	my $open = $db_connection->{open};

	# Goose requires the 'open' line in the dbconf file to be a scalar.
	# example:
	#		open: host=127.0.0.1 port=5432 user=to_user password=twelve dbname=to_development sslmode=disable
	# We need access to these values for db connections so I am manipulating the 'open'
	# line so that it can be loaded into a hash.
	$open = join "\n", map { s/=/ : /; $_ } split " ", $open;
	my $hash = Load $open;

	$host_ip 					= $hash->{host};
	$host_port 				= $hash->{port};
	$db_name 					= $hash->{dbname};
	$db_username 			= $hash->{user};
	$db_password 			= $hash->{password};
}

sub migrate {
	my ($command) = @_;

	print "Migrating database...\n";
	system( 'goose --env=' . $environment . ' ' . $command );
}

sub seed {
	print "Seeding database.\n";
	system("psql -h $host_ip -p $host_port -d $db_name -U $db_username -e < db/seeds.sql");
}

sub load_schema {
	print "Creating database tables.\n";
	system("psql -h $host_ip -p $host_port -d $db_name -U $db_username -e < db/create_tables.sql");
}

sub dropdb {
	system("dropdb -h $host_ip -p $host_port -U $db_username -e --if-exists $db_name;");
}

sub createdb {
	system("createdb -h $host_ip -p $host_port -U $db_username -e $db_name;");
}

sub createuser {
	system("createuser -h $host_ip -p $host_port -P -e --superuser $db_username;");
}

sub dropuser {
	system("dropuser -h $host_ip -p $host_port -i -e $db_username;");
}

sub showusers {
	system("psql postgres -c '\\du';");
}

sub reverse_schema {

  my $db_info = Schema->get_dbinfo();
  my $user    = $db_info->{user};
  my $pass    = $db_info->{password};
  my $dsn     = Schema->get_dsn();
  make_schema_at(
    'Schema', {
      debug                   => 1,
      dump_directory          => './lib',
      overwrite_modifications => 1,
    },
    [ $dsn, $user, $pass ],
  );
}
