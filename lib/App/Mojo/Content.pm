package App::Mojo::Content;

use strict;
use warnings;
use App::Mojo::Schema qw();
use Try::Tiny;

use Data::Dumper;

sub new {
    my ( $class, %args ) = @_;
    $args{schema} = App::Mojo::Schema->connect('dbi:SQLite:db/appmojo.sqlite');
    return bless \%args, $class;
}

sub write_content {
    my ( $self, %args ) = @_;
    my $registered;
    try {
        $registered = $self->{schema}->resultset('Content')->create(
            {
                title   => $self->{title} // $args{title},
                content => $self->{content} // $args{content},
                date    => $self->{date} // $args{date},
                link    => $self->{link} // $args{link},
            }
        );
    }
    catch {
        print "hmmm ... " . $_ . "\n";
        if ( $_ =~ /UNIQUE constraint failed: content\.link/ ) {
            $registered =
              {     error => "The link "
                  . $self->{link}
                  . " exists in our registers." };
        }
        else { $registered = { error => "Can not execute the register." } }

    };
    return $registered;
}

sub read_content {
    my ( $self, %args ) = @_;
    my $registered;
    my $q = $self->{link} // $args{link};
    try {
        $registered = $self->{schema}->resultset('Content')->search(
            {
                link => $q,
            }
        );
    }
    catch {
        print "hmmm ... " . $_ . "\n";
        $registered = { error => "Can not execute the search." };
    };
    if ( !$registered->first ) {
        $registered =
          { error => "This link does not exist in our registers. Sorry!" };
    }
    return $registered;
}

# get 10 last
sub get_last {
    my ( $self, %args ) = @_;
    my $registered;
    # my $q = $self->{link} // $args{link};
    try {
        $registered = $self->{schema}->resultset('Content')->search(
            undef,
            {
                page => 1,     # page to return (defaults to 1)
                rows => 10,    # number of results per page
            },
        );

    }
    catch {
        print "hmmm ... " . $_ . "\n";
        $registered = { error => "Can not execute the search." };
    };
    if ( !$registered->first ) {
        $registered =
          { error => "No content in our registers. Sorry!" };
    }
    return $registered;
}

1;
