#!/usr/bin/perl 

use strict; 

use GD::Graph::linespoints;
use GD;
use DBI;

use vars qw/ $dbh /;
do "/etc/httpd/cgi-bin/jq_globals.pl";

connect_to_db();

my $png_path = "/etc/httpd/htdocs/jqmcbp/graphomatic";
my $logo_path ="/etc/httpd/htdocs/jqmcbp/images/jq_graph_logo.png";

my @data;

my $graphdir = "/etc/httpd/htdocs/jqmcbp/graphomatic";

my $player1; my $player2;

if ($ARGV[0]) {
    $player1 = $ARGV[0]; $player2 = $ARGV[1];
} else {
    $player1 = "33";
    $player2 = "34";
}


my @round_ary; my @player1_scores; my @player2_scores;
my @region_ary; my @player1_region_scores; my @player2_region_scores;
my %names;

grab_names();
grab_score_data();

my $disc = $dbh->disconnect ();
######################################
# Get rounds data into usable format #
######################################

    # rearrange into format for graphing
    my @data_sorted = ( [ @round_ary ] , [ @player1_scores ] , [ @player2_scores ] );

######################################
# Get region data into usable format #
######################################

     my @region_data_sorted = ( [ @region_ary ] , [ @player1_region_scores ] , [ @player2_region_scores ] );

# shorten those long ass names
my $trunc_name1 = substr($names{$player1}, 0, 25);
my $trunc_name2 = substr($names{$player2}, 0, 25);
######################################
# Make graph for regional data       #
######################################

 my $region_graph = GD::Graph::linespoints->new(640,300);

  $region_graph->set_title_font(gdMediumBoldFont) or die "couldn't do it: $!";
#  $region_graph->set_legend("$names{$player1}", "$names{$player2}");
  $region_graph->set_legend("$trunc_name1", "$trunc_name2");
  $region_graph->set( 
         t_margin => "2",
         b_margin => "2",
         l_margin => "2",
         r_margin => "2",
         box_axis => 0,
         x_label_position => 0.5,
         y_min_value => 0,
         title	=> "$trunc_name1 vs. $trunc_name2 by Region",
         dclrs => ["red", "blue"], 
         markers => [2, 4],
         marker_size => 6,
         x_label => "Region",
         y_label => "Score",
         logo => $logo_path,
         logo_resize => 1,
         logo_position => 'UR',
	 legend_placement => 'RC'
         );

#  $region_graph->set_value_font(gdMediumBoldFont)  or die "couldn't set font: $!";

 my $gd = $region_graph->plot(\@region_data_sorted);

print STDOUT "Making regional graph for $names{$player1} vs $names{$player2}\n";

  open(IMG1, ">$png_path/$player1" . "vs" . "$player2" . "_1" . ".png") or die $!;
     binmode IMG;
     print IMG1 $gd->png;
######################################
# Make graph for rounds data         #
######################################
 my $graph = GD::Graph::linespoints->new(640, 300);

  $graph->set_title_font(gdMediumBoldFont) or die "couldn't do it: $!";
  $graph->set_legend("$trunc_name1", "$trunc_name2");
#  my $values = $graph->copy;
  
  $graph->set( 
         t_margin => "2",
         b_margin => "2",
         l_margin => "2",
         r_margin => "2",
         box_axis => 0,
         x_label_position => 0.5,
         y_min_value => 0,
         title	=> "$trunc_name1 vs. $trunc_name2 by Round",
         markers => [2, 4],
         marker_size => 6,
         dclrs => ["red", "blue"], 
         x_label => "Round",
         y_label => "Score",
         logo => "$logo_path",
         logo_resize => 1,
         logo_position => 'UR',
	 legend_placement => 'RC'
         );

#  $graph->set_value_font(gdMediumBoldFont)  or die "couldn't set font: $!";

 my $gd = $graph->plot(\@data_sorted);

print STDOUT "Making rounds graph for $names{$player1} vs $names{$player2}\n";

  open(IMG, ">$png_path/$player1" . "vs" . "$player2" . "_2" . ".png") or die $!;
     binmode IMG;
     print IMG $gd->png;


sub grab_score_data {

########################################################################
#################### pull in count for a game info #####################
########################################################################
open (ROUND,"<$graphdir/round.sql");

my $round_sql;

while (<ROUND>) {

    my $line = $_;
    unless ($line =~ /^#/) {
          $round_sql .= $line;
    }
}
close (ROUND);


open (REGION,"<$graphdir/region.sql");

my $region_sql;

while (<REGION>) {

    my $line = $_;
    unless ($line =~ /^#/) {
          $region_sql .= $line;
    }
}
close (REGION);


##################################
#      get ROUNDS data           #
##################################
my $round; my @rounds = ("1", "2", "3", "4", "5", "6"); my $temp_sql;
my $i = 0;

foreach $round (@rounds) {

$temp_sql = $round_sql;

$temp_sql =~ s/NUMBER1/$player1/g;
$temp_sql =~ s/NUMBER2/$player2/g;
$temp_sql =~ s/ROUND/$round/g;


my $sth = $dbh->prepare($temp_sql);
unless ($sth->execute) {
 die "Statement failed" . $sth->errstr;
   }

my $player_1_null = 1;
my $player_2_null = 1;
while (my @ary = $sth->fetchrow_array()) {

      #   $round_ary = $ary[0];
       if ($player1 == $ary[0]) {
         push @player1_scores, $ary[2];
         push @round_ary, $ary[1];
	 $player_1_null = 0;
       } elsif ($player2 == $ary[0]) {
         push @player2_scores, $ary[2];
	 $player_2_null = 0;
       }
#        $data[0][$i] = $ary[0];
#        $data[1][$i] = $ary[1];
#        $data[2][$i] = $ary[2];
        $i++;
}

$sth->finish;

#if ($player_1_null) {
#   push @round_ary, $round;
#}
#if ($player_2_null) {
#   push @round_ary, $round;
#}

}

##################################
#      get REGION data           #
##################################
my $region; 
my @regions = get_bracket_order(); 
my $temp_sql;

foreach $region (@regions) {

 $temp_sql = $region_sql;

 $temp_sql =~ s/NUMBER1/$player1/g;
 $temp_sql =~ s/NUMBER2/$player2/g;
 $temp_sql =~ s/REGION/$region/g;

 my $sth = $dbh->prepare($temp_sql);
    unless ($sth->execute) {
         die "Statement failed" . $sth->errstr;
    }

 my $player_1_null = 1;
 my $player_2_null = 1;
 while (my @ary = $sth->fetchrow_array()) {

       if ($player1 == $ary[0]) {
         push @player1_region_scores, $ary[2];
         push @region_ary, $ary[1];
         $player_1_null = 0;
       } elsif ($player2 == $ary[0]) {
         push @player2_region_scores, $ary[2];
         $player_2_null = 0;
       }
 }
 $sth->finish;

 if ($player_1_null) {
    push @player1_region_scores, 0;
    push @region_ary, $region;
 }
 if ($player_2_null) {
    push @player2_region_scores, 0;
    push @region_ary, $region;
 }
}



}

sub grab_names {
   
    my $id;

    foreach $id ($player1, $player2) {

        my $name_sql = "select name, player_id from player_info where player_id = $id";

        my $sth = $dbh->prepare($name_sql);

           unless ($sth->execute) {
             die "Statement failed" . $sth->errstr;
           }

        my $hashref;

        while ($hashref = $sth->fetchrow_hashref()) {
            $names{$id} = $hashref->{name};      
        }
     
        $sth->finish;
    }

}

