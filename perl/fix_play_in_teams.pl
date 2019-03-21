#!/usr/bin/perl 
#
use strict;
use DBI;   # perl DBI module
 
use vars qw/ $dbh /;
do "/data/benklaas.com/jqmcbp/jq_globals.pl";
connect_to_db();

# set to 0 for dry run
my $update_it = 1;

###########################################
# UPDATE THIS HASH AND THEN RUN THE PROGRAM
my $play_in_games = {
'Belmont/Temple'=> 'Belmont',
'NCCU/NDSU' => 'North Dakota State',
'FDU/Prairie View' => 'Fairleigh Dickinson',
"ASU/St John's" => 'Arizona State',
};
#############################################

for my $slash (keys %$play_in_games) {
    my $w = $play_in_games->{$slash};
    my $update = "UPDATE player_info set champion = \"$w\" where champion = \"$slash\"";
    print "$update\n";
    $dbh->do($update) if $update_it;

    $update = "UPDATE player_info set alma_mater = \"$w\" where alma_mater = \"$slash\"";
    print "$update\n";
    $dbh->do($update) if $update_it;

    $update = "UPDATE teams set team = \"$w\" where team = \"$slash\"";
    print "$update\n";
    $dbh->do($update) if $update_it;

    $update = "UPDATE picks set winner = \"$w\" where winner = \"$slash\"";
    print "$update\n";
    $dbh->do($update) if $update_it;
}
