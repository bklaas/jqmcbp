#!/usr/bin/perl 

$|=1;
use strict;
use DBI;   # perl DBI module

use vars qw /$dbh/;
do "jq_globals.pl";

connect_to_db();
my @brackets = get_bracket_order();
my $teams_ref = get_teams(@brackets);

my $data_dir = "/tmp";

my %point_values;
my %winners;
my $run_the_table;

my $step = get_step();

my $winners_sql = "select * from games";
my $ref = multi_row_query($winners_sql);

for (@$ref) {
	my $game_name = $_->{game};
	$winners{$game_name} = $_->{winner};
	$point_values{$game_name} = $_->{score};
}

for my $manorchimp ('both') {
	print "UPDATING $manorchimp\n";
	my @sorted_score_data;
	my $manorchimpstub;
	if ($manorchimp eq 'both') {
		$manorchimpstub = "player_info.man_or_chimp != \"foo\"";
	} else {
		$manorchimpstub = "player_info.man_or_chimp = \"$manorchimp\"";
	}
	# calculate all scores with one sql statement
	my $score_sql = "select sum(games.score) as score, 
              picks.name, player_info.candybar, player_info.man_or_chimp,  
              player_info.location, 
              player_info.champion, player_info.j2_factor,
		player_info.player_id
              from games, picks, player_info
              where
		$manorchimpstub and
              picks.game = games.game and
              picks.winner = games.winner and
              picks.player_id = player_info.player_id
              group by player_info.player_id order by score desc, player_info.name";

#	print "$score_sql\n";
	my $score_ref = multi_row_query($score_sql);
	@sorted_score_data = @$score_ref;
	print "got the scores for $manorchimp\n";

	my %names;
	my %ids;

        my $previous = 1;
        my $place;
        for my $j (0..$#sorted_score_data) {
                my $k = $j - 1;
                my $inc = $j+1;
                if ($sorted_score_data[$j]->{'score'} == $sorted_score_data[$k]->{'score'}) {
                        $place = $previous;
                } else {
                        $place = $j + 1;
                        $previous = $place;
                }
		my $update = "UPDATE scores set combined_rank = \"$place\" where player_id = \"$sorted_score_data[$j]->{'player_id'}\" and step = \"$step\"";
		$dbh->do($update) or die "couldn't update\n$update\n";
		print "$update\n";
	}

}
print "SCORING PROGRAM COMPLETE\n";

