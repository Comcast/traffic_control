package UI::GenDbDump;
#
# Copyright 2015 Comcast Cable Communications Management, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
#
use Mojo::Base 'Mojolicious::Controller';

sub dbdump {
	my $self = shift;

	my $filename = $self->param('filename');

	

	my $db_user = $Schema::user;
	my $db_pass = $Schema::pass;
	my $db_name = ( split( /:/, $Schema::dsn ) )[2];
	my $db_host = $Schema::hostname;
	$db_name =~ s/database=//;

	my $cmd	      = "PG_PASSWORD='" . $db_pass . "' pg_dump --username=" . $db_user . " " . $db_name;
	my $extension = ".psql";
	if ( $self->db->storage->isa("DBIx::Class::Storage::DBI::mysql") ) {
		$cmd	   = "mysqldump -h " . $db_host . " -u " . $db_user . " -p" . $db_pass . " " . $db_name;
		$extension = ".mysql";
	}
	my $data = `$cmd`;

	
	$self->res->headers->content_type("application/download");
	
	$self->res->headers->content_disposition( "attachment; filename=\"" . $filename . "\"" );
	$self->render( data => $data );
}

1;
