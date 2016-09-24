use utf8;
package Schema::Result::Region;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Region

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<region>

=cut

__PACKAGE__->table("region");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'region_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 division

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 last_updated

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "region_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "division",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "last_updated",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<idx_37442_name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("idx_37442_name_unique", ["name"]);

=head1 RELATIONS

=head2 division

Type: belongs_to

Related object: L<Schema::Result::Division>

=cut

__PACKAGE__->belongs_to(
  "division",
  "Schema::Result::Division",
  { id => "division" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 phys_locations

Type: has_many

Related object: L<Schema::Result::PhysLocation>

=cut

__PACKAGE__->has_many(
  "phys_locations",
  "Schema::Result::PhysLocation",
  { "foreign.region" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-09-24 13:32:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZhsYfvpg/NhB0jrPCOLOwA


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
