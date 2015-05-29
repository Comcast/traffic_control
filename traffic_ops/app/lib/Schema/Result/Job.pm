use utf8;
package Schema::Result::Job;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Job

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<job>

=cut

__PACKAGE__->table("job");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 agent

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 object_type

  data_type: 'varchar'
  is_nullable: 1
  size: 48

=head2 object_name

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 keyword

  data_type: 'varchar'
  is_nullable: 0
  size: 48

=head2 parameters

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 asset_url

  data_type: 'varchar'
  is_nullable: 0
  size: 512

=head2 asset_type

  data_type: 'varchar'
  is_nullable: 0
  size: 48

=head2 status

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 start_time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 entered_time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 job_user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 last_updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 1

=head2 job_deliveryservice

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "agent",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "object_type",
  { data_type => "varchar", is_nullable => 1, size => 48 },
  "object_name",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "keyword",
  { data_type => "varchar", is_nullable => 0, size => 48 },
  "parameters",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "asset_url",
  { data_type => "varchar", is_nullable => 0, size => 512 },
  "asset_type",
  { data_type => "varchar", is_nullable => 0, size => 48 },
  "status",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "start_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "entered_time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "job_user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "last_updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 1,
  },
  "job_deliveryservice",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 agent

Type: belongs_to

Related object: L<Schema::Result::JobAgent>

=cut

__PACKAGE__->belongs_to(
  "agent",
  "Schema::Result::JobAgent",
  { id => "agent" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 job_deliveryservice

Type: belongs_to

Related object: L<Schema::Result::Deliveryservice>

=cut

__PACKAGE__->belongs_to(
  "job_deliveryservice",
  "Schema::Result::Deliveryservice",
  { id => "job_deliveryservice" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 job_results

Type: has_many

Related object: L<Schema::Result::JobResult>

=cut

__PACKAGE__->has_many(
  "job_results",
  "Schema::Result::JobResult",
  { "foreign.job" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 job_user

Type: belongs_to

Related object: L<Schema::Result::TmUser>

=cut

__PACKAGE__->belongs_to(
  "job_user",
  "Schema::Result::TmUser",
  { id => "job_user" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 status

Type: belongs_to

Related object: L<Schema::Result::JobStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Schema::Result::JobStatus",
  { id => "status" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-05-21 13:27:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AOQJIKcfi/ADgnVuB7U+rg


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
