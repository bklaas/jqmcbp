#!/usr/bin/perl 


use DBI;   # perl DBI module

###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "johnnyquest";
my $location = "localhost";
my $port_num = "3306";
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

$dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
###############################################################

$dbh->do("INSERT INTO players
	(name)
        VALUES (\"WINNERS\")");

