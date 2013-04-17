#!/usr/bin/perl

use strict;
my $dbh;

use DBI;
do "/data/cgi-bin/jq_globals.pl";
my @dbs = ('jq_2005', 'jq_2006', 'jq_2007', 'jq_2008', 'jq_2009', 'jq_2012', 'johnnyquest');
for my $db (@dbs) {
connect_to_db($db);

my %final_four;
for my $game (57..60) {
	my $ff_query = "select winner from games where game = \"game_$game\"";
	my $href = single_row_query($ff_query);
	my $gstring = 'game_' . $game;
	$final_four{$gstring} = $href->{'winner'}
}
	

#my %final_four = (
#			"game_57"	=>	"Florida",
#			"game_58"	=>	"UCLA",
#			"game_59"	=>	"Georgetown",
#			"game_60"	=>	"Ohio State"
#	);

my @ids;
my %ff_tally = ( 0	=>	0,
		1	=>	0,
		2	=>	0,
		3	=>	0,
		4	=>	0);

my $query = "select player_id from player_info where man_or_chimp = 'man' order by player_id";
if ($db eq 'jq_2005') {
	$query = "select player_id from player_info order by player_id";
}
my $ref = multi_row_query($query);
my $total;
for my $href (@$ref) {
	my $tally = 0;
	for my $key (keys %final_four) {
		my $query = "select count(*) as count, name from picks where game = \"$key\" and winner = \"$final_four{$key}\" and player_id = \"$href->{'player_id'}\" group by name";
		my $ref = single_row_query($query);
		my %temp = %$ref;
		if ($temp{'count'} == 1) {
			$tally++;
		}
	}
	$ff_tally{$tally}++;
	$total++;
}

print "$db\n";
for (0..4) {
	my $percentage = ($ff_tally{$_}/$total)*100;
	print "$_\t$ff_tally{$_}\t$percentage\n";
}
}
exit;
