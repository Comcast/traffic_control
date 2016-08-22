use utf8;
package Schema::Result::Hwinfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Hwinfo

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<hwinfo>

=cut

__PACKAGE__->table("hwinfo");

=head1 ACCESSORS

=head2 id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'hwinfo_id_seq'

=head2 serverid

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 256

=head2 val

  data_type: 'varchar'
  is_nullable: 0
  size: 256

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
    sequence          => "hwinfo_id_seq",
  },
  "serverid",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 256 },
  "val",
  { data_type => "varchar", is_nullable => 0, size => 256 },
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

=head2 C<idx_472012_serverid>

=over 4

=item * L</serverid>

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("idx_472012_serverid", ["serverid", "description"]);

=head1 RELATIONS

=head2 serverid

Type: belongs_to

Related object: L<Schema::Result::Server>

=cut

__PACKAGE__->belongs_to(
  "serverid",
  "Schema::Result::Server",
  { id => "serverid" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-08-22 12:27:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AlqxNDuW0/VkFoDZP7u4lQ


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
