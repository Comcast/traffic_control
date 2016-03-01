use utf8;
package Schema::Result::TmUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::TmUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tm_user>

=cut

__PACKAGE__->table("tm_user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 public_ssh_key

  data_type: 'varchar'
  is_nullable: 1
  size: 2048

=head2 role

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 uid

  data_type: 'integer'
  is_nullable: 1

=head2 gid

  data_type: 'integer'
  is_nullable: 1

=head2 local_passwd

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 confirm_local_passwd

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 last_updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 1

=head2 company

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 full_name

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 new_user

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=head2 address_line1

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 address_line2

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 state_or_province

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 phone_number

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 postal_code

  data_type: 'varchar'
  is_nullable: 1
  size: 11

=head2 country

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 token

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 registration_sent

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "public_ssh_key",
  { data_type => "varchar", is_nullable => 1, size => 2048 },
  "role",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "uid",
  { data_type => "integer", is_nullable => 1 },
  "gid",
  { data_type => "integer", is_nullable => 1 },
  "local_passwd",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "confirm_local_passwd",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "last_updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 1,
  },
  "company",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "full_name",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "new_user",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "address_line1",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "address_line2",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "state_or_province",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "phone_number",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "postal_code",
  { data_type => "varchar", is_nullable => 1, size => 11 },
  "country",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "token",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "registration_sent",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<tmuser_email_UNIQUE>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("tmuser_email_UNIQUE", ["email"]);

=head2 C<username_UNIQUE>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username_UNIQUE", ["username"]);

=head1 RELATIONS

=head2 deliveryservice_tmusers

Type: has_many

Related object: L<Schema::Result::DeliveryserviceTmuser>

=cut

__PACKAGE__->has_many(
  "deliveryservice_tmusers",
  "Schema::Result::DeliveryserviceTmuser",
  { "foreign.tm_user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 federation_tmusers

Type: has_many

Related object: L<Schema::Result::FederationTmuser>

=cut

__PACKAGE__->has_many(
  "federation_tmusers",
  "Schema::Result::FederationTmuser",
  { "foreign.tm_user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 jobs

Type: has_many

Related object: L<Schema::Result::Job>

=cut

__PACKAGE__->has_many(
  "jobs",
  "Schema::Result::Job",
  { "foreign.job_user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 logs

Type: has_many

Related object: L<Schema::Result::Log>

=cut

__PACKAGE__->has_many(
  "logs",
  "Schema::Result::Log",
  { "foreign.tm_user" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 role

Type: belongs_to

Related object: L<Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Schema::Result::Role",
  { id => "role" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-02-22 13:13:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:j4nYjjnStUYvhKi7zNh4bw


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
