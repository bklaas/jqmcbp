#!/usr/bin/perl

use DBI;

do "jq_globals.pl";
use vars qw/ $dbh /;
connect_to_db();

# get bracket order
my @brackets = get_bracket_order();

for my $i (1..60) {
	my $j;
	if ($i <= 8 || ($i >= 33 && $i <= 36) || ($i >= 49 && $i <= 50) || $i == 57) {
		$j = 0;
	} elsif ($i <= 16 || $i <= 40 || $i <= 52 || $i == 58) {
		$j = 1;
	} elsif ($i <= 24 || $i <= 44 || $i <= 54 || $i == 59) {
		$j = 2;
	} elsif ($i <= 32 || $i <= 48 || $i <= 56 || $i == 60) {
		$j = 3;
	}
	my $update = "UPDATE games set region = '$brackets[$j]' where game = 'game_$i';\n";
	print "$update\n";
	$dbh->do($update);
}
