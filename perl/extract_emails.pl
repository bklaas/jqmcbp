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

###############################################################
## make variables for the WINNERS
###############################################################

$email_sql = "select name, email from player_info";

my $sth = $dbh->prepare($email_sql);
$sth->execute;

while ($hashref = $sth->fetchrow_hashref()) {
        $name = $hashref->{name};
        $email_address{$name} = $hashref->{email};
}

$sth->finish;

###open file for writing###

open (EMAILS,">/tmp/2002_entries.txt");

foreach $key (keys %email_address) {
     print EMAILS "$email_address{$key}\n";
}

close(EMAILS);
