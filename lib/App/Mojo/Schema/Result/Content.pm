use utf8;
package App::Mojo::Schema::Result::Content;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

App::Mojo::Schema::Result::Content

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<content>

=cut

__PACKAGE__->table("content");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 content

  data_type: 'text'
  is_nullable: 1

=head2 date

  data_type: 'text'
  is_nullable: 1

=head2 link

  data_type: 'text'
  is_nullable: 0

=head2 image

  data_type: 'text'
  is_nullable: 1

=head2 sumary

  data_type: 'text'
  is_nullable: 1

=head2 format

  data_type: 'text'
  default_value: 'html'
  is_nullable: 0

=head2 history

  data_type: 'text'
  is_nullable: 1

=head2 state

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 views

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "content",
  { data_type => "text", is_nullable => 1 },
  "date",
  { data_type => "text", is_nullable => 1 },
  "link",
  { data_type => "text", is_nullable => 0 },
  "image",
  { data_type => "text", is_nullable => 1 },
  "sumary",
  { data_type => "text", is_nullable => 1 },
  "format",
  { data_type => "text", default_value => "html", is_nullable => 0 },
  "history",
  { data_type => "text", is_nullable => 1 },
  "state",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "views",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<link_unique>

=over 4

=item * L</link>

=back

=cut

__PACKAGE__->add_unique_constraint("link_unique", ["link"]);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2018-07-22 21:57:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rSSKnOUJvVef0shrZRZfWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
