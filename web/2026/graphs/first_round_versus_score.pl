#!/usr/bin/perl

use DBI;
$| = 1;

my $dbh; my $sth;
my $webdir = "/etc/httpd/htdocs/johnnyquest/2003/graphs/";

my $graph_name;

my $graph = "current_score_vs_first_round_score.png";
my $field1 = "Current Score";
my $field2 = "First Round Score";
my $title = "Current Score vs. First Round Score comparison";

my $highest;
my $graph_name = "$webdir/$graph";
my @y_data; my @x_data;

print "making scatter plot...";

connect_to_johnnyquest();

query_for_data($field1, $field2);

make_scatter_plot($graph_name, $field1, $field2, $title);

print "done\n";

sub query_for_data {

  my @queries = (

                "select sum(games.score) as score, 
              picks.player_id from games, picks, player_info
              where
              picks.game = games.game and
		player_info.man_or_chimp = \"man\" and
              picks.game like \"%1_%\" and
              picks.winner = games.winner and
              picks.player_id = player_info.player_id
              group by player_id order by picks.player_id",

                "select sum(games.score) as score, 
              picks.player_id from games, picks, player_info
              where
              picks.game = games.game and
              picks.winner = games.winner and
              picks.player_id = player_info.player_id
              group by player_id order by picks.player_id"
	);


my $i = 0;
foreach my $query (@queries) {

  $sth = $dbh->prepare ($query);
  $sth->execute ();
 
  my $j = 0;
  while (my @ary = $sth->fetchrow_array()) {
     my $val;
         $val = $ary[0];
         $ary_ref = "ary$i";
         $$ary_ref[$j] = $val;
         $j++;
  }
$i++;
}

}

sub make_scatter_plot {
######################################
# Make scatter plot                  #
######################################

use Chart::Plot;

  my $graphomatic = shift;
  my $field1 = shift;
  my $field2 = shift;
  my $title = shift;

my $x_label = $field1; 
my $y_label = $field2; 

my $plot = Chart::Plot->new(500,500);

my $gd = $plot->getGDobject;
my $occam_blue = $gd->colorAllocate(0,38,137);

$plot->setData (\@ary0, \@ary1, "Points Noline Blue");
$plot->setGraphOptions ('title' => $title,
                        'horAxisLabel' => "First Round Score",
                        'vertAxisLabel' => "Current Score");


           open (WR,">$graphomatic") or die ("Failed to write file: $!");
           binmode WR;            # for DOSish platforms
           print WR $plot->draw();
           close WR;

  chmod 0777, $graphomatic;

}

sub connect_to_johnnyquest {
 
###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "johnnyquest";
my $location = "localhost";
my $port_num = "3306";
 
# this would need to be slightly altered for other databases
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";
 
$dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
 
###############################################################
 
}          

