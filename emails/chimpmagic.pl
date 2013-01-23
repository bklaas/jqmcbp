#!/usr/bin/perl

my $dbh;

use DBI;
do "/data/cgi-bin/jq_globals.pl";
connect_to_db();

my %upsets;

my %game8;
my %game16;

	my $query = "select picks.name, picks.winner from picks, player_info where picks.player_id = player_info.player_id and game = \"game_8\" and winner = \"Norfolk State\" order by name";
	my $ref = multi_row_query($query);
	for my $chimp (@$ref) {
		$game8{$chimp->{name}}++;
	}

	my $query = "select picks.name, picks.winner from picks, player_info where picks.player_id = player_info.player_id and game = \"game_16\" and winner = \"Lehigh\" order by name";
	my $ref = multi_row_query($query);
	for my $chimp (@$ref) {
		$game16{$chimp->{name}}++;
	}

for my $chimp (sort keys %game8) {
	if (exists $game16{$chimp}) {
		$union{$chimp}++;
	}
}

my $i = 0;
print "<div id = 'chimpmagic'>\n";
print "<h3>Chimps that picked BOTH Lehigh and Norfolk State</h3>\n";
for my $chimp (sort keys %union) {
	print "$chimp<br>\n";
	$i++;
}
print "</div>\n";

print "$i\n";

#for (0..$#upset_pickers) {
#	print "<tr><td>$upset_pickers[$_]{'name'}</td><td>$upset_pickers[$_]{'winner'}</td></tr>\n";
#}
