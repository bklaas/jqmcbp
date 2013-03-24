#!/usr/bin/perl

use GD;
use GD::Graph::pie;
use strict;

my $year = '2013';
my %tallies;
my @category_data;
my @tally_data;
my @graph_data;
my $graph;
my $logo = "jq_graph_logo.gif";

get_tallies_from_db();


for (sort {$tallies{$a} <=> $tallies{$b} } keys %tallies) {
     push @category_data, $_;
     push @tally_data, $tallies{$_};
}

@graph_data = ( [ @category_data ] , [ @tally_data ] );

#$graph = GD::Graph::pie->new();
$graph = GD::Graph::pie->new(650,400);

#/usr/share/fonts/truetype/liberation:
#LiberationMono-BoldItalic.ttf  LiberationSans-BoldItalic.ttf        LiberationSansNarrow-Bold.ttf     LiberationSerif-BoldItalic.ttf
#LiberationMono-Bold.ttf        LiberationSans-Bold.ttf              LiberationSansNarrow-Italic.ttf   LiberationSerif-Bold.ttf
#LiberationMono-Italic.ttf      LiberationSans-Italic.ttf            LiberationSansNarrow-Regular.ttf  LiberationSerif-Italic.ttf
#LiberationMono-Regular.ttf     LiberationSansNarrow-BoldItalic.ttf  LiberationSans-Regular.ttf        LiberationSerif-Regular.ttf

$graph->set_title_font('/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf', 14);
$graph->set_value_font('/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf', 12);

$graph->set(
	title	=>	"$year Locale Breakdown",
        logo	=>	$logo,
	logo_position	=>	'UR',
	suppress_angle	=>	3	
        );


my $gd = $graph->plot(\@graph_data); 
open(IMG, ">locale_$year.png");
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

  my $sql = "select location from player_info where man_or_chimp = \"man\"";

  my $sth = $dbh->prepare ($sql);
  $sth->execute ();

  while (my $hashref = $sth->fetchrow_hashref()) {
        my $locale = $hashref->{location};
        $tallies{$locale}++;
   }

  $dbh->disconnect();


}

