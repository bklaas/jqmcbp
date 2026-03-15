#!/usr/bin/perl 

$|=1;
use strict;
use DBI;   # perl DBI module

use vars qw /$dbh/;
do "./jq_globals.pl";

connect_to_db();

# first get all player_ids into an array
my $player_info = grab_names();
my $total = (scalar(@$player_info));

my %done;

my $i = 1;
$dbh->do('DELETE from similarity_index');
for my $player (@$player_info) {
	my $id = $player->{'player_id'};
	$done{$id}++;
	my $game_picks = get_picks($id);
	for my $other_player (@$player_info) {
		my $other_id = $other_player->{'player_id'};
		next if $done{$other_id};
		# get all game choices from other_player
		my $other_game_picks = get_picks($other_id);
		my $similarity = 0;
		for my $game (keys %$game_picks) {
			if ($game_picks->{$game}{'winner'} eq $other_game_picks->{$game}{'winner'}) {
				$similarity += $game_picks->{$game}{'score'};
			}
		}
		my $similarity_index = int(($similarity / 152)*100);
		my $insert = "INSERT into similarity_index (first_player_id, second_player_id, score, similarity) VALUES (\"$player->{'player_id'}\", \"$other_player->{'player_id'}\", $similarity, $similarity_index)";
		$dbh->do($insert);
		$insert = "INSERT into similarity_index (first_player_id, second_player_id, score, similarity) VALUES (\"$other_player->{'player_id'}\", \"$player->{'player_id'}\", $similarity, $similarity_index)";
		$dbh->do($insert);
#		print $insert . "\n";
	}
	print "$player->{'name'}\t$i:$total\n";
	$i++;
}

sub get_picks {
	my $id = shift;
	my $q = "SELECT picks.winner, games.game, games.score from picks, games where games.game = picks.game AND picks.player_id = \"$id\"";
	my $ref = multi_row_query($q);
	my %return;
	for my $href (@$ref) {
		$return{$href->{'game'}} = $href;
	}
	return \%return;
}
