#!perl -T
use strict;
use warnings;
use 5.006;
use Test::More;

use Data::Dumper;

plan tests => 1;

use App::Mojo::Content qw();

my $ct = new App::Mojo::Content;
my $list = $ct->get_last;
for ( $list->all){
print Dumper $_->title;
}

ok( $list );
diag("Testing app's model.");

