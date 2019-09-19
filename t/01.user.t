#!perl -T
use strict;
use warnings;
use 5.006;
use Test::More;

use Data::Dumper;

plan tests => 1;

use App::Mojo::Schema qw();
my $schema     = App::Mojo::Schema->connect('dbi:SQLite:db/appmojo.sqlite');
my $q = 'k@k';
my $registered = $schema->resultset('User')->search(
    {
        email => $q,
    }
);
print $registered->first->first_name . "\n";

ok( $registered->first->first_name );
diag("Testing app's model.");

