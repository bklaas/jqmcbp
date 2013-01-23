#!/usr/bin/perl 

use DBI;   # perl DBI module
use strict;
 
###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "jq_2009";
my $location = "localhost";
my $port_num = "3306";
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

my $dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
###############################################################

###############################################################
## make variables for the WINNERS
###############################################################

open(BOUNCE, "<bounced.txt");
while(<BOUNCE>) {
	chomp;

	my $email_sql = "SELECT name, email from player_info where email = \"$_\"";

	my $sth = $dbh->prepare($email_sql);
	$sth->execute;
	while (my $hashref = $sth->fetchrow_hashref()) {
		print $hashref->{name} . "\t" . $hashref->{email} . "\n";
	}
	$sth->finish;
}
close(BOUNCE);

