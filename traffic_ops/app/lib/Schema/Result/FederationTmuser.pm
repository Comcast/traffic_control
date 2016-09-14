use utf8;
package Schema::Result::FederationTmuser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::FederationTmuser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<federation_tmuser>

=cut

__PACKAGE__->table("federation_tmuser");

=head1 ACCESSORS

=head2 federation

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 tm_user

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 role

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
  "federation",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "tm_user",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "role",
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

=item * L</federation>

=item * L</tm_user>

=back

=cut

__PACKAGE__->set_primary_key("federation", "tm_user");

=head1 RELATIONS

=head2 federation

Type: belongs_to

Related object: L<Schema::Result::Federation>

=cut

__PACKAGE__->belongs_to(
  "federation",
  "Schema::Result::Federation",
  { id => "federation" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 role

Type: belongs_to

Related object: L<Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Schema::Result::Role",
  { id => "role" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 tm_user

Type: belongs_to

Related object: L<Schema::Result::TmUser>

=cut

__PACKAGE__->belongs_to(
  "tm_user",
  "Schema::Result::TmUser",
  { id => "tm_user" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-07-05 09:49:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NY0OvOo2mTn/3hYWgGkPdg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
