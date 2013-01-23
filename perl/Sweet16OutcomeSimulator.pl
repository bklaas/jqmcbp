#!/usr/bin/perl

use strict;
use DBI;

use vars qw/ $dbh /;
do "/data/cgi-bin/jq_globals.pl";
connect_to_db();

# Collect everyone's current score after 2nd round (DONE)
# Simulate all 2^15 (32768) possible outcomes and encode them as hex (DONE)
# Code the Sweet 16 teams as hex codes 0-F (DONE)
# XXX: For each player, query DB for picks in game_49 - game_63
#		encode those picks as hex codes, with an X for teams that are not part of 0-F code set (i.e., teams that aren't around any more)
# XXX: For each possible outcome of games, calculate every player's score and rank in that outcome, and stash that outcome in a summary data structure

# final data of interest are:
#		for a given player: 
#				highest possible score
#				highest possible rank
#				lowest possible score
#				lowest possible rank
#				median rank
#				number of 32768 outcomes at top

# the points for each remaining game
my $points = [ 4, 4, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 8, 8, 16 ];

# number of remaining games
my $N = 15;
# $all possible combinations is 2^(N) -1
my $all = 2 ** $N - 1;
# if done as planned, step is 48
my $step = 48;

# Get all players and their current score
my $currentScoreRef = getCurrentPlayerScores('man');
# get all chimp player_ids and their score at step = ? (end of round 16)

for my $player (keys %$currentScoreRef) {
}

# select all human players and read in their picks for games 49 to 63
#my $player_picks = "SELECT * from players ";
#my $ref = multi_row_query();

# XXX: re-enable this step to get all the possible outcomes
my $outcomes = encodeAllWinners();
#print $outcomes->[0] . "\n";
#print $outcomes->[16000] . "\n";
#print $outcomes->[$#{$outcomes}] . "\n";

# Code the Sweet 16 teams as hex codes 0-F
# hash key is the team, value is the hex code
my $teamHexCodes = makeTeamHexCodes();

# For each player, query DB for picks in game_49 - game_63
#	encode those picks as hex codes, with an X for teams that are not part of 0-F code set (i.e., teams that aren't around any more)
my $playerPicks = encodePlayerPicks();

# Now we have $outcomes to iterate across for each possible outcome
# And we have $playerPicks for the picks of each player, and their current score
# So:
# XXX: iterate across each outcome, calculate scores efficiently, rank them, and store each player's outcome in the $playerPicks hash
# each outcome
my $j = 1;
for my $outcome (@$outcomes) {
	# each player
	for my $player (keys %$playerPicks) {
		# push player picks through $outcome to get shared hits
		# for debug
		print @{$outcome};
		print "\n";
		print @{$playerPicks->{$player}{picks}};
		print "\n";
		$playerPicks->{$player}{score} = $playerPicks->{$player}{current_score};
		my $i = 0;
		for my $point (@$points) {
			$playerPicks->{$player}{score} += $point if $playerPicks->{$player}{picks}[$i] eq $outcome->[$i];
			$i++;
		}
		print "$playerPicks->{$player}{current_score}\t$playerPicks->{$player}{score}\n";
		print "--------------\n";
		#exit if $j == 40;
		$j++;
	}
}

$dbh->disconnect();

sub encodePlayerPicks {
	my $return;
	my $man_or_chimp = shift || "man";
	my $players_sql = "select * from player_info where man_or_chimp = '$man_or_chimp' order by player_id";
	my $players = multi_row_query($players_sql);

	for my $href (@$players) {
		my $player = $href->{player_id};
		my $encodedString = "";
		my @encodedPick; 
		#for my $i (33..48) {
		for my $i (49..63) {
			my $game = "game_" . $i;
			my $pick = single_row_query("SELECT winner from picks where player_id = \"$player\" and game = \"$game\"");
			my $encodedPick = defined($teamHexCodes->{$pick->{winner}}) ? $teamHexCodes->{$pick->{winner}} : ".";
			push @encodedPick, $encodedPick;
		}
		$return->{$player}{picks} = \@encodedPick;
		$return->{$player}{info} = $href; # cache the rest of the player_info data for convenience

		# the current "step" should be 48, as that's how many games have already been played as of sweet 16
		my $score = single_row_query("SELECT score from scores where player_id = \"$player\" and step = 48");
		$return->{$player}{current_score} = $score->{score};

		# for debug
		#print "$player\t@encodedPick\t$score->{score}\t$href->{champion}\n";
	}
	
	# return the whole kit-n-kaboodle
	return $return;
}

sub makeTeamHexCodes {
	# retrieve winners from games 33-48
	my $j = 0;
	my $return = {};

	for my $i (33..48) {
		my $game = "game_" . $i;
		my $winners = "SELECT winner from games where game = \"$game\"";
		my $ref = single_row_query($winners);
		my $hex_j = sprintf "%x", $j;
		$j++;
		$return->{$ref->{winner}} = $hex_j;

	}

	# for debug
	#for my $hashKey ( sort keys %$return ) {
	#	print "$hashKey\t$return->{$hashKey}\n";
	#}

	return $return;
}

sub getCurrentPlayerScores {
	my $man_or_chimp = shift;

	# get all ids and their scores
	my $players_sql = "select player_info.player_id, scores.score from player_info, scores where player_info.player_id = scores.player_id and player_info.man_or_chimp = '$man_or_chimp' and step = '$step'";

	my $ref = multi_row_query($players_sql);

	my $return;
	for my $href (@$ref) {
		$return->{$href->{player_id}} = { current => $href->{score} };
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
	for my $i (0..7) {
		my $game = $i*2;
		my $winner = $game + $flips->[$i];
		my $hex_i = sprintf "%x", $winner;
		$flips->[$i] = $hex_i; # code the coin flip winner in hex
		push @$codes, $hex_i; # put the winner from this game as the possible winner of the next round
	}

	# using the @codes from the previous round, 
	# encode the winners of the next round
	($flips, $codes) = next_round($flips, $codes, 8, 11);
	($flips, $codes) = next_round($flips, $codes, 12, 13);
	($flips, $codes) = next_round($flips, $codes, 14, 14);

	# return 16 character set of hex codes as one string
	return \@flips;
	# XXX: return the array instead?
	#my $return = join('', @flips);
	#return $return;
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

