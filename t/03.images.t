#!perl -T
use strict;
use warnings;
use 5.006;
use Test::More;
use Image::Caa;

use Data::Dumper;

plan tests => 1;

use Image::Magick;

# load an image
my $img = "public/img/logo.png";

my $image = Image::Magick->new;
$image->Read($img);

# display it as ASCII Art

my $caa = new Image::Caa();

#my $caa = new Image::Caa(
#  driver => 'DriverCurses',
#  window => $window ,
#);
$caa->draw_bitmap( 0, 0, 40, 20, $image );

ok($image);
diag("Testing images under Curses.");

