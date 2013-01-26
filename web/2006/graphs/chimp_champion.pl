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
my $png_path = "/etc/httpd/htdocs/jqmcbp/graphs";
my $logo_path = "/etc/httpd/htdocs/jqmcbp/graphs/jq_graph_logo.png";

my @data;
my @fields;
for (63..63) {
	my $game = "game_" . $_;
	push @fields, $game;
}
my $ary_val;

for $ary_val (0..$#fields) {
     @data = ();
     grab_game_data($fields[$ary_val]);

my $round; my $suppress_angle = 3; 
	$round = "Championship"; 
    
 my $graph = GD::Graph::pie->new(640, 400);

  $graph->set_title_font(gdLargeFont) or die "couldn't do it: $!";

  $graph->set( 
         title	=> "$round",
         logo => "$logo_path",
         logo_position => 'UR',
         suppress_angle => $suppress_angle
         );

  $graph->set_value_font(gdMediumBoldFont)  or die "couldn't set font: $!";

 my $gd = $graph->plot(\@data);

print STDOUT "Making graph for game $fields[$ary_val]\n";

  open(IMG, ">$png_path/chimp_$fields[$ary_val].png") or die $!;
     binmode IMG;
     print IMG $gd->png;

open (HTML,">$png_path/chimp_$fields[$ary_val].html") or die $!;
print HTML "<html><body><img src=\"chimp_$fields[$ary_val].png\"></body></html>\n";
close (HTML);

}

my $disc = $dbh->disconnect ();

sub grab_game_data {
########################################################################
#################### pull in count for a game info #####################
########################################################################
my $game = $_[0];

my $game_sql = "select count(*) as count, picks.winner from picks, player_info where picks.player_id = player_info.player_id and player_info.man_or_chimp = \"chimp\" and picks.game = \"$game\" group by picks.winner order by count desc";
print "$game_sql\n";


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
