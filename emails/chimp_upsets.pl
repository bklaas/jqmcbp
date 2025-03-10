#!/usr/bin/perl

my $dbh;

use DBI;
do "/etc/httpd/cgi-bin/jq_globals.pl";
connect_to_db();

my %upsets;

open(UPSETS,"<upsets");
while(<UPSETS>) {
	chomp;
	next if /^$/ || /^#/;
	my ($team, $key) = split /\t/, $_;
	$upsets{$key} = $team;
}
close(UPSETS);

for (sort keys %upsets) {
	my $query = "select picks.name, picks.winner from picks, player_info where picks.player_id = player_info.player_id and game = \"$_\" and winner = \"$upsets{$_}\" and man_or_chimp = 'chimp' order by name";
#	print $query . "\n";
	print "$upsets{$_}:  ";
	my $ref = multi_row_query($query);
	my @temp = @$ref;
	my @upset_pickers = (@upset_pickers, @temp);
	for (0..$#upset_pickers) {
		print "$upset_pickers[$_]{'name'}, ";
	}
	print "\n" . $#upset_pickers+1;
	print "\n\n";
}

#for (0..$#upset_pickers) {
#	print "<tr><td>$upset_pickers[$_]{'name'}</td><td>$upset_pickers[$_]{'winner'}</td></tr>\n";
#}
