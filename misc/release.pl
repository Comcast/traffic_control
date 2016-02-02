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
use File::Path qw(make_path remove_tree);

my $usage = "\n"
	. "Usage:  $PROGRAM_NAME --gpg-key=[your-signed-key-id] --release_no=[release-to-create]\t\n\n"
	. "Example:  $PROGRAM_NAME --gpg-key=75AFDE1 --release-no=RELEASE-1.1.0 \n\n"
	. "Purpose:  This script automates the release process for the Traffic Control cdn.\n"
	. "\nFlags:   \n\n"
	. "--gpg-key          - Your gpg-key id. ie: 774ACED1\n"
	. "--release-no       - The release_no name you want to cut. ie: 1.1.0\n"
	. "--git-hash         - (optional) The git hash that will be used to reference the release. ie: da4aab57d \n"
	. "--git-remote-url   - (optional) Overrides the git repo URL where the release will be pulled and sent (mostly for testing). ie: git\@github.com:yourrepo/traffic_control.git \n"
	. "--dry-run          - (optional) Simulation mode which will NOT apply any changes. \n"
	. "\nArguments:   \n\n"
	. "branch     - Cut the release branch, tag the release then make the branch, tag public.\n"
	. "cleanup    - Reverses the release steps in case you messed up.\n"
	. "pushdoc    - Upload documentation to the public website.\n";

my $git_remote_name = 'official';

#my $git_remote_url = 'git@github.com:Comcast/traffic_control.git';
my $git_remote_url = 'git@github.com:Comcast/traffic_control.git';

my $gpg_key;
my $release_no;

# Example: 1.1.0
my $version;

# Example: 1.2.0
my $next_version;

# Example: 1.1.x
my $new_branch;

# Example: 2377
my $build_no;

# Example: 774ACED1
my $git_hash;

my $rc;
my $dry_run = 0;
my $working_dir;

GetOptions(
	"gpg-key=s"        => \$gpg_key,
	"release-no=s"     => \$release_no,
	"git-hash=s"       => \$git_hash,
	"git-remote-url=s" => \$git_remote_url,
	"dry-run!"         => \$dry_run
);

#TODO: drichardson - Preflight check for commands 'git', 's3cmd' , '
#                  - Add validation logic here for required flags
#                  - Upload Release (s3cmd)

STDERR->autoflush(1);
my $argument = shift(@ARGV);

if ( defined($argument) ) {

	if ( $argument eq 'branch' ) {
		fetch_branch();
		my $prompt = "Continue with the creating the release branch?";
		if ( prompt_yn($prompt) ) {
			cut_release();
		}
		else {
			exit(0);
		}
	}
	elsif ( $argument eq 'cleanup' ) {
		my $prompt = "Are you sure you want to cleanup release: " . $version . " this is irreversible";
		if ( prompt_yn($prompt) ) {
			fetch_branch();
			cleanup_release();
		}
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

sub fetch_branch {

	clone_repo_to_tmp();

	if ( !defined($git_hash) ) {
		( $rc, $git_hash ) = get_git_hash();
	}

	parse_variables();

	my $release_info = <<"INFO";
\nRelease Info Summary
Git Repo     : $git_remote_url
Version      : $version
Branch       : $new_branch
Tag          : $release_no
Git Hash     : $git_hash
Next Version : $next_version
INFO
	print $release_info;

}

sub get_git_hash {
	my $cmd = "git log --pretty=format:'%h' -n 1";
	chdir $working_dir;
	my ( $rc, $git_shorthash ) = run_and_capture_command( $cmd, "force" );
	if ( $rc > 0 ) {
		print " Failed to run : " . $cmd . " \n ";
		exit(1);
	}
	return $rc, $git_shorthash;
}

sub clone_repo_to_tmp {
	my $tmp_dir = "/tmp";
	my $tc_dir  = "traffic_control";
	$working_dir = sprintf( "%s/%s", $tmp_dir, $tc_dir );
	remove_tree($working_dir);
	chdir $tmp_dir;
	print "Cloning output to: " . $working_dir . "\n";
	my $cmd = "git clone " . $git_remote_url;
	chdir $working_dir;

	my $rc = run_command( $cmd, "force" );
	if ( $rc > 0 ) {
		print " Failed to run : " . $cmd . " \n ";
		exit(1);
	}

}

sub parse_variables {
	my $major;
	my $minor;
	my $patch;
	( $major, $minor, $patch, $build_no ) = ( $release_no =~ /RELEASE-(\d).(\d).(\d)-(.*)/ );

	$version = sprintf( "%s.%s.%s", $major, $minor, $patch );

	my $next_minor = $minor + 1;

	$next_version = sprintf( "%s.%s.%s", $major, $next_minor, $patch );

	$new_branch = sprintf( "%s.%s.X", $major, $minor );

}

sub cut_release {

	chdir $working_dir;
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

	update_version_file($next_version);
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
	my $comment = "Release " . $version;
	$cmd = sprintf( "git tag -s -u %s -m '%s' %s", $gpg_key, $comment, $release_no );
	$rc = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
		exit(1);
	}

	print "Making new tags and branch publicly available.\n";
	$cmd = "git push --follow-tags official " . $new_branch;
	$rc  = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
		exit(1);
	}
}

sub cleanup_release {

	chdir $working_dir;
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

	update_version_file($version);
	$cmd = "git commit -m 'Decrementing VERSION file' VERSION";
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
	$cmd = "git push origin --delete " . $new_branch;
	$rc  = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
		exit(1);
	}

	print "Removing old tag locally\n";
	my $comment = "Release " . $version;
	$cmd = sprintf( "git tag -d %s", $version );
	$rc = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
		exit(1);
	}

	print "Removing old tag from remote\n";
	$cmd = sprintf( "git push origin :refs/tags/%s", $version );
	$rc = run_command($cmd);
	if ( $rc > 0 ) {
		print "Failed to run:" . $cmd . "\n";
		exit(1);
	}

}

sub update_version_file {

	my $version_no = shift;

	print " Updating 'VERSION' file \n ";
	my $version_file_name = "VERSION";
	open my $fh, '<', $version_file_name or die "error opening $version_file_name $!";
	my $data = do { local $/; <$fh> };
	print "Prior VERSION: " . $data . "\n";

	if ($dry_run) {
		print "Would have updated VERSION file to: " . $version_no . "\n";
	}
	else {
		print "Updated VERSION file to: " . $version_no . "\n";
		open( $fh, '>', $version_file_name ) or die "Could not open file '$version_file_name' $!";
		print $fh $version_no . "\n";
		close $fh;
	}
}

sub deploy_documentation {

}

sub prompt {
	my ($query) = @_;    # take a prompt string as argument
	local $| = 1;        # activate autoflush to immediately show the prompt
	print $query;
	chomp( my $answer = <STDIN> );
	return $answer;
}

sub prompt_yn {
	my ($query) = @_;
	my $answer = prompt("$query (Y/N): ");
	return lc($answer) eq 'y';
}

sub run_and_capture_command {
	my ( $cmd, $force ) = @_;
	if ( $dry_run && ( !defined($force) ) ) {
		print "Simulating cmd:> " . $cmd . "\n\n";
		return 0;
	}
	else {
		print "Capturing COMMAND> " . $cmd . "\n\n";
		my $cmd_output = `$cmd </dev/null`;
		return $?, $cmd_output;
	}
}

sub run_command {
	my ( $cmd, $force ) = @_;
	if ( $dry_run && ( !defined($force) ) ) {
		print "Simulating cmd:> " . $cmd . "\n\n";
		return 0;
	}
	else {
		print "Executing COMMAND> " . $cmd . "\n\n";
		system($cmd);

		return $?;
	}

	#system( 'goose --env=' . $environment . ' ' . $command );
}
