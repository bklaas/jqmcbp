#!/usr/bin/perl

use GD;
use GD::Graph::pie;
use DBI;
use strict;


my @years = ('2004', '2003', '2002', '2001');
my $logo = "/etc/httpd/htdocs/jqmcbp/images/jq_graph_logo.png";

for my $year (@years) {

print "$year\n";
my @category_data;
my @tally_data;
my @graph_data;
my $graph;


my $db = "jq_" . $year;

$db = 'johnnyquest' if $year eq '2004';

my $ref = get_tallies_from_db($db);
my %tallies = %$ref;


for (sort {$tallies{$a} <=> $tallies{$b} } keys %tallies) {
     push @category_data, $_;
     push @tally_data, $tallies{$_};
}

@graph_data = ( [ @category_data ] , [ @tally_data ] );

$graph = GD::Graph::pie->new(650,400);

$graph->set_title_font(gdGiantFont);
$graph->set_value_font(gdMediumBoldFont);

$graph->set(
	title	=>	"$year Locale Breakdown",
        logo	=>	$logo,
	logo_position	=>	'UR',
	suppress_angle	=>	3	
        );


my $gd = $graph->plot(\@graph_data); 
print "$year\n";
print "MAKING $year graph\n";
open(IMG, ">locale_$year.png");
binmode IMG;
print IMG $gd->png;

}
	

sub get_tallies_from_db {

my $db = shift;
my %tallies;
###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "$db";
my $location = "localhost";
my $port_num = "3306";

my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

my $dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
###############################################################

  my $sql = "select location from player_info";

  my $sth = $dbh->prepare ($sql);
  $sth->execute ();

  while (my $hashref = $sth->fetchrow_hashref()) {
        my $locale = $hashref->{location};
        $tallies{$locale}++;
   }

  $dbh->disconnect();
	return \%tallies;


}

