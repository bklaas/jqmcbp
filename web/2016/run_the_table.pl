#!/usr/bin/perl
#
# run_the_table.pl
#
#
# bklaas 03.24.04

use strict;
use DBI;   # perl DBI module
use vars qw/$dbh/;
do "jq_globals.pl";

my @brackets = get_bracket_order();
connect_to_db();
my $teams_ref = get_teams(@brackets);
my $player_id = 301;
my %picks;
my $name; 

my $candybar_sql = "select * from player_info where player_id=\"$player_id\"";
my $candy_ref = single_row_query($candybar_sql);
my ($score, $rank, $total, $leader) = get_score($player_id);

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
          if ($winners{$game} eq "foo") {
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
########################################################################
#########################make strike throughs###########################
########################################################################
for (1..63) {

	my $game = "game_" . $_;
	# compare %picks to %winners


         # is there a winner and does it match the player's pick?
         if ($winners{$game} ne "foo" && $picks{$game} ne $winners{$game} ) {
		push @losers, $game;
		my $team = $picks{$game};
		$losers{$team} = 1;
         }
     
	$run_the_table += $point_values{$game};
         # if game is truly a winner, make font color firebrick
         if ($winners{$game} ne 'foo' && $picks{$game} eq $winners{$game} ) {
                   $picks{$game} = "<font color=firebrick>" . $picks{$game} . "</font>";
         }

            # does winner match something already found as a loser??
		for my $loser (keys %losers) {
			my $this_pick = $picks{$game};
			if ($losers{$this_pick}) {
				$picks{$game} = "<strike>" . $picks{$game} . "</strike>\n";
				$run_the_table = $run_the_table - $point_values{$game};
                   		last;
			}
               }
}

print "$player_id\t$run_the_table\n";
exit;

sub get_score {

	my $player_id = shift;
	# score rank total leader
	# best just to get this from the /tmp/jq_scores.txt file
	open(SCORES,"</tmp/jq_scores.txt") or return ('n/a','n/a','n/a','n/a');
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
		if ($line[8] eq $player_id) {
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

