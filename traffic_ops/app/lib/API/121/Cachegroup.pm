package API::121::Cachegroup;
#
## Copyright 2015 Comcast Cable Communications Management, LLC
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
##
##
#
## JvD Note: you always want to put Utils as the first use. Sh*t don't work if it's after the Mojo lines.
#


use Mojo::Base 'Mojolicious::Controller';
use JSON;
use MojoPlugins::Response;
use UI::Cachegroup;
use Data::Dumper;

sub create{
    my $self = shift;
    my $params = $self->req->json;
    if (!defined($params)) {
        return $self->alert("parameters must Json format,  please check!"); 
    }
    $self->app->log->debug("create cachegroup with: " . Dumper($params) );

    my $cachegroups = &UI::Cachegroup::get_cachegroups($self);
    my $name    = $params->{name};
    my $short_name    = $params->{short_name};
    my $parent_cachegroup = $params->{parent_cachegroup};
    my $type_name = $params->{type_name};
    my $type_id = $self->get_typeId($type_name);

    if (!defined($type_id)) {
        return $self->alert("type_name[". $type_name . "] is not a validate cachegroup type"); 
    }
    if (exists $cachegroups->{'cachegroups'}->{$name}) {
        return $self->internal_server_error("cache_group_name[".$name."] is already exist.");
    }
    if (exists $cachegroups->{'short_names'}->{$short_name}) {
        return $self->internal_server_error("cache_group_shortname[".$short_name."] is already exist.");
    }

    my $parent_cachegroup_id = $cachegroups->{'cachegroups'}->{$parent_cachegroup};
    my $insert = $self->db->resultset('Cachegroup')->create(
        {
            name        => $name,
            short_name  => $short_name,
            latitude    => $params->{latitude},
            longitude  => $params->{longitude},
            parent_cachegroup_id => $parent_cachegroup_id,
            type        => $type_id,
        }
    );
    $insert->insert();
   
    my $response;
    my $rs = $self->db->resultset('Cachegroup')->find( { id => $insert->id } );
    if (defined($rs)) {
        $response->{id}     = $rs->id;
        $response->{name}   = $rs->name;
        $response->{short_name}  = $rs->short_name;
        $response->{latitude}    = $rs->latitude;
        $response->{longitude}   = $rs->longitude;
        $response->{parent_cachegroup} = $parent_cachegroup;
        $response->{parent_cachegroup_id} = $rs->parent_cachegroup_id;
        $response->{type}        = $rs->type->id;
        $response->{last_updated} = $rs->last_updated;
    }
    return $self->success($response);
}

sub get_typeId {
    my $self      = shift;
    my $type_name = shift;

    my $rs = $self->db->resultset("Type")->find( { name => $type_name } );
    my $type_id;
    if (defined($rs) && ($rs->use_in_table eq "cachegroup")) {
        $type_id = $rs->id;
    }
    return($type_id);
}

1;
