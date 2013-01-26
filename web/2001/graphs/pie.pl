#!/usr/bin/perl -w

use strict; 

use GD::Graph::pie;
use GD;
use DBI;

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

my $png_path = "/etc/httpd/htdocs/johnnyquest/2001/graphs";

my @data;
my @fields = ("east1_1", "east1_2", "east1_3", "east1_4", "east1_5", "east1_6", "east1_7", "east1_8", "midwest1_1", "midwest1_2", "midwest1_3", "midwest1_4", "midwest1_5", "midwest1_6", "midwest1_7", "midwest1_8", "west1_1", "west1_2", "west1_3", "west1_4", "west1_5", "west1_6", "west1_7", "west1_8", "south1_1", "south1_2", "south1_3", "south1_4", "south1_5", "south1_6", "south1_7", "south1_8", "east2_1", "east2_2", "east2_3", "east2_4", "midwest2_1", "midwest2_2", "midwest2_3","midwest2_4", "west2_1", "west2_2", "west2_3", "west2_4", "south2_1", "south2_2", "south2_3", "south2_4", "east3_1", "east3_2", "midwest3_1", "midwest3_2", "west3_1", "west3_2", "south3_1", "south3_2", "east4_1", "midwest4_1", "west4_1", "south4_1", "ff1", "ff2", "champion");
my $ary_val;

for $ary_val (0..$#fields) {
     @data = ();
     grab_game_data($fields[$ary_val]);

my $region; my $round; my $suppress_angle = 0; 

  if ($fields[$ary_val] =~ /east/) {
         $region = "East Region";
  } elsif ($fields[$ary_val] =~ /midwest/) {
         $region = "Midwest Region";
  } elsif ($fields[$ary_val] =~ /west/) {
         $region = "West Region";
  } elsif ($fields[$ary_val] =~ /south/) {
         $region = "South Region";
  } elsif ($fields[$ary_val] =~ /ff/) {
     if ($fields[$ary_val] =~ /1/) {
         $region = "Final Four Game 1";
     } else {
         $region = "Final Four Game 2";
     }
         $suppress_angle = 5;
  } else {
         $region = "Championship";
         $suppress_angle = 5;
  }       

  if ($fields[$ary_val] =~ /1_/) {
       $round = "First Round";
       
  } elsif ($fields[$ary_val] =~ /2_/) {
       $round = "Second Round";
         $suppress_angle = 5;
        
  } elsif ($fields[$ary_val] =~ /3_/) {
       $round = "Sweet Sixteen";
         $suppress_angle = 5;
  } elsif ($fields[$ary_val] =~ /4_/) {
       $round = "Regional Finals";
         $suppress_angle = 5;
  }
    
 my $graph = GD::Graph::pie->new(640, 400);

  $graph->set_title_font(gdLargeFont) or die "couldn't do it: $!";

  $graph->set( 
         title	=> "$region $round",
         logo => 'jq_graph_logo.png',
         logo_position => 'UR',
         suppress_angle => $suppress_angle
         );

  $graph->set_value_font(gdMediumBoldFont)  or die "couldn't set font: $!";

 my $gd = $graph->plot(\@data);

print STDOUT "Making graph for game $fields[$ary_val]\n";

  open(IMG, ">$png_path/$fields[$ary_val].png") or die $!;
     binmode IMG;
     print IMG $gd->png;

open (HTML,">$png_path/$fields[$ary_val].html") or die $!;
print HTML "<html><body><img src=\"$fields[$ary_val].png\"></body></html>\n";
close (HTML);

}

my $disc = $dbh->disconnect ();

sub grab_game_data {
########################################################################
#################### pull in count for a game info #####################
########################################################################
my $game = $_[0];

my $game_sql = "select count(*) as count, winner from picks where game = \"$game\" group by winner order by count desc";


my $sth = $dbh->prepare($game_sql);
unless ($sth->execute) {
 die "Statement failed" . $sth->errstr;
   }

my $hashref;


my $i = 0;
 while ($hashref = $sth->fetchrow_hashref()) {
        $data[0][$i] = $hashref->{winner} . " (" . $hashref->{count} . ")";
        $data[1][$i] = $hashref->{count};
        $i++;
 }
$sth->finish;


}
