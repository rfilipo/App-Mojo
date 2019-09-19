use utf8;
package App::Mojo::Schema::Result::Menu;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::Mojo::Schema::Result::Menu

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<menu>

=cut

__PACKAGE__->table("menu");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 title

  data_type: 'integer'
  default_value: 'menu_'
  is_nullable: 0

=head2 action

  data_type: 'text'
  default_value: '/'
  is_nullable: 0

=head2 parent_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "title",
  { data_type => "integer", default_value => "menu_", is_nullable => 0 },
  "action",
  { data_type => "text", default_value => "/", is_nullable => 0 },
  "parent_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<id_unique>

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->add_unique_constraint("id_unique", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-07-22 21:57:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZCjkNqiCnpiSXsVayBMJVg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
