#!/usr/bin/perl
$| = 1;  # make sure output is unbuffered

use DBI;   # perl DBI module

package main;
my @brackets;
 
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

my $outfile = "/home/bklaas/jqmcbp/web/2017/brackets.order";

open(ORDER, "<$outfile");
while(<ORDER>) {
	chomp;
	push @regions, $_;
}
close(ORDER);

# set region for each game
update_games(@regions);

sub update_games {

        my @order = @_;

        my @first = qw/ 1 2 3 4 5 6 7 8 33 34 35 36 49 50 57/;
        my @second = qw/ 9 10 11 12 13 14 15 16 37 38 39 40 51 52 58/;
        my @third = qw/ 17 18 19 20 21 22 23 24 41 42 43 44 53 54 59/;
        my @fourth = qw/ 25 26 27 28 29 30 31 32 45 46 47 48 55 56 60/;

        my @games = ( \@first, \@second, \@third, \@fourth);

        for my $i (0..3) {
                my $region = $order[$i];
                my $nums = $games[$i];
                for (@$nums) {
                        my $game = "game_" . $_;
                        my $update = "UPDATE games set region = \"$region\" where game = \"$game\"";
                        $dbh->do($update) or die "$DBI::ERRSTR";
                        print $update . "\n";
                }

        }

}

