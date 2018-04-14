#!/usr/bin/perl 

$|=1;
use strict;
use DBI;   # perl DBI module

use vars qw /$dbh/;
do "jq_globals.pl";

my $update_scores = 1;
if ($ARGV[0]) {
	$update_scores = 0;
}
connect_to_db();
my @brackets = get_bracket_order();
my $teams_ref = get_teams(@brackets);

my $data_dir = "/tmp";

my %point_values;
my %winners;
my $run_the_table;

my $step = 1;
my $sql = 'select step from scores order by step desc limit 1';
my $href = single_row_query($sql);
if ($href->{'step'}) {
	$step = $href->{'step'} + 1;
}

my $winners_sql = "select * from games";
my $ref = multi_row_query($winners_sql);

for (@$ref) {
	my $game_name = $_->{game};
	$winners{$game_name} = $_->{winner};
	$point_values{$game_name} = $_->{score};
}

for my $manorchimp ('chimp', 'man', 'both') {
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
	print "got the scores for $manorchimp\n";

	my %names;
	my %ids;
	for my $hashref (@$score_ref) {
		my $id = $hashref->{'player_id'};
		$ids{$id}++;
		if ($hashref->{'location'} eq "") {
			$hashref->{'location'} = "---";
		}
		# run the table
		my $table_run = calculate_table_run($hashref->{player_id});
		$hashref->{'rtt'} = $table_run;
		my $darwin;
		if ($manorchimp eq 'man' ) {
			$darwin = calculate_darwin($hashref->{score});
		} else {
			$darwin = '';
		}
		$hashref->{'darwin'} = $darwin;
		push @sorted_score_data, $hashref;
	}
	print "scores collected and sorted\n";

	# whole section can be skipped if there is no one at zero
	my $last_step = $step - 1;
	my $zero = "select count(*) as count from scores where score = 0 and step = \"$last_step\"";
	my $calculate_zeroes = 0;
	if ($last_step > 0) {
		my $ref = single_row_query($zero);
		if ($ref->{'count'}) {
			$calculate_zeroes++;
		}
	}
	if ($calculate_zeroes) {
		print "recording metadata for people who haven't scored anything\n";
		# this is to record people that haven't scored any points
		my $zeroes = "select * from player_info where $manorchimpstub order by player_info.name";
		my $zilch_ref = multi_row_query($zeroes);
		for my $ref (@$zilch_ref) {
			my $id = $ref->{'player_id'};
			next if $ids{$id};
			$ref->{'score'} = 0;
			if ($ref->{'location'} eq "") {
				$ref->{'location'} = "--";
			}
			# run the table
			my $table_run = calculate_table_run($ref->{player_id});
			$ref->{'rtt'} = $table_run;
			push @sorted_score_data, $ref;
		}
	}
	
	my $scorefile;
        if ($manorchimp eq 'man') {
        	$scorefile = "jq_scores.txt";
        } elsif ($manorchimp eq 'chimp') {
			$scorefile = "chimp_scores.txt";
        } else {
			$scorefile = "combined_scores.txt";
        }
	print "Writing to $scorefile and updating scores record ($manorchimp)\n";
	open (SCORES, ">$data_dir/$scorefile") or die "can't open jq_scores.txt: $!";


	my $previous = 1;
	my $place;
	my @fields = ('rank', 'score', 'name', 'candybar', 'man_or_chimp', 'location', 'champ', 'j2_factor', 'player_id', 'rtt', 'darwin');
	for my $j (0..$#sorted_score_data) {
		my $k = $j - 1;
		my $inc = $j+1;
		if ($sorted_score_data[$j]->{'score'} == $sorted_score_data[$k]->{'score'}) {
			$place = $previous;
		} else {
			$place = $j + 1;
			$previous = $place;
		}
		$sorted_score_data[$j]->{'rank'} = $place;
		my $i = 0;
		for my $field (@fields) {
			print SCORES "$sorted_score_data[$j]->{$field}";
			if ($field eq "darwin") {
				print SCORES "\n";
			} else {
				print SCORES "\t";
			}
			$i++;
   		}
		if ($manorchimp eq 'both') {
			my $update = "UPDATE scores set combined_rank = \"$sorted_score_data[$j]->{'rank'}\" where player_id = \"$sorted_score_data[$j]->{'player_id'}\" and step = \"$step\"";
			if ($update_scores) {
				$dbh->do($update) or die "couldn't update\n$update\n";
			}
		} else {
			my $scoresql = "INSERT into scores (player_id, step, score, rank, name, rtt, man_or_chimp, darwin, rawnumber) VALUES
			(\"$sorted_score_data[$j]->{'player_id'}\",
			\"$step\",
			\"$sorted_score_data[$j]->{'score'}\",
			\"$sorted_score_data[$j]->{'rank'}\",
			\"$sorted_score_data[$j]->{'name'}\",
			\"$sorted_score_data[$j]->{'rtt'}\",
			\"$manorchimp\",
			\"$sorted_score_data[$j]->{'darwin'}\",
			\"$inc\")";
			if ($update_scores) {
				$dbh->do($scoresql) or die "couldn't enter $sorted_score_data[$j][1]: $DBI::ERRSTR";
			}
			$inc++;
    		}
	}
	close (SCORES);
	chmod 0777, "$data_dir/$scorefile" or warn "couldn't chmod $scorefile: $!";

		open(FOREMAIL,">$data_dir/top10_${manorchimp}.txt") or warn "can't open top10.txt: $!";
		$place = 1;
		for my $data (@sorted_score_data) {
			last if $data->{'rank'} > 10;
			for my $field ('rank', 'name', 'location', 'candybar', 'champion', 'score') {
				print FOREMAIL "$data->{$field}\t";
    			}
			print FOREMAIL "\n";
		}
		close(FOREMAIL);
		chmod 0777, "$data_dir/top10_${manorchimp}.txt" or warn "couldn't chmod top10.txt: $!";
		open(WRITE,">$data_dir/top10_${manorchimp}_abbr.txt") or warn "can't write top10_abbr.txt: $!";
		for my $data (@sorted_score_data) {
			last if $data->{'rank'} > 10;
			foreach my $field ('rank', 'name', 'candybar', 'score') {
				print WRITE "$data->{$field}\t";
			}
			print WRITE "\n";
		}
		close(WRITE);
		chmod 0777, "$data_dir/top10_${manorchimp}_abbr.txt" or warn "can't do that: $!";

}
print "SCORING PROGRAM COMPLETE\n";


##########################################

sub calculate_table_run {
	use Data::Dumper;
	my $player_id = shift;
	my %picks;
	my %losers;
	my $run_the_table;
	my $player_sql = "select * from picks where player_id=\"$player_id\"";
	my $player_ref = multi_row_query($player_sql);
	for (@$player_ref) {
		my $game = $_->{'game'};
		$picks{$game} = $_->{'winner'};
	}

	for (1..63) {

		my $game = "game_" . $_;

		# compare %picks to %winners

	  	# is there a winner and does it match the player's pick?
		if ($winners{$game} ne "foo" && $picks{$game} ne $winners{$game} ) {
			my $team = $picks{$game};
			$losers{$team} = 1;
		}
     
		$run_the_table += $point_values{$game};
		# does winner match something already found as a loser??
		for my $loser (keys %losers) {
			my $this_pick = $picks{$game};
			if ($losers{$this_pick}) {
				$run_the_table = $run_the_table - $point_values{$game};
        		last;
			}
               }
	}
	return $run_the_table;
}

sub calculate_darwin {
	my $score = shift;
	my $query = "select count(*) as count from scores, player_info where player_info.player_id = scores.player_id and player_info.man_or_chimp = 'chimp' and scores.score >= $score and scores.step = \"$step\"";
	my $return = single_row_query($query);
	if ($return->{'count'} == 0 && $score == 0) {
		$return->{'count'} = 1000;
	}
	return $return->{'count'};
}
