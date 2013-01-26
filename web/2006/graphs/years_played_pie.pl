#!/usr/bin/perl

use GD;
use GD::Graph::pie;
use strict;


my %tallies;
my @category_data;
my @tally_data;
my @graph_data;
my $graph;
my $logo = "/etc/httpd/htdocs/jqmcbp/images/jq_graph_logo.png";

get_tallies_from_db();

#for (sort {$tallies{$a} <=> $tallies{$b} } keys %tallies) {
for (sort {$a <=> $b}  keys %tallies) {
     push @category_data, $_;
     push @tally_data, $tallies{$_};
}

@graph_data = ( [ @category_data ] , [ @tally_data ] );

#$graph = GD::Graph::pie->new();
$graph = GD::Graph::pie->new(650,400);

$graph->set_title_font(gdGiantFont);
$graph->set_value_font(gdMediumBoldFont);

$graph->set(
	title	=>	'Years JQMCBP Experience',
        logo	=>	$logo,
	logo_position	=>	'UR',
	show_values	=>	1,
	suppress_angle	=>	3	
        );


my $gd = $graph->plot(\@graph_data); 
open(IMG, '>years_played.png');
binmode IMG;
print IMG $gd->png;
	

sub get_tallies_from_db {

use DBI;
###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "johnnyquest";
my $location = "localhost";
my $port_num = "3306";

# this would need to be slightly altered for other databases
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

my $dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
###############################################################

  my $sql = "select years_played from player_info where man_or_chimp = \"man\"";

  my $sth = $dbh->prepare ($sql);
  $sth->execute ();

  while (my $hashref = $sth->fetchrow_hashref()) {
        my $years_played = $hashref->{years_played};
	if ($years_played == 1) {
		$years_played = "1 year";
	} elsif ($years_played < 4) {
		$years_played .= " years";
	}
        $tallies{$years_played}++;
   }

  $dbh->disconnect();


}

