#!perl 
use strict;
use warnings;
use 5.006;
use Test::More;

use File::Find;
use App::Mojo::TreeView;
use Data::Dumper;
use Data::TreeDumper;

plan tests => 1;

my $path0 = "./test/not/abc.txt";
my $path1 = "./test/yes/abc.txt";
my $path2 = "./test/not/abcd.txt";
my $path3 = "./test/abc.txt";
my $path4 = "./abc.txt";
my $path5 = "../abc.txt";
my $path6 = "/abc.txt";

#my $tree = []; 
my $node = new App::Mojo::TreeView();

print DumpTree $node->data;
#print Dumper $tree;

#find( \&wanted, $path );

#print Dumper $tree;
#print Dumper $node->{data};

$node->insert($path0);
$node->insert($path1);
#$node->insert($path2);
#$node->insert($path3);
#$node->insert($path4);
#$node->insert($path5);
#$node->insert($path6);

print DumpTree $node->data;

ok($node);
diag("Testing app's feature tree.");


__END__


sub wanted {
    my $name = $_;
    my $dir = $File::Find::dir;
		my $file;
    my ( $dev, $ino, $mode, $nlink, $uid, $gid ) = lstat($_);
    $file = {
        dir        => $dir,
        name       => $name,
        text       => $dir . "/" . $name,
        icon       => "glyphicon glyphicon-file",
        selectable => 1,
        state      => {
            expanded => 0,
        },
        color     => "#000000",
        backColor => "#FFFFFF",
        dev       => $dev,
        ino       => $ino,
        mode      => $mode,
        nlink     => $nlink,
        uid       => $uid,
        gid       => $gid,
    };
    if (-d) {
        $file->{isd}   = 1;
    }

    $file->{node} = [$level, $pos];
		push @$tree , $file;
		$pos++;
}


