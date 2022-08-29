use v5.18;
use warnings;
use Wx;
use utf8;

# circular color flow
# additional pendulum
# reihen speichern
# undo
# speicher für letzten graphike und farben

package App::Harmonograph::GUI;
my $VERSION = 0.14;
use base qw/Wx::App/;
use App::Harmonograph::GUI::Pendulum;
use App::Harmonograph::GUI::Color;
use App::Harmonograph::GUI::Board;

sub OnInit {
    my $app   = shift;
    my $frame = Wx::Frame->new( undef, -1, 'Harmonograph '.$VERSION , [-1,-1], [-1,-1]);
    $frame->SetIcon( Wx::GetWxPerlIcon() );
    $frame->CreateStatusBar( 2 );
    $frame->SetStatusWidths(2, 800, 100);
    $frame->SetStatusText( "Harmonograph", 1 );

    my $btnw = 50; my $btnh = 40;# button width and height
    $frame->{'btn'}{'new'}   = Wx::Button->new( $frame, -1, '&New',    [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'open'}  = Wx::Button->new( $frame, -1, '&Open',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'write'} = Wx::Button->new( $frame, -1, '&Write',  [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'draw'}  = Wx::Button->new( $frame, -1, '&Draw',   [-1,-1],[$btnw, $btnh] );
    $frame->{'btn'}{'save'}  = Wx::Button->new( $frame, -1, '&Save',   [-1,-1],[$btnw, $btnh] );
    #$frame->{'btn'}{'exit'}  = Wx::Button->new( $frame, -1, '&Exit',   [-1,-1],[$btnw, $btnh] );
    #$frame->{'btn'}{'tips'}  = Wx::ToggleButton->new($frame,-1,'&Tips',[-1,-1],[$btnw, $btnh] );

    $frame->{'btn'}{'new'} ->SetToolTip('put all settings to default');
    $frame->{'btn'}{'open'}->SetToolTip('load image settings from a text file');
    $frame->{'btn'}{'write'}->SetToolTip('save image settings into text file');
    $frame->{'btn'}{'draw'}->SetToolTip('redraw the harmonographic image');
    $frame->{'btn'}{'save'}->SetToolTip('save image into SVG file');
    #$frame->{'btn'}{'exit'}->SetToolTip('close the application');

    $frame->{'pendulum'}{'x'}  = App::Harmonograph::GUI::Pendulum->new( $frame, 'x','pendulum in x direction (left to right)', 1, 30);
    $frame->{'pendulum'}{'y'}  = App::Harmonograph::GUI::Pendulum->new( $frame, 'y','pendulum in y direction (left to right)', 1, 30);
    $frame->{'pendulum'}{'z'}  = App::Harmonograph::GUI::Pendulum->new( $frame, 'z','circular pendulum in z direction',        0, 30);
    
    $frame->{'color'}{'start'}  = App::Harmonograph::GUI::Color->new( $frame, 'start', { r => 20, g => 20, b => 110 } );
    $frame->{'color'}{'target'} = App::Harmonograph::GUI::Color->new( $frame, 'end',  { r => 110, g => 20, b => 20 } );
    
    $frame->{'cmb'}{'time'} = App::Harmonograph::GUI::SliderCombo->new( $frame, 80, 'Time','length of drawing in full circles',     1,  150,  10);
    $frame->{'cmb'}{'dt'} = App::Harmonograph::GUI::SliderCombo->new( $frame, 80, 'Dense','x 10 pixel per circle',  1,  400,  100);
    $frame->{'cmb'}{'ps'}  = Wx::ComboBox->new( $frame, -1, 1, [-1,-1],[65, -1], [1,2,3,4,5,6,7,8], 1);
    $frame->{'cmb'}{'ps'}->SetToolTip('dot size in pixel');
    $frame->{'cmb'}{'cftype'}  = Wx::ComboBox->new( $frame, -1, 'no', [-1,-1], [105, -1], [qw/no linear circular/] );
    $frame->{'cmb'}{'cftype'}->SetToolTip('choose between no color flow, linear color flow between start and end color or circular (start to end, back and again)');
    $frame->{'cmb'}{'stepsize'} = App::Harmonograph::GUI::SliderCombo->new( $frame, 100, 'Step Size','after how many circles does color change', 1, 100, 1);

    $frame->{'board'}    = App::Harmonograph::GUI::Board->new($frame, 600, 600);

    Wx::ToolTip::Enable(1);
    Wx::Event::EVT_LEFT_DOWN( $frame->{'board'}, sub {  });
    Wx::Event::EVT_RIGHT_DOWN( $frame->{'board'}, sub {
        my ($panel, $event) = @_;
        return unless $frame->{'editable'};
        my ($mx, $my) = ($event->GetX, $event->GetY);
        my $c = 1 + int(($mx - 15)/52);
        my $r = 1 + int(($my - 16)/57);
        return if $r < 1 or $r > 9 or $c < 1 or $c > 9;
        return if $frame->{'game'}->cell_solution( $r, $c );
        my $cand_menu = Wx::Menu->new();
        $cand_menu->AppendCheckItem($_,$_) for 1..9;
        my $nr;
        for (1 .. 9) {$cand_menu->Check($_, 1),$nr++ if $frame->{'game'}->is_cell_candidate($r,$c,$_) }
        return if $nr < 2;
        my $digit = $panel->GetPopupMenuSelectionFromUser( $cand_menu, $event->GetX, $event->GetY);
        return unless $digit > 0;
        $frame->{'game'}->remove_candidate($r, $c, $digit, 'set by app user');
        update_game( $frame );
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'new'}, sub { $app->reset($frame) });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'open'}, sub {
        my $s = shift;
        my $dialog = Wx::FileDialog->new ( $frame, "Select a file", './beispiel', './beispiel/schwer.txt',
                   ( join '|', 'Sudoku files (*.txt)|*.txt', 'All files (*.*)|*.*' ), &Wx::wxFD_OPEN|&Wx::wxFD_MULTIPLE );
        if( $dialog->ShowModal == &Wx::wxID_CANCEL ) {}
        else {
            $frame->{'game'} = $frame->{'board'}{'game'} =  Games::Sudoku::Solver::Strategy::Game->new();
            my @paths = $dialog->GetPaths;
            $frame->{'game'}->load($paths[0]);
            $frame->SetStatusText( "loaded $paths[0]", 0 );
    }});
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'write'},  sub {
        my $dialog = Wx::FileDialog->new ( $frame, "Select a file name to store data", '.', '',
                   ( join '|', 'SVG files (*.tsv)|*.tsv', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        if( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
            my @paths = $dialog->GetPaths;
            open my $FH, '>', $paths[0] or return $frame->SetStatusText( "could not write $paths[0]", 0 );
            my $data = get_data($frame);
            say $FH '[x]';
            say $FH '[y]';
            say $FH '[z]';
            close $FH;
            $frame->SetStatusText( "saved data into $paths[0]", 0 );
        }
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'draw'},  sub { $app->draw( $frame ) });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'save'},  sub {
        my $dialog = Wx::FileDialog->new ( $frame, "select a file name to save image", '.', '',
                   ( join '|', 'SVG files (*.svg)|*.svg', 'All files (*.*)|*.*' ), &Wx::wxFD_SAVE );
        if( $dialog->ShowModal != &Wx::wxID_CANCEL ) {
            my @paths = $dialog->GetPaths;
            $frame->{'board'}->save_file( $paths[0] );
            $frame->SetStatusText( "saved $paths[0]", 0 );
        }
    });
    Wx::Event::EVT_BUTTON( $frame, $frame->{'btn'}{'exit'},  sub { $frame->Close; } );


    my $cmd_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $cmd_sizer->Add( 5, 0, &Wx::wxEXPAND);
    $cmd_sizer->Add( $frame->{'btn'}{$_}, 0, &Wx::wxGROW|&Wx::wxALL, 10 ) for qw/new open write save draw /; # exit 
    $cmd_sizer->Insert( 4, 40, 0 );
   # $cmd_sizer->Insert( 6, 40 );
    $cmd_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $board_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $board_sizer->Add( $frame->{'board'}, 0, &Wx::wxGROW|&Wx::wxALL, 10);
    $board_sizer->Add( $cmd_sizer,        0, &Wx::wxEXPAND, 0);
    $board_sizer->Add( 0, 0, &Wx::wxEXPAND | &Wx::wxGROW);

    my $t_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    $t_sizer->Add( $frame->{'cmb'}{'time'},  0, &Wx::wxALIGN_LEFT| &Wx::wxGROW | &Wx::wxRIGHT, 0);
    $t_sizer->Add( $frame->{'cmb'}{'dt'}, 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW| &Wx::wxRIGHT, 5);
    $t_sizer->Add( Wx::StaticText->new($frame, -1, 'Px'), 0, &Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW|&Wx::wxALL, 12);
    $t_sizer->Add( $frame->{'cmb'}{'ps'}, 0, &Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL|&Wx::wxGROW, 0);
    $t_sizer->Add( 0, 0, &Wx::wxEXPAND);

    my $cf_sizer = Wx::BoxSizer->new(&Wx::wxHORIZONTAL);
    my $cf_attr = &Wx::wxLEFT|&Wx::wxALIGN_LEFT|&Wx::wxALIGN_CENTER_VERTICAL;
    my $cflbl = Wx::StaticText->new( $frame, -1, 'Color Flow');
    $cf_sizer->Add( 79, 0);
    $cf_sizer->Add( $cflbl,                      0, $cf_attr,   8);
    $cf_sizer->Add( $frame->{'cmb'}{'cftype'},   0, $cf_attr,  10);
    $cf_sizer->Add( $frame->{'cmb'}{'stepsize'}, 0, $cf_attr,  20);
    $cf_sizer->Add( 0, 0, &Wx::wxEXPAND);

    my $s_attr = &Wx::wxALIGN_LEFT|&Wx::wxEXPAND|&Wx::wxGROW|&Wx::wxTOP;
    my $setting_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
    $setting_sizer->Add( $frame->{'pendulum'}{'x'},  0, $s_attr, 20);
    $setting_sizer->Add( $frame->{'pendulum'}{'y'},  0, $s_attr, 10);
    $setting_sizer->Add( $frame->{'pendulum'}{'z'},  0, $s_attr, 10);
    $setting_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 135, 2] ),  0, $s_attr|&Wx::wxALIGN_CENTER_HORIZONTAL, 10);
    $setting_sizer->Add( $t_sizer,                   0, $s_attr, 10);
    $setting_sizer->Add( Wx::StaticLine->new( $frame, -1, [-1,-1], [ 135, 2] ),  0, $s_attr|&Wx::wxALIGN_CENTER_HORIZONTAL, 10);
    $setting_sizer->Add( $frame->{'color'}{'start'}, 0, $s_attr, 15);
    $setting_sizer->Add( $cf_sizer,                  0, $s_attr, 10);
    $setting_sizer->Add( $frame->{'color'}{'target'},0, $s_attr, 10);
    $setting_sizer->Add( 0, 1, &Wx::wxEXPAND | &Wx::wxGROW);

    my $main_sizer = Wx::BoxSizer->new( &Wx::wxHORIZONTAL );
    $main_sizer->Add( $board_sizer, 0, &Wx::wxEXPAND, 0);
    $main_sizer->Add( $setting_sizer, 0, &Wx::wxEXPAND|&Wx::wxLEFT, 10);
    $main_sizer->Add( 0, 0, &Wx::wxEXPAND);

    $frame->SetSizer($main_sizer);
    $frame->SetAutoLayout( 1 );
    $frame->{'btn'}{'draw'}->SetFocus;
    my $size = [1300, 900];
    $frame->SetSize($size);
    $frame->SetMinSize($size);
    $frame->SetMaxSize($size);
    $frame->Show(1);
    $frame->CenterOnScreen();
    $app->SetTopWindow($frame);
    $app->reset( $frame );
    1;
}

sub get_data {
    my $frame = shift;
    { 
        x => $frame->{'pendulum'}{'x'}->get_data,
        y => $frame->{'pendulum'}{'y'}->get_data,
        z => $frame->{'pendulum'}{'z'}->get_data,
        start_color => $frame->{'color'}{'start'}->get_data,
        target_color => $frame->{'color'}{'target'}->get_data,
        map { $_ => $frame->{'cmb'}{$_}->GetValue } qw/time dt ps cftype stepsize/, 
    }
}

sub set_data {
    my ($frame, $data) = @_;
    return unless ref $data eq 'HASH';
}

sub draw {
    my ($app, $frame) = @_;
    $frame->SetStatusText( "drawing .....", 0 );
    $frame->{'board'}->set_data( get_data( $frame ) );
    $frame->{'board'}->Refresh;
    $frame->SetStatusText( "done drawing", 0 );
}
sub reset {
    my ($app, $frame) = @_;
    $frame->{'pendulum'}{$_}->init() for qw/x y z/;
    $frame->{'color'}{$_}->init() for qw/start target/;
    $frame->{'cmb'}{'ps'}->SetValue(1);
    $frame->{'cmb'}{'dt'}->SetValue(100);
    $frame->{'cmb'}{'time'}->SetValue(10);
    $app->draw( $frame );
}


sub OnQuit { my( $self, $event ) = @_; $self->Close( 1 ); }
sub OnExit { my $app = shift;  1; }

1;

__END__

    #$frame->{'list'}{'sol'}->DeleteAllItems();
    #$frame->{'list'}{'sol'}->InsertStringItem( 0, "$_->[0],$_->[1] : $_->[2]") for reverse @{$frame->{'game'}{'solution_stack'}};
    #$frame->{'btn'}{'exit'}   = Wx::ToggleButton->new($frame,-1,'&Exit',[-1,-1],[$btnw, $btnh] );
    #$frame->{'list'}{'cand'}  = Wx::ListCtrl->new( $frame, -1, [-1,-1],[290,-1], &Wx::wxLC_ICON );
    # EVT_TOGGLEBUTTON( $frame, $frame->{'btn'}{'edit'}, sub { $frame->{'editable'} = $_[1]->IsChecked() } );
    # Wx::Event::EVT_LIST_ITEM_SELECTED( $frame, $frame->{'list'}{'cand'}, sub {$frame->{'txt'}{'comment'}->SetValue($frame->{'game'}{'candidate_stack'}[ $_[1]->GetIndex() ][3]) } );
    # Wx::InitAllImageHandlers();
