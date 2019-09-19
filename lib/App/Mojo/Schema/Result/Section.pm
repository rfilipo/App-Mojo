use utf8;
package App::Mojo::Schema::Result::Section;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::Mojo::Schema::Result::Section

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<section>

=cut

__PACKAGE__->table("section");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 content_id

  data_type: 'integer'
  is_nullable: 1

=head2 parent_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "content_id",
  { data_type => "integer", is_nullable => 1 },
  "parent_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-07-22 21:57:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SPxgak/OA+MkAV6alYRjeg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
