package App::Mojo::User;

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

sub write_user {
    my ( $self, %args ) = @_;
    my $registered;
    try {
        $registered = $self->{schema}->resultset('User')->create(
            {
                first_name => $self->{first_name} // $args{first_name},
                last_name  => $self->{last_name}  // $args{last_name},
                email      => $self->{email}      // $args{email},
                password   => $self->{password}   // $args{password},
            }
        );
    }
    catch {
        print "hmmm ... " . $_ . "\n";
        if ( $_ =~ /UNIQUE constraint failed: user\.email/ ) {
            $registered =
              {     error => "The email "
                  . $self->{email}
                  . " exists in our registers." };
        }
        else { $registered = { error => "Can not execute the register." } }

    };
    return $registered;
}

sub read_user {
    my ( $self, %args ) = @_;
    my $registered;
		my $q = $self->{email} // $args{email};
    try {
        $registered = $self->{schema}->resultset('User')->search(
            {
                email => $q,
            }
        );
    }
    catch {
        print "hmmm ... " . $_ . "\n";
        $registered = { error => "Can not execute the search." };
    };
		if (!$registered->first){$registered = { error => "Your e-mail does not exist in our registers. Please Signup!" }}
    return $registered;
}

1;
