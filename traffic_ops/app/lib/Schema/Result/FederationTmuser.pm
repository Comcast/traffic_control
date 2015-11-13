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

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tm_user

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 role

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 last_updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "federation",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tm_user",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 role

Type: belongs_to

Related object: L<Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Schema::Result::Role",
  { id => "role" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 tm_user

Type: belongs_to

Related object: L<Schema::Result::TmUser>

=cut

__PACKAGE__->belongs_to(
  "tm_user",
  "Schema::Result::TmUser",
  { id => "tm_user" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-10-01 14:21:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GtS0uKLYINOgVL6K5muNag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
