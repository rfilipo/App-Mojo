#!/usr/bin/env perl
use Mojolicious::Lite;

use Crypt::Digest::SHA1;
use Data::Dumper;

use lib 'lib';
use App::Mojo::User;
use App::Mojo::Content;

# Using the trader.conf file
plugin 'Config';

#show config
my $config = plugin('Config');

#print Dumper $config."\n";

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

if ( my $secrets = app->config->{secrets} ) {
    app->secrets($secrets);
}

# special mime types
app->types->type(md => 'text/markdown');

# It's bootstrap navibar
my $the_app_menu = [
    { title => 'home',   url => "/" },
    { title => 'about',  url => "/about" },
    { title => 'help',   url => "/help" },
    { title => 'app',    url => "/app" },
    { title => 'logon',  url => "/logon" },
    { title => 'logout', url => "/logout" }
];

# It's bootstrap navibar
my $the_menu = [
    { title => 'home',  url => "/" },
    { title => 'about', url => "/about" },
    { title => 'help',  url => "/help" },

    #{ title => 'app',    url => "/app" },
    #{ title => 'logon',  url => "/logon" },
    #{ title => 'logout', url => "/logout" }
];

# Routes

get '/' => sub {
    my $c  = shift;
    my $ct = App::Mojo::Content->new;
    my $r  = $ct->get_last();

    #use Data::Dumper;
    #print Dumper $r;
    $c->stash( links => $r );
    $c->stash( menu => $the_menu, format => 'html' );
    $c->render( template => 'index' );
};

get '/page/:link' => sub {
    my $c  = shift;
    my $ct = App::Mojo::Content->new;
    my $r  = $ct->read_content( link => $c->stash('link') );
    $c->stash( links => $r );
    $c->stash( menu => $the_menu, format => 'html' );
    $c->render( template => 'page' );
};

post '/json' => sub {
    my $c    = shift;
    my $hash = $c->req->json;

    my $result = {error=>"Unknown Error"};

    # loadsections gets contents section tree for filling 
		# bootstrap treeview component
    #
    if ( $hash->{command} eq "loadsections" ) {
      my $ct = App::Mojo::Content->new;
      $result = $ct->get_last();
    }
    $c->render( json => $result );
};

get '/about' => sub {
    my $c = shift;
    $c->stash( menu => $the_menu, format => 'html' );
};

get '/help' => sub {
    my $c = shift;
    $c->stash( menu => $the_menu, format => 'html' );
};

app->start;
