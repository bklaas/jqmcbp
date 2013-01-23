#!/usr/bin/perl

use DBI;

do "jq_globals.pl";
use vars qw/ $dbh /;
connect_to_db();

# get player_ids
#my $q = "SELECT * from player_info where man_or_chimp = 'man' order by player_id";
my $q = "SELECT * from player_info order by player_id";
my $ref = multi_row_query($q);

for my $href (@$ref) {
	print "$href->{'player_id'}\n";
	my %games = (
			'game_57'	=>	'ff1',
			'game_58'	=>	'ff2',
			'game_59'	=>	'ff3',
			'game_60'	=>	'ff4',
			);
	my %picks;
	for my $game (keys %games) {
		my $q = "select winner from picks where player_id = \"$href->{'player_id'}\" and game = \"$game\"";
		my $r = single_row_query($q);
		my $which = $games{$game};
		my $update = "UPDATE player_info set $which = \"$r->{'winner'}\" where player_id = \"$href->{'player_id'}\"\n";
		$picks{$which} = $r->{'winner'};
		$dbh->do($update);
	}

	$q = "SELECT count(*) as count from player_info where player_id != \"$href->{'player_id'}\" AND
			ff1 = \"$picks{'ff1'}\" AND 
			ff2 = \"$picks{'ff2'}\" AND 
			ff3 = \"$picks{'ff3'}\" AND 
			ff4 = \"$picks{'ff4'}\" ";
	for my $type ('man', 'chimp') {
		my $query = $q;
		$query .= "AND man_or_chimp = \"$type\"";
		my $tally = single_row_query($query);
		print $href->{'name'} . " has $tally->{'count'} ($type) that have picked the same final four\n";
		my $insert = "UPDATE player_info set ff_${type}_neighbors = \"$tally->{'count'}\" where player_id = \"$href->{'player_id'}\"";
		$dbh->do($insert);
	}
}
