#!/usr/bin/perl 

$|=1;
use strict;
use DBI;   # perl DBI module

use vars qw /$dbh/;
do "jq_globals.pl";

connect_to_db();
my @brackets = get_bracket_order();
my $teams_ref = get_teams(@brackets);

my %point_values;
my %winners;
my $run_the_table;

# array ref ordered by bracket order of the final four teams
my $final_four_teams = get_final_four_teams();
my $step = get_step();
my @first_game = ($final_four_teams->[0]{'winner'}, $final_four_teams->[1]{'winner'});
my @second_game = ($final_four_teams->[2]{'winner'}, $final_four_teams->[3]{'winner'});

my $winners_sql = "select * from games";
my $ref = multi_row_query($winners_sql);

for (@$ref) {
	my $game_name = $_->{game};
	$winners{$game_name} = $_->{winner};
	$point_values{$game_name} = $_->{score};
}

my @sorted_score_data;
# calculate all scores with one sql statement
my $score_sql = "select * from scores, player_info where scores.player_id = player_info.player_id and scores.eliminated = 'n' and scores.step = \"$step\" order by scores.score desc";
my $score_ref = multi_row_query($score_sql);
print "got the scores\n";
for my $hashref (@$score_ref) {
	push @sorted_score_data, $hashref;
}

# go through each scenario and calculate final score of each remaining players picks
my $game_1 = 'game_61';
my $game_2 = 'game_62';
my $game_3 = 'game_63';

my %score_hash;
for my $winner1 (@first_game) {
	for my $winner2 (@second_game) {
		for my $winner3 ($winner1, $winner2) {
			for my $player (@sorted_score_data) {
				my $id = $player->{'player_id'};
				my $scenario = "ff1: $winner1 | ff2: $winner2 | champ: $winner3"; 
				my $query = "select winner from picks where player_id = $player->{'player_id'} and game = \"$game_1\"";
				my $ref = single_row_query($query);
				my $score = $player->{'score'};
				if ($ref->{'winner'} eq $winner1) {
					$score += 8;
				}
				$query = "select winner from picks where player_id = $player->{'player_id'} and game = \"$game_2\"";
				$ref = single_row_query($query);
				if ($ref->{'winner'} eq $winner2) {
					$score += 8;
				}
				$query = "select winner from picks where player_id = $player->{'player_id'} and game = \"$game_3\"";
				$ref = single_row_query($query);
				if ($ref->{'winner'} eq $winner3) {
					$score += 16;
				}
				$score_hash{$scenario}{$id}{'score'} = $score;
				$score_hash{$scenario}{$id}{'name'} = $player->{'name'};
			}
		}
	}
}

for my $scenario (sort keys %score_hash) {
	print "$scenario\n";
	my $href = $score_hash{$scenario};
	my $high_score = 0;
	my $name = '';
	for my $id (sort keys %$href) {
		if ($score_hash{$scenario}{$id}{'score'} >= $high_score) {
		$high_score = $score_hash{$scenario}{$id}{'score'};
		print "$score_hash{$scenario}{$id}{'name'}\t";
		print "$score_hash{$scenario}{$id}{'score'}\n";
		}
	}
	
	print "\n\n";
}

sub get_final_four_teams {
	my @return;
	for my $bracket (@brackets) {
		my $query = "select * from games where (game = 'game_57' or game = 'game_58' or game = 'game_59' or game = 'game_60') and region = '$bracket'";
		my $href = single_row_query($query);
		push @return, $href;
	}
	return \@return;
}
