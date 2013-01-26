#!/usr/bin/perl

use GD;
use GD::Graph::lines;
use strict;

my @timestamps;
my @labels;
my @data;
my $graph;
my $logo = "/etc/httpd/htdocs/jqmcbp/images/jq_graph_logo.png";

use Time::Local;
my $start_time = timelocal(00,00,16,13,2,2005);
my $end_time = timelocal(00,00,9,17,2,2005);

#my $start_time = time;
#print "$start_time\t$end_time\n";

get_timestamps_from_db();

compile_data();

# sort timestamps
#my @sorted_timestamps = sort @timestamps;

my @graph_data = ( [ @labels ] , [ @data ] );

#$graph = GD::Graph::pie->new();
$graph = GD::Graph::lines->new(600,500) or die "couldn't do it: $!";

$graph->set_title_font(gdGiantFont);

my $max_y = $data[$#data];
#my $max_y = 285;
$graph->set(
	box_axis	=> 0,
        x_ticks	=> 0,
        x_label_skip	=> 500,
        x_labels_vertical	=> 1,
	y_max_value => $max_y,
        transparent	=> 0,
	dclrs	=> [ qw(blue green blue cyan) ],
	bgclr	=> "white",
	title	=>	'Entries through Time',
        logo	=>	$logo,
	logo_position	=>	'UR',
        shadow_depth	=> 3
        );


my $gd = $graph->plot(\@graph_data); 
open(IMG, '>entries.png') or die "couldn't open it: $!";
binmode IMG;
print IMG $gd->png;
	
sub compile_data {

my $i;

for ($i=$start_time; $i < $end_time; $i=$i+60) {

  my $stamp = localtime($i);

  # works
  push @labels, $stamp;
  for my $j (0..$#timestamps) {
	my $k = $j+1;
	if ($timestamps[$j] > $i) {
                #print "$k";
		push @data, $k;
		last;
	}
        if ($j == $#timestamps) {
              # print "$k";
               push @data, $k;
        }
  }
}


}

sub get_timestamps_from_db {

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

  my $sql = "select entry_time from player_info where man_or_chimp = \"man\" order by entry_time";

  my $sth = $dbh->prepare ($sql);
  $sth->execute ();

  while (my $hashref = $sth->fetchrow_hashref()) {
        my $entry = $hashref->{entry_time};
        push @timestamps, $entry;
   }

  $dbh->disconnect();


}


