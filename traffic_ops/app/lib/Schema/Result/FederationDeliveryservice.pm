use utf8;
package Schema::Result::FederationDeliveryservice;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Schema::Result::FederationDeliveryservice

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<federation_deliveryservice>

=cut

__PACKAGE__->table("federation_deliveryservice");

=head1 ACCESSORS

=head2 federation

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 deliveryservice

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
  "deliveryservice",
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

=item * L</deliveryservice>

=back

=cut

__PACKAGE__->set_primary_key("federation", "deliveryservice");

=head1 RELATIONS

=head2 deliveryservice

Type: belongs_to

Related object: L<Schema::Result::Deliveryservice>

=cut

__PACKAGE__->belongs_to(
  "deliveryservice",
  "Schema::Result::Deliveryservice",
  { id => "deliveryservice" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-09-28 13:05:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WFPKsZLhl68a4TZwfNUURA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
