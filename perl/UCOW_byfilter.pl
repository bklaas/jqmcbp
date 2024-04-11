#!/usr/bin/perl
# UCOW = Unweighted Chance Of Winning

use strict;
use DBI;
use Data::Dump qw/dump/;

use vars qw/ $dbh /;
do "./jq_globals.pl";
#connect_to_db('johnnyquest', '192.168.1.199');
connect_to_db('johnnyquest');

my $filter_id = shift @ARGV;

#################################
## SET THE REMAINING TEAMS VARIABLE HERE
## EVERYTHING ELSE SHOULD TAKE CARE OF ITSELF
#################################
#my $remainingTeams = 16;
#my $remainingTeams = 8;
my $remainingTeams = 4;

my $N;

# the points for each remaining game
my $points;
my $startGame;
my $endGame;

if ($remainingTeams == 16) {
	$N = 15;
	$points = [ 4, 4, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 8, 8, 16 ];
	$startGame = 33;
	$endGame = 48;
}
elsif ($remainingTeams == 8) {
	$N = 7;
	$points = [ 6, 6, 6, 6, 8, 8, 16 ];
	$startGame = 49;
	$endGame = 56;
}
elsif ($remainingTeams == 4) {
	$N = 3;
	$points = [ 8, 8, 16 ];
	$startGame = 57;
	$endGame = 60;
}

# $all possible combinations is 2^(N) -1 (-1 because we start counting from zero)
my $all = 2 ** $N - 1;

# for testing, just do 10 combos
#$all = 500;

# if done as planned, step is 48
# get the current step, with the assumption we are between 1st and 2nd weekends
my $step = get_step();


# Get all players and their current score
my $currentScoreRef = getCurrentPlayerScores();
# get all chimp player_ids and their score at step = ? (end of round 16)

my $outcomes = encodeAllWinners();

# Code the Sweet 16 teams as hex codes 0-F
# hash key is the team, value is the hex code
my $teamHexCodes = makeTeamHexCodes();

# For each player, query DB for picks in game_49 - game_63
#	encode those picks as hex codes, with an X for teams that are not part of 0-F code set (i.e., teams that aren't around any more)
my $playerPicks = encodePlayerPicks();

$dbh->disconnect();

# Now we have $outcomes to iterate across for each possible outcome
# And we have $playerPicks for the picks of each player, and their current score
# So:
# XXX: iterate across each outcome, calculate scores efficiently, rank them, and store each player's outcome in the $playerPicks hash
# each outcome
my $j = 1;
my $byPlayer = {};
my $byOutcome = {};

my $numberOfWinnersTally;
my $menOrChimps;

# WORKS, probably not as efficient as it could be
for my $outcome (@$outcomes) {
	# each player
	my $stringOutcome = join("", @$outcome);
	my $scenario = {};
	for my $player (keys %$playerPicks) {
		my $thisScore = $playerPicks->{$player}{current_score};
		my $i = 0;
		for my $point (@$points) {
			$thisScore = $thisScore + $point if $playerPicks->{$player}{picks}[$i] eq $outcome->[$i];
			$i++;
		}

		$scenario->{$player}{'score'} = $thisScore;

	}
	# $ranks is a LoH
	# size of $ranks is number of winners from that outcome
	# go through each and 
	my $ranks = rank_em($scenario, $stringOutcome );

	my $i = 0;
	my $manWins = 0;
	my $chimpWins = 0;

	for my $winner (@$ranks) {
        my $n = $winner->{name};
		if ( $winner->{man_or_chimp} eq 'chimp' ) {
            $n = $n . " the Chimp";
        }
		$byPlayer->{ $winner->{player_id} }++;
		if ( $remainingTeams == 4 ) {
			print "$n\t$winner->{stringOutcome}\n";
		}
		if ( $winner->{man_or_chimp} eq 'chimp' && !$chimpWins ) {
			$menOrChimps->{chimp}++;
			$chimpWins++;
		}
		elsif ( $winner->{man_or_chimp} eq 'man' && !$manWins ) {
			$menOrChimps->{man}++;
			$manWins++;
		}
		$i++;
	}
	# keep a running taly of how many times we have $i winners
	$numberOfWinnersTally->{$i}++;

	
	$j++;
}

print "===== WINNERS ====\n";
print "Name\tNumber of Winning Brackets\tPercentage of Winning Brackets\n";
for my $winner ( sort { $byPlayer->{$b} <=> $byPlayer->{$a} } keys %$byPlayer ) {
	# winner is the player_id
	my $percentage = sprintf("%.3f", ($byPlayer->{$winner}/($all+1) * 100));
    my $n = $currentScoreRef->{$winner}{'name'};
    if ($currentScoreRef->{$winner}{'man_or_chimp'} eq "chimp") {
        $n = $n . " the Chimp";
    }
	print "$n\t$byPlayer->{$winner}\t$percentage\n";
}

print "==== HUMAN WINS, CHIMP WINS ====\n";
print "Human Wins: $menOrChimps->{man}\n";
print "Chimp Wins: $menOrChimps->{chimp}\n";

print "==== NUMBER OF WINNERS/OUTCOME TALLY ====\n";
for my $num ( sort { $a <=> $b } keys %$numberOfWinnersTally ) {
	print "$num\t$numberOfWinnersTally->{$num}\n";
}
exit;

my $highScore =   0; # arbitrary can't be the high score
my $lowScore  = 200; # arbitrary can't be the low score

for my $outcome (keys %$byOutcome) {
	my ($ranks, $thisHighest, $thisLowest) = rank_em($byOutcome->{$outcome});
	$highScore = $thisHighest if $thisHighest > $highScore;
	$lowScore  = $thisLowest if $thisLowest < $lowScore;
	# XXX: for each $outcome, map in the $ranks hash so every key in 
	#      $byOutcome has a $byOutcome->{$stringOutcome}{$player}{'rank'} value
	# 
	# XXX: also for each player in $byPlayer, populate
	# 
}
print "|$highScore|$lowScore|\n";

# keep tally of each playerID's # of wins

# keep tally of how many winners for each sim


# For all given players:
#	What is the highest rank ever achieved
#	What is the lowest rank acheived in all possible outcomes
#	How many times do you win across all outcomes
#	How many times does a chimp win
#	How many times is there more than one victor
#	What's the largest number of players that win a single outcome
#
# For all given outcomes:
#	How many players are still in the race?
#	What is the highest possible winning score
#	What is the lowest possible winning score
#	

exit;

sub rank_em {
	my $outcome = shift;
	my $stringOutcome = shift;
	# put all of the scores into a sorted list
	my @scores;
	for my $player (keys %$outcome) {
	    #push @scores, [ $outcome->{$player}{'score'}, $player ];
	    push @scores, { score => $outcome->{$player}{'score'}, player_id => $player, man_or_chimp => $currentScoreRef->{$player}{'man_or_chimp'}, name => $currentScoreRef->{$player}{'name'}, stringOutcome => $stringOutcome };
	}

	my $place = 1;
	my $ranks; # hash of score as key and rank as value, for a given outcome
	my $j = 1;
	my $previousScore = 0;

	for my $href ( sort { $b->{score} <=> $a->{score} } @scores ) {
		if ($href->{score} < $previousScore) {
			#XXX let's bail after getting the winner right now
			last;
			$place = $j + 1;
		}
		#push @{$ranks->{$place}}, $href;
		# we're just getting winners, so no need to send anything but a list of winners (hashrefs) back
		push @$ranks, $href;
		$j++;
		$previousScore = $href->{score};
	}
	
	return $ranks;
}

sub encodePlayerPicks {
	my $return;
	my $players_sql;

    #$players_sql = "select * from player_info order by player_id";
	$players_sql = "select * from player_info
JOIN scores s ON s.player_id = player_info.player_id
JOIN filter_link fl ON player_info.player_id = fl.player_id
JOIN filter f ON fl.filter_id = f.filter_id
where f.filter_id = $filter_id order by player_info.player_id";
	my $players = multi_row_query($players_sql);

	for my $href (@$players) {
		my $player = $href->{player_id};
		my $encodedString = "";
		my @encodedPick; 
		my $startPick = $endGame + 1;
		for my $i ($startPick..63) {
			my $game = "game_" . $i;
			my $pick = single_row_query("SELECT winner from picks where player_id = \"$player\" and game = \"$game\"");
			my $encodedPick = defined($teamHexCodes->{$pick->{winner}}) ? $teamHexCodes->{$pick->{winner}} : ".";
			push @encodedPick, $encodedPick;
		}
		$return->{$player}{picks} = \@encodedPick;
		$return->{$player}{info} = $href; # cache the rest of the player_info data for convenience

		my $score = single_row_query("SELECT score from scores where player_id = \"$player\" and step = '$step'");
		$return->{$player}{current_score} = $score->{score};

		# for debug
		#print "$player\t@encodedPick\t$score->{score}\t$href->{champion}\n";
	}
	
	# return the whole kit-n-kaboodle
	return $return;
}

sub makeTeamHexCodes {
	# retrieve winners from games $startGame to $endGame (e.g., 33-48 for sweet 16, 49-56 for elite eight, 57-60 for final four)
	my $j = 0;
	my $return = {};

	for my $i ($startGame..$endGame) {
		my $game = "game_" . $i;
		my $winners = "SELECT winner from games where game = \"$game\"";
		my $ref = single_row_query($winners);
		my $hex_j = sprintf "%x", $j;
		$j++;
		$return->{$ref->{winner}} = $hex_j;
		if ($remainingTeams == 4) {
			print "$ref->{winner}\t$hex_j\n";
		}
	}

	return $return;
}

sub getCurrentPlayerScores {

	my $players_sql;
	# get all ids and their scores
    $players_sql = "select player_info.*, scores.score from player_info, scores, filter_link, filter where filter_link.filter_id = filter.filter_id and player_info.player_id = filter_link.player_id and filter.filter_id = $filter_id and scores.player_id = player_info.player_id and scores.step = '$step'";
print $players_sql . "\n";
	my $ref = multi_row_query($players_sql);

	my $return;
	for my $href (@$ref) {
		$return->{$href->{player_id}} = { current => $href->{score}, man_or_chimp => $href->{man_or_chimp}, name => $href->{name} };
	}
	return $return;

}

sub encodeAllWinners {
	# encode all winners in string of hex codes 
	my @return;
	for my $i ( 0 .. $all) {
		my $encoded_outcome = encode_outcome($i);
		push @return, $encoded_outcome;
	}
	return \@return;
}

sub encode_outcome {
	my $i = shift;
	my $format = "%0$N" . "b"; #uuuugly
	my $binary_outcome = sprintf $format, $i;

	my @flips = split //, $binary_outcome;
	my $flips = \@flips;
	#my @codes = qw/ x x x x x x x x /;
	my $codes = [];
	my $end = $remainingTeams/2 - 1;
	for my $i (0..$end) {
		my $game = $i*2;
		my $winner = $game + $flips->[$i];
		my $hex_i = sprintf "%x", $winner;
		$flips->[$i] = $hex_i; # code the coin flip winner in hex
		push @$codes, $hex_i; # put the winner from this game as the possible winner of the next round
	}

	# using the @codes from the previous round, 
	# encode the winners of the next round
	if ($remainingTeams == 16) {
		($flips, $codes) = next_round($flips, $codes, 8, 11);
		$end = 11;
	}
	if ($remainingTeams > 4) {
		($flips, $codes) = next_round($flips, $codes, $end + 1 , $end + 2);
		$end = $end + 2;
	}
	($flips, $codes) = next_round($flips, $codes, $end + 1, $end + 1);

	# return 16 character set of hex codes as one string
	return \@flips;
}

sub next_round {
	my ($flips, $codes, $start, $end) = @_;
	my $a = 0;
	my $b = 1;
	my $newcodes = [];
	for my $i ($start..$end) {
		if ($flips->[$i] == 0) {
			$flips->[$i] = $codes->[$a];
			push @$newcodes, $codes->[$a];
		}
		else {
			$flips->[$i] = $codes->[$b];
			push @$newcodes, $codes->[$b];
		}
		$a += 2;
		$b += 2;
	}
	return $flips, $newcodes;
}

