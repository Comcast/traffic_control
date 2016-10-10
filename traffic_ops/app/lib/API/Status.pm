package API::Status;
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
use Data::Dumper;

sub index {
	my $self = shift;
	my @data;
	my $orderby = $self->param('orderby') || "name";
	my $rs_data = $self->db->resultset("Status")->search( undef, { order_by => $orderby } );
	while ( my $row = $rs_data->next ) {
		push(
			@data, {
				"id"          => $row->id,
				"name"        => $row->name,
				"description" => $row->description,
				"lastUpdated" => $row->last_updated
			}
		);
	}
	$self->success( \@data );
}

sub show {
	my $self = shift;
	my $id   = $self->param('id');

	my $rs_data = $self->db->resultset("Status")->search( { id => $id } );
	my @data = ();
	while ( my $row = $rs_data->next ) {
		push(
			@data, {
				"id"          => $row->id,
				"name"        => $row->name,
				"description" => $row->description,
				"lastUpdated" => $row->last_updated
			}
		);
	}
	$self->success( \@data );
}


1;
