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
use File::Find::Rule;

my $usage = "\n"
	. "Usage:  $PROGRAM_NAME [--gpg-key [your-signed-key-id] --release_no=[release-to-create]\t\n\n"
	. "Example:  $PROGRAM_NAME --gpg-key=75AFDE1 --release-no=RELEASE-1.1.0 --git-hash=da4aab57d\n\n"
	. "Purpose:  This script automates the release process for the Traffic Control cdn.\n"
	. "          defined in the dbconf.yml, as well as the database names.\n\n"
	. "Flags:   \n\n"
	. "--gpg-key  - Your gpg-key id. ie: 774ACED1\n"
	. "--release-no   - The release_no name you want to cut. ie: 1.1.0\n"
	. "--git-hash   - The git hash that will be used to reference the release. ie: da4aab57d \n"
	. "--dry-run      - Simulation mode which will NOT apply any changes. \n"
	. "\nArguments:   \n\n"
	. "release    - Cut the release, tag the release then make the branch, tag public\n"
	. "pushdoc    - Upload documentation to the public website.\n";

my $git_remote_name = 'official';
my $git_remote_url  = 'git@github.com:dewrich/traffic_control.git';

#my $git_remote_url  = 'git@github.com:Comcast/traffic_control.git';
my $gpg_key;
my $release_no;

# Example: 1.1.0
my $version;

# Example: 1.2.0
my $next_version;

# Example: 1.1.x
my $new_branch;

# Example: 774ACED1
my $git_hash;
my $dry_run = 0;

GetOptions( "gpg-key=s" => \$gpg_key, "release-no=s" => \$release_no, "git-hash=s" => \$git_hash, "dry-run!" => \$dry_run );

STDERR->autoflush(1);
my $argument = shift(@ARGV);

if ( defined($argument) ) {
	parse_variables();

	if ( $argument eq 'release' ) {
		cut_release_branch();
	}
	elsif ( $argument eq 'pushdoc' ) {
		push_documentation();
	}
	else {
		print $usage;
	}
}
else {
	print $usage;
}

exit(0);

sub parse_variables {
	my ( $major, $minor, $patch, $build_no ) = ( $release_no =~ /RELEASE-(\d).(\d).(\d)-(.*)/ );
	print "release_no #-> (" . $release_no . ")\n";
	print "major #-> (" . $major . ")\n";
	print "minor #-> (" . $minor . ")\n";
	print "patch #-> (" . $patch . ")\n";
	print "build_no #-> (" . $build_no . ")\n";
	$version = sprintf( "%s.%s.%s", $major, $minor, $patch );

	my $next_minor = $minor + 1;
	print "next_minor #-> (" . $next_minor . ")\n";
	$next_version = sprintf( "%s.%s.%s", $major, $next_minor, $patch );

	print "version #-> (" . $version . ")\n";
	$new_branch = sprintf( "%s.%s.X", $major, $minor );
	print "new_branch #-> (" . $new_branch . ")\n";
}

sub cut_release_branch {

	print "gpg_key #-> (" . $gpg_key . ")\n";
	print "release_no #-> (" . $release_no . ")\n";
	print "dry_run #-> (" . $dry_run . ")\n";
	my $cmd = "git remote add official " . $git_remote_url;
	my $rc  = run_command($cmd);
	if ( $rc > 0 ) {
		print "Added new origin: " . $git_remote_name . " " . $git_remote_url . "\n\n";
	}
	else {
		print "Found Official : " . $git_remote_name . " " . $git_remote_url . "\n\n";
	}

	update_version_file();
	$cmd = "git commit -m 'Incrementing VERSION file' VERSION";
	$rc  = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
	}

	print "Updating 'VERSION' file\n";
	$cmd = "git push official master";
	$rc  = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
		exit(1);
	}

	print "Creating new branch\n";
	$cmd = "git checkout -b " . $new_branch;
	$rc  = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
		exit(1);
	}

	print "Signing new tag based upon your gpg key\n";
	$cmd = sprintf( "git tag -s -u %s -m '%s' %s", $git_hash, "Release 1.1.0 RC0", $version );
	$rc = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
		exit(1);
	}

	print "Making new tags and branch public available.\n";
	$cmd = "git push --follow-tags official " . $new_branch;
	$rc  = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
		exit(1);
	}

	#if ( $rc > 0 ) {
	#die " System $cmd failed : $? ";
	#}

	#print( " rc    #-> " . $rc . "\n" );

}

sub update_version_file {

	my $version_file_name = "VERSION";
	open my $fh, '<', $version_file_name or die "error opening $version_file_name $!";
	my $data = do { local $/; <$fh> };
	print "Prior VERSION: " . $data . "\n";

	if ($dry_run) {
		print "Would have updated VERSION file to: " . $next_version . "\n";
	}
	else {
		print "Updated VERSION file to: " . $next_version . "\n";
		open( $fh, '>', $version_file_name ) or die "Could not open file '$version_file_name' $!";
		print VERSION_FILE $next_version . "\n";
		close VERSION_FILE;
	}
}

sub deploy_documentation {

}

sub run_command {
	my ($cmd) = @_;
	if ($dry_run) {
		print "Simulating cmd:> " . $cmd . "\n\n";
		return 0;
	}
	else {
		print "Executing COMMAND> " . $cmd . "\n\n";
		system($cmd);

		#system($cmd) == 0
		#or die "system $cmd failed: $?";
		return $?;
	}

	#system( 'goose --env=' . $environment . ' ' . $command );
}
