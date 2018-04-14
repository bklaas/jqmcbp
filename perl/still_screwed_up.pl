#!/usr/bin/perl 
use strict;
use DBI;   # perl DBI module

 
###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "johnnyquest";
my $location = "localhost";
my $port_num = "3306";
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

my $dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
###############################################################

###############################################################
## make variables for the WINNERS
###############################################################

my $email_sql = "select player_info.name as name, player_info.email as email, player_info.champion as champ, player_info.player_id as id, player_info.how_found as url from player_info, picks, teams where player_info.player_id = picks.player_id and teams.team = picks.winner and game = 'game_59' and teams.bracket_name = 'midwest'";

my $sth = $dbh->prepare($email_sql);
$sth->execute;

my $email;
my %emails;
my $url;
while (my $hashref = $sth->fetchrow_hashref()) {
	my $key = $hashref->{id};
	$email = $hashref->{email};
	$emails{$key} = {
		url => $hashref->{url},
		email => $hashref->{email},
		name => $hashref->{name},
		champ => $hashref->{champ},
		ff1 => $hashref->{ff1},
		ff2 => $hashref->{ff2},
	};
	#my $random = int(rand(100000)) + 100000;
	#my $insert = "UPDATE player_info set how_found = \"$random\" where player_id = \"$key\"";
	#print $insert . "\n";
	#$dbh->do($insert);
}

$sth->finish;
###open file for writing###
#open (EMAILS,">the140.csv");
my $i = 1;
foreach my $key (sort keys %emails) {
	#print join(',',$i, $key,"\"$emails{$key}{name}\"",$emails{$key}{email});
	print join(" ",$i,"\"$emails{$key}{name}\"", $emails{$key}{champ}, "http://benklaas.com/jqmcbp/fix_it.cgi?id=$key");
	print  "\n";
	$i++;
}
close(EMAILS);
