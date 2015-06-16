package Utils::Helper::Extensions;
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

use Data::Dumper;
use Mojo::UserAgent;
use File::Find;

sub use {
	my $module;
	my $to_ext_lib_env = $ENV{"TO_EXTENSIONS_LIB"};
	if ( defined($to_ext_lib_env) ) {
		if ( -e $to_ext_lib_env ) {
			print "Using Extensions library path: " . $to_ext_lib_env . "\n";
			my @file_list;
			find(
				sub {
					return unless -f;         #Must be a file
					return unless /\.pm$/;    #Must end with `.pl` suffix
					push @file_list, $File::Find::name;
				},
				$to_ext_lib_env
			);

			foreach my $file (@file_list) {
				open my $fn, '<', $file;
				my $first_line = <$fn>;
				my ( $package_keyword, $package_name ) = ( $first_line =~ m/(package )(.*);/ );
				eval "use $package_name;";
				close $fn;
			}
		}
	}
}

1;
