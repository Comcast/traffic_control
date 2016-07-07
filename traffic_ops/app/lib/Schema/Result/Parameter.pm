use utf8;
package Schema::Result::Parameter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Parameter

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<parameter>

=cut

__PACKAGE__->table("parameter");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 1024

=head2 config_file

  data_type: 'varchar'
  is_nullable: 0
  size: 256

=head2 value

  data_type: 'varchar'
  is_nullable: 0
  size: 1024

=head2 last_updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 1

=head2 secure

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 1024 },
  "config_file",
  { data_type => "varchar", is_nullable => 0, size => 256 },
  "value",
  { data_type => "varchar", is_nullable => 0, size => 1024 },
  "last_updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 1,
  },
  "secure",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 cachegroup_parameters

Type: has_many

Related object: L<Schema::Result::CachegroupParameter>

=cut

__PACKAGE__->has_many(
  "cachegroup_parameters",
  "Schema::Result::CachegroupParameter",
  { "foreign.parameter" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 profile_parameters

Type: has_many

Related object: L<Schema::Result::ProfileParameter>

=cut

__PACKAGE__->has_many(
  "profile_parameters",
  "Schema::Result::ProfileParameter",
  { "foreign.parameter" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-03-15 23:28:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aTrkVhWmNRR9aZ9VqhH1Pg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
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
1;
