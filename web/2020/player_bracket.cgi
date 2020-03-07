#!/usr/bin/perl
# player_bracket.cgi

$| = 1;  # make sure output is unbuffered
use strict;
use CGI qw/:param/; # cgi.pm module
use DBI;   # perl DBI module
use vars qw/$dbh %PARAMS /;
use Template;
do "./jq_globals.pl";

my $config = config_variables();
$PARAMS{'imagedir'} = "/jqmcbp/images";
my $base_height = 35;

my @brackets = get_bracket_order();
connect_to_db();
my $last_updated = get_last_updated();
my $teams_ref = get_teams(@brackets);
my $player_id = param("player_id") || 'winners';

if ($player_id eq 'THE_PRESIDENT_OF_THE_UNITED_STATES') {
	$player_id = 6601;
}

$PARAMS{'player_id'} = $player_id;
$PARAMS{'pool_size'} = get_player_pool_size('man');
$PARAMS{'high_score'} = get_high_score();

my %picks;
my $name; 

my $candybar;
my $candybar_sql = "select * from player_info where player_id=\"$player_id\"";
my $player_info = single_row_query($candybar_sql);

my $man_or_chimp = $player_info->{'man_or_chimp'};
$candybar = $player_info->{'candybar'};
($player_info->{'score'}, $player_info->{'rank'}, $player_info->{'total'}, $player_info->{'leader'}) = get_score($player_info->{'name'});

my @games; my %winners; my @losers; my %losers;
my %point_values;
my $run_the_table;

for (1..63) {
	my $game = "game_" . $_;
	push @games, $game;
}

my @fields = (@games, "location", "candybar", "name", "email");

my $heading = "brackets_heading";
my $table_color1 = "brackets_clear";
my $table_color2 = "brackets2";
#my $table_color1_center = $table_color1 . "_center";
#my $table_color2_center = $table_color2 . "_center";
my $table_color1_center = $heading . "_center";
my $table_color2_center = $heading . "_center";



########################################################################
#################### pull in winner info ###############################
########################################################################
# this is with the new schema
# winners hash is populated from games table

my $winner_sql = "select game, winner, score from games";
my $winner_ref = multi_row_query($winner_sql);

for (@$winner_ref) {
	my $game_name = $_->{'game'};
	$winners{$game_name} = $_->{'winner'};
	$point_values{$game_name} = $_->{'score'};
}

########################################################################
#################### pull in player info ###############################
########################################################################
if ($player_id eq "winners") {

	for (1..63) {
		my $game = "game_" . $_;
          if ($winners{$game} =~ /foo/ || $winners{$game} eq 'NULL') {
            $picks{$game} = "&nbsp;";
          } else {
            $picks{$game} = $winners{$game};
          }
        }

} else {

my $player_sql = "select * from picks where player_id=\"$player_id\"";
my $player_ref = multi_row_query($player_sql);

for (@$player_ref) {
        $name = $_->{'name'};
        my $game = $_->{'game'};
	$picks{$game} = $_->{'winner'};
}

}

for (1..63) {

	my $game = "game_" . $_;
	# compare %picks to %winners


         # is there a winner and does it match the player's pick?
         if (($winners{$game} ne "foo" && $winners{$game} ne "" && $winners{$game} ne 'NULL') && $picks{$game} ne $winners{$game} ) {
#		log_to_file("$game|$winners{$game}|$picks{$game}");
		push @losers, $game;
		my $team = $picks{$game};
		$losers{$team} = 1;
         }
     
	$run_the_table += $point_values{$game};
         # if game is truly a winner, make font color firebrick
         if ($winners{$game} ne 'foo' && $picks{$game} eq $winners{$game} ) {
                   #$picks{$game} = "<font color=firebrick><b>" . $picks{$game} . "</b></font>";
                   $picks{$game} = "<span class = 'winner'>" . $picks{$game} . "</span>";
         }

            # does winner match something already found as a loser??
		for my $loser (keys %losers) {
			my $this_pick = $picks{$game};
			if ($losers{$this_pick}) {
				#log_to_file("$this_pick|$losers{$this_pick}|$loser");
				$picks{$game} = "<strike>" . $picks{$game} . "</strike>\n";
				$run_the_table = $run_the_table - $point_values{$game};
                   		last;
			}
               }
}

$player_info->{'rtt'} = $run_the_table;

print "Content-type: text/html\n\n";
my $template = "player_bracket";
my $tm = "&#0153;";
$PARAMS{'title'} = "Prognosticationland$tm";
$PARAMS{'cgi'} = 'player_bracket';

my %data = ( 
        'params'  		=>      \%PARAMS,
		'player_info'	=>	$player_info,
		'last_updated'	=>	$last_updated,
		'picks'			=>	\%picks,
		'base_height'	=>	$base_height,
		'teams_ref'		=>	$teams_ref,
		'brackets'		=>	\@brackets,
);

my $tmpl = "cgi_generic";
my $template = Template->new( {
            INCLUDE_PATH => "$config->{'template_dir'}",
																 } ) or print "couldn't do it $!";
$template->process($tmpl, \%data) || die "Template process failed: ", $template->error(), "\n";

exit;

sub get_score {
	my $name = shift;
	# score rank total leader
	# best just to get this from the /tmp/jq_scores.txt file
	my $file = "/tmp/jq_scores.txt";
	$file = "/tmp/jq_chimp_scores.txt" if $man_or_chimp eq "chimp";
	open(SCORES,"<$file") or return ('n/a','n/a','n/a','n/a');
	my $inc;
	my @data;
	my %ranks;
	my $leader = 0;
	
	while(<SCORES>) {
		chomp;
		$inc++;
		my @line = split /\t+/;
		if ($line[0] eq "1") {
			$leader = $line[1];
		}
		# count number at a given rank
		$ranks{$line[0]}++;
		unless ($leader) {
			$leader = $line[1];
		}
		if ($line[2] eq $name) {
			@data = @line;
		}
	}
	close(SCORES);
	# denote ties
	if ($ranks{$data[0]} > 1) {
		$data[0] = "T-" . $data[0];
	}
	return ( $data[1], $data[0], $inc, $leader);
}
