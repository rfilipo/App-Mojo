#!/usr/bin/env perl
# app_admin.pl
# Simple blog administration made with Curses::UI
# Based in the examples from the module by Shawn Boyette
# Author: Monsenhor

use strict;
use warnings;
use File::Temp qw( :POSIX );

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Curses::UI;

use App::Mojo::Content;
use App::Mojo::User;

#   make KEY_BTAB (shift-tab) working in XTerm
#   and also at the same time enable colors
$ENV{TERM} = "xterm-vt220" if ( $ENV{TERM} eq 'xterm' );

my $debug = 0;
if ( @ARGV and $ARGV[0] eq '-d' ) {
    my $fh = tmpfile();
    open STDERR, ">&fh";
    $debug = 1;
}
else {
    # We do not want STDERR to clutter our screen.
    my $fh = tmpfile();
    open STDERR, ">&fh";
}

################################################
# model structure
################################################

my $current_state = 2;  # the focused screen
my %w = ();             # the screens
my $userdata      = {}; # the data in some screens for callbacks

# articles
# --------
my $selected_article;   # selected article from list
my $the_article = {     # prepared data for db use/save/retrieve
    id       => undef,
    title    => undef,
    date     => undef,
    image    => undef,
    format   => undef,
    link     => undef,
    parent   => undef,
    user_id  => undef,
    history  => undef,
    content  => undef,
    sumary   => undef,
    views    => undef 
};
# aux var
my $art_ids    = [];
my $art_titles = {};
my $art_data   = {};
# the view objects
my %view_art = (
    title    => undef,
    date     => undef,
    user_id  => undef,
    image    => undef,
    sumary   => undef,
    format   => undef,
    link     => undef,
    parent   => undef,
    history  => undef,
    content  => undef,
);

# users
# --------
my $selected_user;      # selected user from list
my $the_user = {        # prepared data for db use/save/retrieve
    "id"=> undef,
    "first_name"=> undef,
    "last_name"=> undef,
    "email"=> undef,
    "password"=> undef,
    "auth"=> undef,
    "verified"=> undef,
    "phones"=> undef,
};
my $view_user = {
    "first_name"=> undef,
    "last_name"=> undef,
    "email"=> undef,
    "password"=> undef,
    "phones"=> undef,
};
# server
# --------
my $the_server = {  # prepared data for server control
    command => undef,
		args    => undef,
};


###################################################
# UI - view structure
###################################################

# root object.
my $cui = new Curses::UI(
    -color_support => 1,
    -clear_on_exit => 1,
    -debug         => $debug,
);

# ----------------------------------------------------------------------
# menu bar
# ----------------------------------------------------------------------

my $file_menu = [
    {
        -label => 'list articles',
        -value => sub { list_articles() }
    },
    {
        -label => 'edit article',
        -value => sub {
            if ($selected_article) {
                get_article();
            }
            else {
                list_articles();
            }
        }
    },
		{
        -label => 'main page',
        -value => sub { select_state(1); }
    },
		{
        -label => 'server control',
        -value => sub { select_state(6); }
    },
    {
        -label => 'quit program',
        -value => sub { exit(0) }
    },
];

my $menu = [
    { -label => 'file', -submenu => $file_menu },
];

$cui->add(
    'menu', 'Menubar',
    -menu => $menu,

    -bg => "blue",
    -fg => "black",
);

# ----------------------------------------------------------------------
# message bar
# ----------------------------------------------------------------------

my $w0 = $cui->add(
    'w0', 'Window',
    -border => 1,
    -y      => -1,
    -height => 3,
    -bg     => "blue",
    -fg     => "black",
    -bfg    => "blue",
);
$w0->add( 'explain', 'Label',
    -text => "CTRL+A: list articles  CTRL+E: edit article  "
      . "CTRL+X: menu  CTRL+Q: quit" );

# ----------------------------------------------------------------------
# the screens
# ----------------------------------------------------------------------

my %screens = (
    '1' => 'home',
    '2' => 'list articles',
    '3' => 'list users',
    '4' => 'article editor',
    '5' => 'user editor',
    '6' => 'app control',
);

my @screens = sort { $a <=> $b } keys %screens;

my %args = (
    -border       => 0,
    -titlereverse => 1,
    -padtop       => 2,
    -padbottom    => 3,
    -ipad         => 0,
    -tbg          => "blue",
    -tfg          => "black",
    -bfg          => "blue",
);

while ( my ( $nr, $title ) = each %screens ) {
    my $id = "window_$nr";
    $w{$nr} = $cui->add(
        $id, 'Window',

        #-title => "Mojo::App admin: $title ($nr/" . @screens . ")",
        -titlefullwidth => 1,
        -title          => ": $title",
        %args
    );
}

# ----------------------------------------------------------------------
# main page
# ----------------------------------------------------------------------

$w{1}->add(
    undef, 'Label',
    -text => "App::Mojo admin\n"
      . "Hackerish blog administration interface.\n"
      . "The best mojo made for your terminal pleasure!",

    #-bg => "black",
    -fg    => "blue",
    -ipad  => 0,
    -width => -1,
);

$w{1}->add(
    'buttonlabel', 'Label',
    -y     => 8,
    -width => -1,
    -bold  => 1,
    -text  => "Edit your stories here!",

    #-bg => "black",
    -fg => "blue",
);

$w{1}->add(
    undef,
    'Buttonbox',
    -y       => 12,
    -buttons => [
        {
            -label   => "  list articles  ",
            -value   => "lets list articles!!",
            -onpress => \&ihome_button_callback,
        },
        {
            -label   => "  create a new article  ",
            -value   => "lets create a new one!",
            -onpress => \&home_button_callback,
        },
        {
            -label   => "  list users  ",
            -value   => "gona list users",
            -onpress => \&home_button_callback,
        },
    ],
    -bg     => "blue",
    -fg     => "black",
    -border => 1,
);

# ----------------------------------------------------------------------
# list articles
# ----------------------------------------------------------------------

$w{2}->add(
    undef, 'Label',
    -fg   => "blue",
    -text => "select the article with the arrow keys or <J> and <K>\n"
      . "and press it using the <SPACE> or <ENTER> key. Edit with <CTRL> E."
);

my $articles_list = $w{2}->add(
    undef, 'Listbox',
    -y => 3,

    #-padbottom  => 2,
    -values   => $art_ids,
    -labels   => $art_titles,
    -userdata => $userdata,
    -width    => 30,
    -border   => 1,
    -bfg      => "blue",

    #-bg => "blue",
    -fg => "blue",

    #-title      => 'articles',
    -vscrollbar => 1,
    -onchange   => \&list_articles_callback,

    #    -onselchange   => \&list_articles_callback,
    #    -onfocus   => \&list_articles_callback,
);

my $article_sinopsys = $w{2}->add(
    'articleSinopsys', 'Label',
    -y      => 3,
    -x      => 31,
    -bold   => 1,
    -text   => "Select the article to see a sinopsys.\n\n\n\n\n\n ...\n",
    -width  => -1,
    -height => 10,
    -border => 1,
    -bfg    => "blue",
);

$w{2}->add(
    undef,
    'Buttonbox',
    -x       => 31,
    -y       => 13,
    -width   => 20,
    -border  => 1,
    -bfg     => "blue",
    -buttons => [
        {
            -label   => "edit",
            -onpress => sub {
                if ($selected_article) {
                    get_article();
                }
                else {
                    list_articles();
                }

            }
        },
        {
            -label   => "new",
            -onpress => sub {
                if ($selected_article) {
                    get_article();
                }
                else {
                    list_articles();
                }

            }
        },
    ],
    -bg => "blue",
    -fg => "black",
);

# ----------------------------------------------------------------------
# list users
# ----------------------------------------------------------------------

$w{3}->add( undef, 'Label',
        -text => "Implement me!\n"
      . "Please!" );

# ----------------------------------------------------------------------
# edit article
# ----------------------------------------------------------------------

$w{4}->add(
    'titleLabel', 'Label',
    -y     => 0,
    -text  => "title:",
    -width => 6,
    -bg    => "black",
    -fg    => "blue",
);
$view_art{title} = $w{4}->add(
    'title', 'TextEntry',
    -sbborder => 1,
    -y        => 0,
    -x        => 10,
    -width    => 40,
);

$w{4}->add(
    'dateLabel', 'Label',
    -x     => 52,
    -y     => 0,
    -text  => "date:",
    -width => 6,
    -bg    => "black",
    -fg    => "blue",
);
$view_art{date} = $w{4}->add(
    'date', 'TextEntry',
    -sbborder => 1,
    -y        => 0,
    -x        => 59,
    -width    => 14,
);

$w{4}->add(
    'imageLabel', 'Label',
    -y     => 1,
    -text  => "image:",
    -width => 6,
    -bg    => "black",
    -fg    => "blue",
);
$view_art{image} = $w{4}->add(
    'image', 'TextEntry',
    -sbborder => 1,
    -y        => 1,
    -x        => 10,
    -width    => 40,
);

$w{4}->add(
    'formatLabel', 'Label',
    -x     => 52,
    -y     => 1,
    -text  => "format:",
    -width => 7,
    -bg    => "black",
    -fg    => "blue",
);
$view_art{format} = $w{4}->add(
    'format', 'TextEntry',
    -sbborder => 1,
    -y        => 1,
    -x        => 59,
    -width    => 14,
);

$w{4}->add(
    'linkLabel', 'Label',
    -y     => 2,
    -text  => "link:",
    -width => 6,
    -bg    => "black",
    -fg    => "blue",
);
$view_art{link} = $w{4}->add(
    'link', 'TextEntry',
    -sbborder => 1,
    -y        => 2,
    -x        => 10,
    -width    => 40,
);

$w{4}->add(
    'parentLabel', 'Label',
    -x     => 52,
    -y     => 2,
    -text  => "parent:",
    -width => 7,
    -bg    => "black",
    -fg    => "blue",
);

$view_art{parent} = $w{4}->add(
    'parent', 'TextEntry',
    -sbborder => 1,
    -y        => 2,
    -x        => 59,
    -width    => 14,
);

$view_art{sumary} = $w{4}->add(
    'articleSumary',
    'TextEditor',
    -tbg            => "blue",
    -tfg            => "black",
    -title          => 'summary',
    -titlefullwidth => 1,
    -y              => 4,
    -x              => 0,
    -width          => -1,
    -height         => 4,
    -border         => 1,
    -bfg            => "blue",
    -padbottom      => 3,
    -vscrollbar     => 1,
    -hscrollbar     => 1,
    -wrapping       => 1,
    #-onChange       => sub {
    #    my $te2 = shift;
        #my $te1 = $te2->parent->getobj('te1');
        #my $te3 = $te2->parent->getobj('te3');
        #$te1->text( $te2->get );
        #$te3->text( $te2->get );
        #$te1->pos( $te2->pos );
    #},
);

$view_art{content} = $w{4}->add(
    'articleContent',
    'TextEditor',
    -tbg            => "blue",
    -tfg            => "black",
    -title          => 'content',
    -titlefullwidth => 1,
    -y              => 8,
    -x              => 0,
    -width          => -1,
    -border         => 1,
    -bfg            => "blue",
    -padbottom      => 3,
    -vscrollbar     => 1,
    -hscrollbar     => 1,
    -wrapping       => 1,
    #-onChange       => sub {
    #    my $me = shift;
        #my $te1 = $te2->parent->getobj('te1');
        #my $te3 = $te2->parent->getobj('te3');
        #$te1->text( $te2->get );
        #$te3->text( $te2->get );
        #$te1->pos( $te2->pos );
    #},
);

$w{4}->add(
    undef,
    'Buttonbox',
    -y       => -1,
    -buttons => [
        {
            -label   => "save  ",
            -value   => "saving article!!",
            -onpress => \&editor_callback,
        },
        {
            -label   => "  revert  ",
            -value   => "revert to saved one!",
            -onpress => \&editor_callback,
        },
        {
            -label   => "  new  ",
            -value   => "gona create a new story!",
            -onpress => \&editor_callback,
        },
    ],
    -bg     => "blue",
    -fg     => "black",
    -bfg    => "blue",
    -border => 1,
    ipad    => 1,
);

# ----------------------------------------------------------------------
# user profile
# ----------------------------------------------------------------------

$w{5}->add( undef, 'Label',
        -text => "Implement me!\n"
      . "Please!" );


# ----------------------------------------------------------------------
# control program
# ----------------------------------------------------------------------

$w{6}->add( undef, 'Label',
        -text => "Implement me!\n"
      . "Please!" );

# ----------------------------------------------------------------------
# Setup bindings and focus
# ----------------------------------------------------------------------

# Bind <CTRL+Q> to quit.
$cui->set_binding( sub { exit }, "\cQ" );

# Bind <CTRL+X> to menubar.
$cui->set_binding( sub { shift()->root->focus('menu') }, "\cX" );

$cui->set_binding( \&list_articles, "\cA" );
$cui->set_binding( \&goto_next_state, "\cN" );
$cui->set_binding( \&goto_prev_state, "\cP" );
$cui->set_binding( \&get_article, "\cE" );

# ----------------------------------------------------------------------
# Get things rolling...
# ----------------------------------------------------------------------

&list_articles();
$w{$current_state}->focus;
$cui->mainloop;

########################################################################
# control structures
########################################################################

sub select_state($;) {
    my $nr = shift;
    $current_state = $nr;
    $w{$current_state}->focus;
}

sub goto_prev_state() {
    $current_state--;
    $current_state = 1 if $current_state < 1;
    $w{$current_state}->focus;
}

sub goto_next_state() {
    $current_state++;
    $current_state = @screens if $current_state > @screens;
    $w{$current_state}->focus;
}

sub home_button_callback($;) {
    my $this  = shift;
    my $label = $this->parent->getobj('buttonlabel');
    $label->text( "Doing: " . $this->get );
    if ( $this->get eq 'lets list articles!!' ) {
        list_articles();
    }
    if ( $this->get eq "lets create a new one!" ) {
        select_state(4);
    }
    if ( $this->get eq "gona list users" ) {
        select_state(3);
    }
}

sub list_articles_callback() {
    my $listbox = shift;
    my $label   = $listbox->parent->getobj('articleSinopsys');
    my @sel     = $listbox->get;
    @sel = ('<none>') unless @sel;
    my $sel = "link: " . join( ", ", @sel );
    my $s = $sel[0];
    $selected_article = $s;
    my $date   = $listbox->userdata->{$s}->{date} // "<nodate>";
    my $sumary = $listbox->userdata->{$s}->{sumary} // "<nosumary>";

    $label->text( $sel . "\n" . "- " . $date . "\n" . "- " . $sumary );
}


sub list_articles {

    # load articles from db
    my $ct   = new App::Mojo::Content;
    my $list = $ct->get_last;
    $art_ids    = [];
    $art_titles = {};
    $art_data   = {};

    # fill page with data
    for ( $list->all ) {
        push @$art_ids, $_->link;
        $art_titles->{ $_->link } = $_->title;
        $art_data->{ $_->link }   = {
            id      => $_->id,
            link    => $_->link,
            title   => $_->title,
            sumary  => $_->sumary,
            image   => $_->image,
            format  => $_->format,
            date    => $_->date,
            state   => $_->state,
            views   => $_->views,
            content => $_->content,
        };
    }
    $articles_list->values($art_ids);
    $articles_list->labels($art_titles);
    $articles_list->userdata($art_data);

    # load page
    select_state(2);
}

sub get_article {
    my $q = shift;

    # load article from userdata
    my $data = $articles_list->userdata()->{$selected_article};
    $view_art{title}->text( $data->{title} );
    $view_art{date}->text( $data->{date} );
    $view_art{image}->text( $data->{image} );
    $view_art{format}->text( $data->{format} );
    $view_art{link}->text( $data->{link} );
    $view_art{parent}->text("---");
    $view_art{sumary}->text( $data->{sumary} );
    $view_art{content}->text( $data->{content} );
    $view_art{content}->userdata($data);
    select_state(4);
}

sub editor_callback($;) {
    my $this = shift;

    #my $label = $this->parent->getobj('editorLabel');
    #$label->text( "Doing: " . $this->get );
    if ( $this->get eq 'saving article!!' ) {
        save_article();
    }
    if ( $this->get eq "revert to saved one!" ) {
        revert_article();
    }
    if ( $this->get eq "gona create a new story!" ) {
        new_article();
    }
}

sub new_article {
    my $value = $view_art{content}->root->dialog(
        -message => "A new story to edit.\n" . "Enjoy!",
        -buttons => ['ok'],
        -title   => 'New!',
        -bg      => "blue",
        -fg      => "black",
        -bfg     => "blue",
    );

}

sub revert_article {
    my $value = $view_art{content}->root->dialog(
        -message => "Your story was reverted.\n" . "to the last version saved.",
        -buttons => ['ok'],
        -title   => 'Reverted!',
        -bg      => "blue",
        -fg      => "black",
        -bfg     => "blue",
    );

}

sub save_article {

    # load article from editor
    my $data = $view_art{content}->userdata();

    # save to db
    my $ct = new App::Mojo::Content;

    #my $a = $ct->read_content(link=>$view_art{link}->text);
    my $a = $ct->{schema}->resultset('Content')->find( $data->{id} );

    $a->title( $view_art{title}->text() );
    $a->date( $view_art{date}->text() );
    $a->image( $view_art{image}->text() );
    $a->format( $view_art{format}->text() );
    $a->link( $view_art{link}->text() );

    #$a->parent ( $view_art{parent}->text() );
    $a->sumary( $view_art{sumary}->text() );
    $a->content( $view_art{content}->text() );

    $a->update;

    my $value = $cui->dialog(
        -message => "Your story was saved.\n" . "Good job!",
        -buttons => ['ok'],
        -title   => 'Saved!',
        -bg      => "blue",
        -fg      => "black",
        -bfg     => "blue",
    );
}

