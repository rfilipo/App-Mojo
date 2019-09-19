#!/usr/bin/env perl
# app_admin.pl
# Simple blog administration made with Curses::UI
# Based in the examples from the module
# Author: Monsenhor
use strict;
use warnings;
use File::Temp qw( :POSIX );
use lib "../lib";

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

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Curses::UI;

use App::Mojo::Content;
use App::Mojo::User;

# Create the root object.
my $cui = new Curses::UI(
    -color_support => 1,
    -clear_on_exit => 1,
    -debug         => $debug,
);

# Home App
my $current_state = 2;
my $selected_article;

# App windows
my %w = ();

# ----------------------------------------------------------------------
# main menu
# ----------------------------------------------------------------------

sub select_state($;) {
    my $nr = shift;
    $current_state = $nr;
    $w{$current_state}->focus;
}

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

    #    {
    #        -label => 'new article',
    #        -value => sub { select_state(4) }
    #    },
    #    {
    #        -label => '------------',
    #        -value => sub { }
    #    },
    #    {
    #        -label => 'users',
    #        -value => sub { select_state(10) }
    #    },
    {
        -label => 'quit program',
        -value => sub { exit(0) }
    },
  ],

  my $menus_menu = [
    {
        -label => 'list menus',
        -value => sub { select_state(5) }
    },
    {
        -label => 'new menu',
        -value => sub { select_state(6) }
    },
  ];

my $users_menu = [
    {
        -label => 'list users',
        -value => sub { select_state(7) }
    },
    {
        -label => 'user profile',
        -value => sub { select_state(8) }
    },
    {
        -label => 'new user',
        -value => sub { select_state(9) }
    },
];
my $menu = [
    { -label => 'file', -submenu => $file_menu },

    #    { -label => 'menus', -submenu => $menus_menu },
    #    { -label => 'users', -submenu => $users_menu },
];

$cui->add(
    'menu', 'Menubar',
    -menu => $menu,

    -bg => "blue",
    -fg => "black",
);

# ----------------------------------------------------------------------
# Create the explanation window
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
# the app state windows
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
# main page - never show
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

sub button_callback($;) {
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

$cui->set_binding( \&list_articles, "\cA" );

$w{1}->add(
    undef,
    'Buttonbox',
    -y       => 12,
    -buttons => [
        {
            -label   => "  list articles  ",
            -value   => "lets list articles!!",
            -onpress => \&button_callback,
        },
        {
            -label   => "  create a new article  ",
            -value   => "lets create a new one!",
            -onpress => \&button_callback,
        },
        {
            -label   => "  list users  ",
            -value   => "gona list users",
            -onpress => \&button_callback,
        },
    ],
    -bg     => "blue",
    -fg     => "black",
    -border => 1,
);

# ----------------------------------------------------------------------
# list articles
# ----------------------------------------------------------------------
my $art_ids    = [];
my $art_titles = {};
my $art_data   = {};

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

$w{2}->add(
    undef, 'Label',
    -fg   => "blue",
    -text => "select the article with the arrow keys or <J> and <K>\n"
      . "and press it using the <SPACE> or <ENTER> key. Edit with <CTRL> E."
);

my $userdata      = {};
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

$cui->set_binding( \&get_article, "\cE" );

my $article_title;
my $article_date;
my $article_image;
my $article_format;
my $article_link;
my $article_parent;
my $article_content;
my $article_sumary;

sub get_article {
    my $q = shift;

    # load article from userdata
    my $data = $articles_list->userdata()->{$selected_article};
    $article_title->text( $data->{title} );
    $article_date->text( $data->{date} );
    $article_image->text( $data->{image} );
    $article_format->text( $data->{format} );
    $article_link->text( $data->{link} );
    $article_parent->text("---");
    $article_sumary->text( $data->{sumary} );
    $article_content->text( $data->{content} );
    $article_content->userdata($data);
    select_state(4);
}

# ----------------------------------------------------------------------
# list users
# ----------------------------------------------------------------------

$w{3}->add( undef, 'Label',
        -text => "The checkbox can be used for selecting a true or false\n"
      . "value. If the checkbox is checked (a 'X' is inside it)\n"
      . "the value is true. <SPACE> and <ENTER> will toggle the\n"
      . "state of the checkbox, <Y> will check it and <N> will\n"
      . "uncheck it." );

=for comment

my $cb_no  = "The checkbox says: I don't like it :-(";
my $cb_yes = "The checkbox says: I do like it! :-)";

$w{3}->add(
    'checkboxlabel', 'Label',
    -y     => 8,
    -width => -1,
    -bold  => 1,
    -text  => "Check the checkbox please...",
);

$w{3}->add(
    undef,
    'Checkbox',
    -y        => 6,
    -checked  => 0,
    -label    => 'I like this Curses::UI demo so far!',
    -onchange => sub {
        my $cb    = shift;
        my $label = $cb->parent->getobj('checkboxlabel');
        $label->text( $cb->get ? $cb_yes : $cb_no );
    },
);

=cut

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
$article_title = $w{4}->add(
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
$article_date = $w{4}->add(
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
$article_image = $w{4}->add(
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
$article_format = $w{4}->add(
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
$article_link = $w{4}->add(
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

$article_parent = $w{4}->add(
    'parent', 'TextEntry',
    -sbborder => 1,
    -y        => 2,
    -x        => 59,
    -width    => 14,
);

$article_sumary = $w{4}->add(
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
    -onChange       => sub {
        my $te2 = shift;

        #my $te1 = $te2->parent->getobj('te1');
        #my $te3 = $te2->parent->getobj('te3');
        #$te1->text( $te2->get );
        #$te3->text( $te2->get );
        #$te1->pos( $te2->pos );
    },
);

$article_content = $w{4}->add(
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
    -onChange       => sub {
        my $me = shift;

        #my $te1 = $te2->parent->getobj('te1');
        #my $te3 = $te2->parent->getobj('te3');
        #$te1->text( $te2->get );
        #$te3->text( $te2->get );
        #$te1->pos( $te2->pos );
    },
);

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
    my $value = $article_content->root->dialog(
        -message => "A new story to edit.\n" . "Enjoy!",
        -buttons => ['ok'],
        -title   => 'New!',
        -bg      => "blue",
        -fg      => "black",
        -bfg     => "blue",
    );

}

sub revert_article {
    my $value = $article_content->root->dialog(
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
    my $data = $article_content->userdata();

    # save to db
    my $ct = new App::Mojo::Content;

    #my $a = $ct->read_content(link=>$article_link->text);
    my $a = $ct->{schema}->resultset('Content')->find( $data->{id} );

    $a->title( $article_title->text() );
    $a->date( $article_date->text() );
    $a->image( $article_image->text() );
    $a->format( $article_format->text() );
    $a->link( $article_link->text() );

    #$a->parent ( $article_parent->text() );
    $a->sumary( $article_sumary->text() );
    $a->content( $article_content->text() );

    $a->update;

    # show dialog result to user

=for comment
=cut

    my $value = $article_content->root->dialog(
        -message => "Your story was saved.\n" . "Good job!",
        -buttons => ['ok'],
        -title   => 'Saved!',
        -bg      => "blue",
        -fg      => "black",
        -bfg     => "blue",
    );
}

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
# Listbox demo
# ----------------------------------------------------------------------

my $values = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ];
my $labels = {
    1  => 'One',
    2  => 'Two',
    3  => 'Three',
    4  => 'Four',
    5  => 'Five',
    6  => 'Six',
    7  => 'Seven',
    8  => 'Eight',
    9  => 'Nine',
    10 => 'Ten',
};

$w{5}->add( undef, 'Label',
        -text => "The listbox can be used for selecting on or more options\n"
      . "out of a predefined list of options. <SPACE> and <ENTER> will\n"
      . "change the current selected option for a normal listbox and a\n"
      . "radiobuttonbox, They will toggle the state of the active option in\n"
      . "a multi-select listbox. In a multi-select listbox you can also\n"
      . "use <Y> and <N> to check or uncheck options. Press </> for a\n"
      . "'less'-like search through the list." );

sub listbox_callback() {
    my $listbox = shift;
    my $label   = $listbox->parent->getobj('listboxlabel');
    my @sel     = $listbox->get;
    @sel = ('<none>') unless @sel;
    my $sel = "selected: " . join( ", ", @sel );
    $label->text( $listbox->title . " $sel" );
}

$w{5}->add(
    undef, 'Listbox',
    -y          => 8,
    -padbottom  => 2,
    -values     => $values,
    -labels     => $labels,
    -width      => 20,
    -border     => 1,
    -title      => 'Listbox',
    -vscrollbar => 1,
    -onchange   => \&listbox_callback,
);

$w{5}->add(
    undef, 'Listbox',
    -y          => 8,
    -padbottom  => 2,
    -x          => 21,
    -values     => $values,
    -labels     => $labels,
    -width      => 20,
    -border     => 1,
    -multi      => 1,
    -title      => 'Multi-select',
    -vscrollbar => 1,
    -onchange   => \&listbox_callback,
);

$w{5}->add(
    undef, 'Radiobuttonbox',
    -y          => 8,
    -padbottom  => 2,
    -x          => 42,
    -values     => $values,
    -labels     => $labels,
    -width      => 20,
    -border     => 1,
    -title      => 'Radiobuttonbox',
    -vscrollbar => 1,
    -onchange   => \&listbox_callback,
);

$w{5}->add(
    'listboxlabel', 'Label',
    -y     => -1,
    -bold  => 1,
    -text  => "Select any option in one of the listboxes please....",
    -width => -1,
);

# ----------------------------------------------------------------------
# Popupmenu
# ----------------------------------------------------------------------

$w{6}->add( undef, 'Label',
    -text => "The popmenu is much like a standard listbox. The difference is\n"
      . "that only the currently selected value is visible (or ---- if\n"
      . "no value is yet selected). The list of possible values will be\n"
      . "shown as a separate popup windows if requested.\n"
      . "Press <ENTER> or <CURSOR-RIGHT> to open the popupbox and use\n"
      . "those same keys to select a value (or use <CURSOR-LEFT> to close\n"
      . "the popup listbox without selecting a value from it). Press\n"
      . "</> in the popup for a 'less'-like search through the list." );

$w{6}->add(
    undef,
    'Popupmenu',
    -y        => 9,
    -values   => $values,
    -labels   => $labels,
    -width    => 20,
    -onchange => sub {
        my $pm  = shift;
        my $lbl = $pm->parent->getobj('popupmenulabel');
        my $val = $pm->get;
        $val = "<undef>" unless defined $val;
        my $lab = $pm->{-labels}->{$val};
        $val .= " (label = '$lab')" if defined $lab;
        $lbl->text($val);
        $lbl->draw;
    },
);

$w{6}->add(
    undef, 'Label',
    -y    => 9,
    -x    => 21,
    -text => "--- selected --->"
);

$w{6}->add(
    'popupmenulabel', 'Label',
    -y     => 9,
    -x     => 39,
    -width => -1,
    -bold  => 1,
    -text  => "none"
);

=for comment


# ----------------------------------------------------------------------
# Progressbar
# ----------------------------------------------------------------------

$w{7}->add(
    'progressbarlabel', 'Label',
    -x      => -1,
    -y      => 3,
    -width  => 10,
    -border => 1,
    -text   => "the time"
);

$w{7}->add( undef, 'Label',
    -text =>
      "The progressbar can be used to provide some progress information\n"
      . "to the user of a program. Progressbars can be drawn in several\n"
      . "ways (see below for a couple of examples). In this example, I\n"
      . "just built a kind of clock (the values for the bars are \n"
      . "depending upon the current time)." );

$w{7}->add( undef, "Label", -y => 7, -text => "Showing value" );
$w{7}->add(
    'p1', 'Progressbar',
    -max       => 24,
    -x         => 15,
    -y         => 6,
    -showvalue => 1
);

$w{7}->add( undef, "Label", -y => 10, -text => "No centerline" );
$w{7}->add(
    'p2', 'Progressbar',
    -max          => 60,
    -x            => 15,
    -y            => 9,
    -nocenterline => 1
);

$w{7}->add( undef, "Label", -y => 13, -text => "No percentage" );
$w{7}->add(
    'p3', 'Progressbar',
    -max          => 60,
    -x            => 15,
    -y            => 12,
    -nopercentage => 1
);

sub progressbar_timer_callback($;) {
    my $cui = shift;
    my @l   = localtime;
    $w{7}->getobj('p1')->pos( $l[2] );
    $w{7}->getobj('p2')->pos( $l[1] );
    $w{7}->getobj('p3')->pos( $l[0] );
    $w{7}->getobj('progressbarlabel')
      ->text( sprintf( "%02d:%02d:%02d", @l[ 2, 1, 0 ] ) );
}

$cui->set_timer( 'progressbar_demo', \&progressbar_timer_callback, 1 );
$cui->disable_timer('progressbar_demo');

$w{7}->onFocus( sub { $cui->enable_timer('progressbar_demo') } );
$w{7}->onBlur( sub  { $cui->disable_timer('progressbar_demo') } );

# ----------------------------------------------------------------------
# Calendar
# ----------------------------------------------------------------------


$w{8}->add(
    undef, 'Label',
    -text => "The calendar can be used to select a date, somewhere between\n"
           . "the years 0 and 9999. It honours the transition from the\n"
	   . "Julian- to the Gregorian calender in 1752."
);

$w{8}->add(
    undef, 'Label',
    -y => 5, -x => 27,
    -text => "Use your cursor keys (or <H>, <J>, <K> and <L>)\n"
           . "to walk through the calender. Press <ENTER>\n"
	   . "or <SPACE> to select a date. Press <SHIFT+J> to\n"
	   . "go one month forward and <SHIFT+K> to go one\n"
	   . "month backward. Press <SHIFT+L> or <N> to go one\n"
	   . "year forward and <SHIFT+H> or <P> to go one year\n"
	   . "backward. Press <T> to go to today's date. Press\n"
	   . "<C> to go to the currently selected date."
);

$w{8}->add(
    'calendarlabel', 'Label',
    -y => 14, -x => 27,
    -bold => 1,
    -width => -1,
    -text => 'Select a date please...'
);

$w{8}->add(
    'calendar', 'Calendar',
    -y => 4, -x => 0,
    -border => 1,
    -onchange => sub {
        my $cal = shift;
	my $label = $cal->parent->getobj('calendarlabel'); 
	$label->text("You selected the date: " . $cal->get);
    },
);


# ----------------------------------------------------------------------
# Dialog::Basic
# ----------------------------------------------------------------------

$w{9}->add( undef, 'Label',
        -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
      . "The basic dialog is one of them. It consists of a dialog\n"
      . "showing a message and one or more buttons. Press the\n"
      . "buttons to see some examples of this." );

$w{9}->add(
    undef,
    'Buttonbox',
    -y       => 7,
    -buttons => [
        {
            -label   => "< Example 1 >",
            -onpress => sub {
                shift()->root->dialog("As basic as it gets");
            }
        },
        {
            -label   => "< Example 2 >",
            -onpress => sub {
                shift()->root->dialog(
                    -message => "Basic, but carrying a\n" . "title this time.",
                    -title   => 'Dialog::Basic demo',
                );
            }
        },
        {
            -label   => "< Example 3 >",
            -onpress => sub {
                my $b     = shift();
                my $value = $b->root->dialog(
                    -message => "Basic, but carrying a\n"
                      . "title and multiple buttons.",
                    -buttons => [ 'ok', 'cancel', 'yes', 'no' ],
                    -title   => 'Dialog::Basic demo',
                );
                $b->root->dialog(
                    -message => "The value for that\n" . "button was: $value",
                    -title   => "Value?"
                );
            }
        }
    ],
);

# ----------------------------------------------------------------------
# Dialog::Error
# ----------------------------------------------------------------------

$w{10}->add( undef, 'Label',
        -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
      . "The Error dialog is one of them. It consists of a dialog\n"
      . "showing an errormessage, an ASCII art exclamation sign\n"
      . "and one or more buttons. Press the buttons to see some\n"
      . "examples of this." );

$w{10}->add(
    undef,
    'Buttonbox',
    -y       => 7,
    -buttons => [
        {
            -label   => "< Example 1 >",
            -onpress => sub {
                shift()->root->error("Some error occurred, I guess...");
            }
        },
        {
            -label   => "< Example 2 >",
            -onpress => sub {
                shift()->root->error(
                    -message => "Unfortunately this program is\n"
                      . "unable to cope with the enless\n"
                      . "stream of bugs the programmer\n"
                      . "has induced!!!!",
                    -title => 'Serious trouble',
                );
            }
        },
        {
            -label   => "< Example 3 >",
            -onpress => sub {
                my $b     = shift();
                my $value = $b->root->error(
                    -message => "General error somewhere in the program\n"
                      . "Are you sure you want to continue?",
                    -buttons => [ 'yes', 'no' ],
                    -title   => 'Vague problem detected',
                );
                $b->root->dialog(
                    -message => "You do "
                      . ( $value ? '' : 'not ' )
                      . "want to continue.",
                    -title => "What did you answer?"
                );
            }
        }
    ],
);

# ----------------------------------------------------------------------
# Dialog::Filebrowser
# ----------------------------------------------------------------------

$w{11}->add( undef, 'Label',
        -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
      . "The Filebrowser dialog is one of them. Using this dialog\n"
      . "it is possible to select a file anywhere on the file-\n"
      . "system. Press the buttons below for a demo" );

$w{11}->add(
    undef,
    'Buttonbox',
    -y       => 7,
    -buttons => [
        {
            -label   => "< Load file >",
            -onpress => sub {
                my $cui  = shift()->root;
                my $file = $cui->loadfilebrowser(
                    -title => "Select some file",
                    -mask  => [
                        [ '.',      'All files (*)' ],
                        [ '\.txt$', 'Text files (*.txt)' ],
                        [ '\.pm$',  'Perl modules (*.pm)' ],
                    ],
                );
                $cui->dialog("You selected the file:\n$file")
                  if defined $file;
            }
        },
        {
            -label   => "< Save file (is fake) >",
            -onpress => sub {
                my $cui  = shift()->root;
                my $file = $cui->savefilebrowser("Select some file");
                $cui->dialog("You selected the file:\n$file")
                  if defined $file;
            }
        }
    ]
);

# ----------------------------------------------------------------------
# Dialog::Progress
# ----------------------------------------------------------------------

$w{12}->add( undef, 'Label',
        -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
      . "The Progress dialog is one of them. Using this dialog\n"
      . "it is possible to present some progress information to\n"
      . "the user. Press the buttons below for a demo." );

$w{12}->add(
    undef,
    'Buttonbox',
    -y       => 7,
    -buttons => [
        {
            -label   => "< Example 1 >",
            -onpress => sub {
                $cui->progress(
                    -min       => 0,
                    -max       => 700,
                    -title     => 'Progress dialog without a message',
                    -nomessage => 1,
                );

                for my $pos ( 0 .. 700 ) {
                    $cui->setprogress($pos);
                }
                sleep 1;
                $cui->noprogress;
            }
        },
        {
            -label   => "< Example 2 >",
            -onpress => sub {
                my $msg = "Counting from 0 to 700...\n";
                $cui->progress(
                    -min     => 0,
                    -max     => 700,
                    -title   => 'Progress dialog with a message',
                    -message => $msg,
                );

                for my $pos ( 0 .. 700 ) {
                    $cui->setprogress( $pos, $msg . $pos . " / 700" );
                }
                $cui->setprogress( undef, "Finished counting!" );
                sleep 1;
                $cui->noprogress;
            }
        }
    ]
);

# ----------------------------------------------------------------------
# Dialog::Status
# ----------------------------------------------------------------------

$w{13}->add( undef, 'Label',
        -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
      . "The Status dialog is one of them. Using this dialog\n"
      . "it is possible to present some status information to\n"
      . "the user. Press the buttons below for a demo." );

$w{13}->add(
    undef,
    'Buttonbox',
    -y       => 7,
    -buttons => [
        {
            -label   => "< Example 1 >",
            -onpress => sub {
                $cui->status("This is a status dialog...");
                sleep 1;
                $cui->nostatus;
            }
        },
        {
            -label   => "< Example 2 >",
            -onpress => sub {
                $cui->status( "A status dialog can contain\n"
                      . "more than one line, but that is\n"
                      . "about all that can be told about\n"
                      . "status dialogs I'm afraid :-)" );
                sleep 3;
                $cui->nostatus;
            }
        }
    ]
);

# ----------------------------------------------------------------------
# Dialog::Calendar
# ----------------------------------------------------------------------

$w{14}->add( undef, 'Label',
        -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
      . "The calendar dialog is one of them. Using this dialog\n"
      . "it is possible to select a date." );

$w{14}->add( undef, 'Label', -y => 7, -text => 'Date:' );
$w{14}->add(
    'datelabel', 'Label',
    -width => 10,
    -y     => 7,
    -x     => 6,
    -text  => 'none',
);

$w{14}->add(
    undef,
    'Buttonbox',
    -y       => 7,
    -x       => 17,
    -buttons => [
        {
            -label   => "< Set date >",
            -onpress => sub {
                my $label = shift()->parent->getobj('datelabel');
                my $date  = $label->get;
                print STDERR "$date\n";
                $date = undef if $date eq 'none';
                my $return = $cui->calendardialog( -date => $date );
                $label->text($return) if defined $return;
            }
        },
        {
            -label   => "< Clear date >",
            -onpress => sub {
                my $label = shift()->parent->getobj('datelabel');
                $label->text('none');
            }
        }
    ]
);

# ----------------------------------------------------------------------
# Dialog::Question
# ----------------------------------------------------------------------

$w{15}->add( undef, 'Label',
        -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
      . "The question dialog is one of them. Using this dialog\n"
      . "it is possible to prompt the user to enter an answer.", );

$w{15}->add(
    undef,
    'Buttonbox',
    -y       => 7,
    -buttons => [
        {
            -label   => "< Example 1 >",
            -onpress => sub {
                my $button  = shift;
                my $feeling = $button->root->question("How awesome are you?");
                if ($feeling) {
                    $button->root->dialog("You answered '$feeling'");
                }
                else {
                    $button->root->dialog("Question cancelled.");
                }
            }
        },
        {
            -label   => "< Example 2 >",
            -onpress => sub {
                my $button  = shift;
                my $feeling = $button->root->question(
                    -question => "How does coffee make you feel?",
                    -title    => 'Dialog::Question example',
                );
                if ($feeling) {
                    $button->root->dialog("You answered '$feeling'");
                }
                else {
                    $button->root->dialog("Question cancelled.");
                }
            }
        },
        {
            -label   => "< Example 3 >",
            -onpress => sub {
                my $button  = shift;
                my $feeling = $button->root->question(
                    -question => "How does coffee make you feel?",
                    -title    => 'Dialog::Question example',
                    -answer   => "Really good.",
                );
                if ($feeling) {
                    $button->root->dialog("You answered '$feeling'");
                }
                else {
                    $button->root->dialog("Question cancelled.");
                }
            }
        }
    ],
);

=cut

# ----------------------------------------------------------------------
# Setup bindings and focus
# ----------------------------------------------------------------------

# Bind <CTRL+Q> to quit.
$cui->set_binding( sub { exit }, "\cQ" );

# Bind <CTRL+X> to menubar.
$cui->set_binding( sub { shift()->root->focus('menu') }, "\cX" );

sub goto_next_state() {
    $current_state++;
    $current_state = @screens if $current_state > @screens;
    $w{$current_state}->focus;
}
$cui->set_binding( \&goto_next_state, "\cN" );

sub goto_prev_state() {
    $current_state--;
    $current_state = 1 if $current_state < 1;
    $w{$current_state}->focus;
}

$cui->set_binding( \&goto_prev_state, "\cP" );

&list_articles();

$w{$current_state}->focus;

# ----------------------------------------------------------------------
# Get things rolling...
# ----------------------------------------------------------------------

$cui->mainloop;

