#!/usr/bin/perl

use strict;
my $dbh;

use DBI;
do "/data/cgi-bin/jq_globals.pl";
my $dbh = connect_to_db();

my $player_id = 6756;
my $query_stub = "select winner from picks where game = ? and player_id = ?";
my $sth = $dbh->prepare($query_stub);
my $picks = {};

#my $step = get_step();
my $step = 48;
my $player_ids = get_player_ids();
for my $player (@$player_ids) {
	$picks->{ $player->{player_id} }->{current_score} = $player->{score};
	for my $game (49..63) {
		my $aref = mrq($sth, 'game_' . $game, $player->{player_id});
		for my $href (@$aref) {
			$picks->{ $player->{player_id} }->{"game_$game"} = $href->{winner};
		}
	}
}
	
use Data::Dump;
Data::Dump::dump($picks);

sub get_player_ids {
	#my $query = "select player_id from player_info where man_or_chimp = 'man' order by player_id";
	my $query = "select player_id, score from scores where step = $step and man_or_chimp = 'man' order by player_id";
	my $ref = multi_row_query($query);
	return $ref;
}

exit;
