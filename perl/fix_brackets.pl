#!/usr/bin/perl 
use strict;
use DBI;   # perl DBI module
 
use vars qw/ $dbh /;
do "jq_globals.pl";
connect_to_db();

###############################################################
############### connect to database ###########################
###############################################################
#my $database_name = "johnnyquest";
#my $location = "localhost";
#my $port_num = "3306";
#my $database = "DBI:mysql:$database_name:$location:$port_num";
#my $db_user = "nobody";
#
#my $dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
###############################################################

###############################################################
## make variables for the WINNERS
###############################################################

#my $email_sql = "select player_info.player_id as id from player_info, picks, teams where player_info.player_id = picks.player_id and teams.team = picks.winner and game = 'game_59' and teams.bracket_name = 'midwest' and player_info.how_found IS NOT NULL";
my $email_sql    = "select player_info.name, player_info.email, player_info.player_id as id, player_info.date_created from teams, picks, player_info where picks.winner = teams.team and picks.game = 'game_58' and teams.spot like \"east\%\" and player_info.player_id = picks.player_id";

my $sth = $dbh->prepare($email_sql);
$sth->execute;

my $email;
my %emails;
my $url;
my $i = 0;

#picks for game_9 - game_16 have to be moved to game_25 to game_32
#picks for game_17 - game_24 have to be moved to game_9 - game_16
#picks for game_25 - game_32 have to be moved to game_17 - game_24
#
#picks for game_37 - game_40 have to be moved to game_45 - game_48
#picks for game_41 - game_44 have to be moved to game_38 - game_40
#picks for game_45 - game_48 have to be moved to game_41 - game_44
#
#picks for game_51 - game_52 have to be moved to game_55 - game_56
#picks for game_53 - game_54 have to be moved to game_51 - game_52
#picks for game_55 - game_56 have to be moved to game_53 - game_54
#
#THEN
#
#take the dat file and update game_57 to game_63 with those data

my $translate = {
	game_9 => 'game_17',
	game_10 => 'game_18',
	game_11 => 'game_19',
	game_12 => 'game_20',
	game_13 => 'game_21',
	game_14 => 'game_22',
	game_15 => 'game_23',
	game_16 => 'game_24',
	game_17 => 'game_25',
	game_18 => 'game_26',
	game_19 => 'game_27',
	game_20 => 'game_28',
	game_21 => 'game_29',
	game_22 => 'game_30',
	game_23 => 'game_31',
	game_24 => 'game_32',
	game_25 => 'game_9',
	game_26 => 'game_10',
	game_27 => 'game_11',
	game_28 => 'game_12',
	game_29 => 'game_13',
	game_30 => 'game_14',
	game_31 => 'game_15',
	game_32 => 'game_16',

	game_37 => 'game_41',
	game_38 => 'game_42',
	game_39 => 'game_43',
	game_40 => 'game_44',
	game_41 => 'game_45',
	game_42 => 'game_46',
	game_43 => 'game_47',
	game_44 => 'game_48',
	game_45 => 'game_37',
	game_46 => 'game_38',
	game_47 => 'game_39',
	game_48 => 'game_40',

	game_51 => 'game_53',
	game_52 => 'game_54',
	game_53 => 'game_55',
	game_54 => 'game_56',
	game_55 => 'game_51',
	game_56 => 'game_52',
};

#my $reverse_it;
#while (my ($key, $value) = each %$translate) {
#   $reverse_it->{$value} = $key;
#}
#$translate = $reverse_it;

while (my $hashref = $sth->fetchrow_hashref()) {
	$i++;
	my $key = $hashref->{id};
	print "$i\t$key\n";
	my $picks_sql = "select * from picks where player_id = \"$key\"";
	my $aref = multi_row_query($picks_sql);
	for my $href (@$aref) {
		my $game = $href->{game};
		if ($translate->{$game}) {
			my $update = "UPDATE picks set game = \"transition_$translate->{$game}\" where game = \"$game\" and player_id = \"$key\"";
			print "$update\n";
			$dbh->do($update);
		}
	}
	my $update3 = "UPDATE player_info set how_found = \"bracket_fix\" where player_id = \"$key\"";
	print $update3 . "\n";
	$dbh->do($update3);
}

for my $game ( sort keys %$translate ) {
	my $update2 = "UPDATE picks set game = \"$game\" where game = \"transition_$game\"";
	print $update2 . "\n";
	$dbh->do($update2);
}


$sth->finish;
