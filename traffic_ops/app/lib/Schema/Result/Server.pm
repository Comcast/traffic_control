use utf8;
package Schema::Result::Server;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::Server

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<server>

=cut

__PACKAGE__->table("server");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 host_name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 domain_name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 tcp_port

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 xmpp_id

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 xmpp_passwd

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 interface_name

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 ip_address

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 ip_netmask

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 ip_gateway

  data_type: 'varchar'
  is_nullable: 0
  size: 45

=head2 ip6_address

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 ip6_gateway

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 interface_mtu

  data_type: 'integer'
  default_value: 9000
  is_nullable: 0

=head2 phys_location

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 rack

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 cachegroup

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 type

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 upd_pending

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 profile

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cdn_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 mgmt_ip_address

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 mgmt_ip_netmask

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 mgmt_ip_gateway

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 ilo_ip_address

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 ilo_ip_netmask

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 ilo_ip_gateway

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 ilo_username

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 ilo_password

  data_type: 'varchar'
  is_nullable: 1
  size: 45

=head2 router_host_name

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 router_port_name

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 last_updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "host_name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "domain_name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "tcp_port",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 1 },
  "xmpp_id",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "xmpp_passwd",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "interface_name",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "ip_address",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "ip_netmask",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "ip_gateway",
  { data_type => "varchar", is_nullable => 0, size => 45 },
  "ip6_address",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "ip6_gateway",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "interface_mtu",
  { data_type => "integer", default_value => 9000, is_nullable => 0 },
  "phys_location",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rack",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "cachegroup",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "type",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "upd_pending",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "profile",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cdn_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "mgmt_ip_address",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "mgmt_ip_netmask",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "mgmt_ip_gateway",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "ilo_ip_address",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "ilo_ip_netmask",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "ilo_ip_gateway",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "ilo_username",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "ilo_password",
  { data_type => "varchar", is_nullable => 1, size => 45 },
  "router_host_name",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "router_port_name",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "last_updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=item * L</cachegroup>

=item * L</type>

=item * L</status>

=item * L</profile>

=back

=cut

__PACKAGE__->set_primary_key("id", "cachegroup", "type", "status", "profile");

=head1 UNIQUE CONSTRAINTS

=head2 C<cs_ip_address_UNIQUE>

=over 4

=item * L</ip_address>

=back

=cut

__PACKAGE__->add_unique_constraint("cs_ip_address_UNIQUE", ["ip_address"]);

=head2 C<host_name>

=over 4

=item * L</host_name>

=back

=cut

__PACKAGE__->add_unique_constraint("host_name", ["host_name"]);

=head2 C<ip6_address>

=over 4

=item * L</ip6_address>

=back

=cut

__PACKAGE__->add_unique_constraint("ip6_address", ["ip6_address"]);

=head2 C<se_id_UNIQUE>

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->add_unique_constraint("se_id_UNIQUE", ["id"]);

=head1 RELATIONS

=head2 cachegroup

Type: belongs_to

Related object: L<Schema::Result::Cachegroup>

=cut

__PACKAGE__->belongs_to(
  "cachegroup",
  "Schema::Result::Cachegroup",
  { id => "cachegroup" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 cdn

Type: belongs_to

Related object: L<Schema::Result::Cdn>

=cut

__PACKAGE__->belongs_to(
  "cdn",
  "Schema::Result::Cdn",
  { id => "cdn_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "RESTRICT",
  },
);

=head2 deliveryservice_servers

Type: has_many

Related object: L<Schema::Result::DeliveryserviceServer>

=cut

__PACKAGE__->has_many(
  "deliveryservice_servers",
  "Schema::Result::DeliveryserviceServer",
  { "foreign.server" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 hwinfos

Type: has_many

Related object: L<Schema::Result::Hwinfo>

=cut

__PACKAGE__->has_many(
  "hwinfos",
  "Schema::Result::Hwinfo",
  { "foreign.serverid" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phys_location

Type: belongs_to

Related object: L<Schema::Result::PhysLocation>

=cut

__PACKAGE__->belongs_to(
  "phys_location",
  "Schema::Result::PhysLocation",
  { id => "phys_location" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 profile

Type: belongs_to

Related object: L<Schema::Result::Profile>

=cut

__PACKAGE__->belongs_to(
  "profile",
  "Schema::Result::Profile",
  { id => "profile" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 servercheck

Type: might_have

Related object: L<Schema::Result::Servercheck>

=cut

__PACKAGE__->might_have(
  "servercheck",
  "Schema::Result::Servercheck",
  { "foreign.server" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 status

Type: belongs_to

Related object: L<Schema::Result::Status>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Schema::Result::Status",
  { id => "status" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 type

Type: belongs_to

Related object: L<Schema::Result::Type>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Schema::Result::Type",
  { id => "type" },
  { is_deferrable => 1, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-10-05 11:50:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8Ir+ulHZBxu/B886Q0dNFA


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
