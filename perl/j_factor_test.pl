#!/usr/bin/perl

use DBI;
#use Data::Dump qw(dump);

my $dbh;
connect_to_database();

# chittenden
my $player_id = 19361;

my $ids = [];

my $query = "select player_id from player_info where man_or_chimp = \"man\"";
my $sth = $dbh->prepare($query);
$sth->execute();
while (my $hashref = $sth->fetchrow_hashref) {
    my $id = $hashref->{player_id};
    push @$ids, $id;
}
$sth->finish();

#$ids = [ 19361 ];
my $i = 0;
for my $player_id (@$ids) {
    ###################################
    # calculate j and j2 factors
    my $sigma1; my $sigma2;
    my $frag = make_frag("1","32");

    $query = "select sum(teams.seed) as total, picks.name from teams, picks where teams.team = picks.winner and picks.player_id = \"$player_id\" and ( $frag ) group by picks.player_id order by total";
    #print "$query\n";
    my $frag2 = make_frag("49","56");
    my $query2 = "select sum(teams.seed) as total, picks.name from teams, picks where teams.team = picks.winner and picks.player_id = \"$player_id\" and ( $frag2 ) group by picks.player_id order by total";
    my $query3 = "select j2_factor from player_info where player_id = \"$player_id\"";

    $sth = $dbh->prepare($query);
    $sth->execute();
    while (my $hashref = $sth->fetchrow_hashref) {
        $sigma1 = $hashref->{total};
    }
    $sth->finish();

    $sth = $dbh->prepare($query2);
    $sth->execute();
    while (my $hashref = $sth->fetchrow_hashref) {
        $sigma2 = $hashref->{total};
    }
    $sth->finish();

    my $db_j_factor;
    $sth = $dbh->prepare($query3);
    $sth->execute();
    while (my $hashref = $sth->fetchrow_hashref) {
        $db_j_factor = $hashref->{j2_factor};
    }
    $sth->finish();


    my $j = (($sigma1 - 144) / 256);
    my $j_factor = 100 * $j;
    my $j2 = ( $j + ( 4 * (($sigma2 -12)/112)) );
    my $j2_factor = 20 * $j2;
    my $diff = $j2_factor - $db_j_factor;
    if ($diff > 0.02) {
        $i++;
        print "$i\t$player_id\tj_factor: $j_factor\tj2_factor: $j2_factor\tDB j2_factor: $db_j_factor\tDIFF: $diff\n";
    }
}

$dbh->disconnect();

sub make_frag {
	# sub to deal with new naming scheme for games
	my $first = shift;
	my $last = shift;
	my $frag;
	for ($first..$last) {
		$frag .= " picks.game = \"game_$_\" ";
		$frag .= "OR " unless $_ == $last;
	}
	return $frag;
}

sub connect_to_database {
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
}
