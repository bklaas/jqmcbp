#!/usr/bin/perl 
#
# jq_entry.cgi
#
# this cgi is to serve up the html for the various rounds
# of selection in the johnnyquest pool
#
# complete rewrite of past jqmcbp bracket cgis

use strict;
$| = 1;  # make sure output is unbuffered

use CGI qw/:param :header :image_button/; # cgi.pm module

use DBI;   # perl DBI module
use Template;
use vars qw/$dbh/;
do "jq_globals.pl";
my $config = config_variables();
my %PARAMS;
for (param()) {
	$PARAMS{$_} = param($_);
	$PARAMS{$_} =~ s/"/'/g;
	if (/^[A-Z]/) {
		$PARAMS{$_} = 1;
	}
}
if ($PARAMS{"ENTER_PICKS.x"} > 0) {
	submit_picks();
        print header( -Refresh=>"0;URL=/jqmcbp/credits.html" );
	print "<html><body></body></html>\n";
	exit;
} else {
	print "Content-type: text/html\n\n";
}

$PARAMS{'year'} = '2008';

if (!$PARAMS{'email'} || !$PARAMS{'locale'} || !$PARAMS{'name'} || $PARAMS{'years_played'} eq '') {
	print "<html><body><b>Somehow you got here without entering an email address, location, years played, and/or name.<p>Make sure javascript is turned on in your browser, hit back, and submit again</b></body></html>\n";
	exit;
}
# html colors
connect_to_db();
# first get bracket order
my @brackets = get_bracket_order();
my $teams = get_teams(@brackets);
my $seeds = get_seeds($teams);
my $games = construct_games_array($teams);
$dbh->disconnect();

my %data = ( 'games'	=>	$games,
		'PARAMS'	=>	\%PARAMS,
		'teams'	=>	$teams,
		'seeds'	=>	$seeds,
		'brackets'	=>	\@brackets,
		);

my $file = "bracket.html.tmpl";
my $template = Template->new( {
                INCLUDE_PATH => "$config->{'template_dir'}",
} ) or print "couldn't do it $!";
		$template->process($file, \%data)
		|| die "Template process failed: ", $template->error(), "\n";

sub construct_games_array {
	my $teams = shift;
	my @ary;
	# go through teams 1 through 64, placing them in game_1 through game_32
	# next games range from 33 to 48
	# i counts from 1 to 64
	my @first_round = construct_round( 1, 32, 2);
	my @second_round = construct_round( 33, 48, 4);
	my @third_round = construct_round( 49, 56, 8);
	my @fourth_round = construct_round( 57, 60, 16);
	my @final_four = construct_round( 61, 62, 32);
	my @championship = construct_last_round();
	@ary = (@first_round, @second_round, @third_round, @fourth_round, @final_four, @championship);
	return \@ary;
}

sub construct_last_round {
	my @ary;
	my $game = 63;
	my $game_name = "game_63";
	my @team_list;
	for (@$teams) {
		push @team_list, $_->{'team'};
	}
	my $team_list = join('","', @team_list);
	$team_list = '"' . $team_list . '"';
	$ary[0]{'game'} = $game_name;
	$ary[0]{'teams'} = \@team_list;
	$ary[0]{'team_list'} = $team_list;
	my @prev_game_list;
	my $prevGame;
	for my $elem (0..63) {
		$prevGame = 'game_61' if $elem < 32;
		$prevGame = 'game_62' if $elem > 31;
		push @prev_game_list, $prevGame;
	}
	$ary[0]{'prevGame'} = \@prev_game_list;
	my $prev_game_list = join('","', @prev_game_list);
	$prev_game_list = '"' . $prev_game_list . '"';
	$ary[0]{'prevGame_list'} = $prev_game_list;
	return @ary;
}
sub construct_round {
	my $start = shift;
	my $end = shift;
	my $teamlist_size = shift;
	my @ary;
	my @team_list;
	my $game = $start;
	my $next_game = $end+1;
	my $element = 0;
	my $next = 0;
	for (my $game = $start; $game <= $end; $game = $game+1) {
		my $game_name = "game_" . $game;
		my $next_game_name = "game_" . $next_game;
		my @team_list;
		my $j = $next;
		for (my $k = $j; $k < $j+$teamlist_size; $k++) {
			push @team_list, $teams->[$k]{'team'};
			$next++;
		}
		my $team_list = join('","', @team_list);
		$team_list = '"' . $team_list . '"';
		$ary[$element]{'game'} = $game_name;
		$ary[$element]{'teams'} = \@team_list;
		$ary[$element]{'team_list'} = $team_list;
		$ary[$element]{'nextGame'} = $next_game_name;
		$element++;
		$next_game++ unless ($element % 2);
	}
	# populate the prevGame array ref
	my $break = $teamlist_size/2;
	my $prev_end = $start - 1;
	my $arysize = $teamlist_size;
	my $prev_start = $start - ((($end-$start)+1)*2);
	my $inc = $prev_start;
	$element = 0;
	#print "DEBUG: $prev_start\n";
	for (my $game = $start; $game <= $end; $game = $game+1) {
		my $arysize = $teamlist_size;
		my $break = $arysize/2;
		$arysize = $arysize - 1;
		my @prev_game_list;
		for my $element (0..$arysize) {
			my $mark = $element + 1;
			my $prev_game_name = "game_" . $inc;
			push @prev_game_list, $prev_game_name;
			$inc++ unless ($mark % $break);
		}
	#	print "$game|@prev_game_list\n";
		my $prev_game_list = join('","', @prev_game_list);
		$prev_game_list = '"' . $prev_game_list . '"';
		$ary[$element]{'prevGame_list'} = $prev_game_list;
		$ary[$element]{'prevGame'} = \@prev_game_list;
		$element++;
	}
	return @ary;
}

sub get_seeds {
	my $aref = shift;
	my %return;
	for my $href (@$aref) {
		my $team = $href->{'team'};
		my $seed = $href->{'seed'};
		$return{$team} = $seed;
	}
	return \%return;
}

sub submit_picks {
        my $stamp = time;
        my $file = $stamp . "." . $PARAMS{'email'} . ".dat";
        my $dir = "/tmp/jq_entries";
        mkdir $dir, 0777 unless -d $dir;
        open(DATA,">$dir/$file") or warn "couldn't open $file: $!";
                for (sort keys %PARAMS) {
                        next if /^[A-Z]/;
			my $key = $_;
			$key =~ s/^radio_//;
                        print DATA "$key|$PARAMS{$_}\n";
                }
        close(DATA);
}

