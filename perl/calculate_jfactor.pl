#!/usr/bin/perl

use DBI;

###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "johnnyquest";
my $location = "localhost";
my $port_num = "3306";
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

$dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
################################################################

# get player_ids
my $q = "SELECT player_id from player_info order by player_id";
my $sth = $dbh->prepare($q);
$sth->execute();
my @ids;
while (my $hashref = $sth->fetchrow_hashref) {
	my $id = $hashref->{player_id};
	push @ids, $id;
}

#my $player_id = 115;



###################################
# calculate j and j2 factors
for my $player_id (@ids) {
my $sigma1; my $sigma2;

my $query = "select sum(teams.seed) as total, picks.name from teams, picks where teams.team = picks.winner and picks.player_id = \"$player_id\" and picks.game like \"%1_%\" group by picks.player_id order by total";

my $query2 = "select sum(teams.seed) as total, picks.name from teams, picks where teams.team = picks.winner and picks.player_id = \"$player_id\" and picks.game like \"%3_%\" group by picks.player_id order by total";
$sth = $dbh->prepare($query);
$sth->execute();
while (my $hashref = $sth->fetchrow_hashref) {
	$sigma1 = $hashref->{total};
	print "sigma1:\t$sigma1\n";
}
$sth->finish();

$sth = $dbh->prepare($query2);
$sth->execute();
while (my $hashref = $sth->fetchrow_hashref) {
	$sigma2 = $hashref->{total};
	print "sigma2:\t$sigma2\n";
}
$sth->finish();

my $j = (($sigma1 - 144) / 256);
my $j_factor = 100 * $j;
my $j2 = ( $j + ( 4 * (($sigma2 -12)/112)) );
my $j2_factor = 20 * $j2;

print "j_factor: $j_factor\tj2_factor: $j2_factor\n";
my $insert = "UPDATE player_info set j_factor = \"$j_factor\", j2_factor = \"$j2_factor\" where player_id = \"$player_id\"";
$dbh->do($insert);
}

###################################
## disconnect from database
$dbh->disconnect ();

