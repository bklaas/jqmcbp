#!/usr/bin/perl 

use DBI;   # perl DBI module
use Statistics::Descriptive;

package main;
 
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

my $data_dir = "/tmp";

###############################################################
## make variables for the WINNERS
###############################################################

# new SQL for new schema
# WORKS getting winners hash populated from games table!
$winners_sql = "select game, winner from games";

my $sth = $dbh->prepare($winners_sql);
$sth->execute;

while ($hashref = $sth->fetchrow_hashref()) {
      $game_name = $hashref->{game};
      $winners{$game_name} = $hashref->{winner};
}

$sth->finish;
########################################################################
########################initialize some variables#######################
########################################################################
my @midwest_1 = ( "midwest1_1", "midwest1_2", "midwest1_3", "midwest1_4",
                "midwest1_5", "midwest1_6", "midwest1_7", "midwest1_8");
my @west_1 = ( "west1_1", "west1_2", "west1_3", "west1_4", "west1_5", "west1_6",
                "west1_7", "west1_8");
my @east_1 = ( "east1_1", "east1_2", "east1_3", "east1_4", "east1_5", "east1_6",
                "east1_7", "east1_8");
my @south_1 = ( "south1_1", "south1_2", "south1_3", 
                "south1_4", "south1_5", "south1_6", "south1_7", "south1_8");


my @midwest_2 = ("midwest2_1", "midwest2_2", "midwest2_3", "midwest2_4");
my @west_2 = ("west2_1", "west2_2", "west2_3", "west2_4" );
my @south_2 = ("south2_1", "south2_2", "south2_3", "south2_4");
my @east_2 = ("east2_1", "east2_2", "east2_3", "east2_4");

my @midwest_3 = ("midwest3_1", "midwest3_2");
my @west_3 = ("west3_1", "west3_2");
my @south_3 = ("south3_1", "south3_2");
my @east_3 = ("east3_1", "east3_2");


@first_round = ( @west_1, @south_1, @midwest_1, @east_1);
@second_round = (@west_2,@south_2,@midwest_2,@east_2); 
@third_round = ( @west_3, @south_3, @midwest_3, @east_3 );
@fourth_round = ("west4_1","south4_1","midwest4_1","east4_1");  
@final_four = ("ff1","ff2");  
@championship = ("champion");
########################################################################



# calculate all scores with one sql statement

my $male_total = 0;
my  $female_total = 0;
my $male_pool = 0;
my $female_pool = 0;

foreach my $gender ("M","F") {
$score_sql = "select sum(games.score) as score, 
              picks.name, player_info.candybar, 
              player_info.gender, player_info.location, 
              player_info.champion, player_info.player_id
              from games, picks, player_info
              where
              player_info.gender = \"$gender\" and
              picks.game = games.game and
              picks.winner = games.winner and
              picks.name = player_info.name
              group by name order by score desc";

my $sth = $dbh->prepare($score_sql);
$sth->execute;


while (my @returned_scores = $sth->fetchrow_array()) {
   if ($gender eq "M") {
      push @male_scores, $returned_scores[0];
      $male_total += $returned_scores[0];
      $male_pool++;
   } else {
      push @female_scores, $returned_scores[0];
      $female_total += $returned_scores[0];
      $female_pool++;
   }
}

}



my $male_stat = Statistics::Descriptive::Full->new();
$male_stat->add_data(@male_scores);

my $female_stat = Statistics::Descriptive::Full->new();
$female_stat->add_data(@female_scores);

my $male_avg = sprintf("%.2f", $male_stat->mean());
my $female_avg = sprintf("%.2f", $female_stat->mean());
my $male_median = sprintf("%.2f", $male_stat->median());
my $female_median = sprintf("%.2f", $female_stat->median());
my $male_sd = sprintf("%.2f", $male_stat->standard_deviation());
my $female_sd = sprintf("%.2f", $female_stat->standard_deviation());
print STDOUT "\tn\tMean\tMedian\tStandard Deviation\n";
print STDOUT "Men:\t$male_pool\t$male_avg\t$male_median\t$male_sd\n";
print STDOUT "Women:\t$female_pool\t$female_avg\t$female_median\t$female_sd\n";

