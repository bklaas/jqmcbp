#!/usr/bin/perl

use GD;
use GD::Graph::lines;
use strict;

###############################################################
# VARIABLES TO CHANGE
my $years_of_interest = ['2019', '2018', '2017', '2016'];
#
# HEY BEN! values in this hash are day of month, and are 1-based.
# Add a key/value pair for the new JQMCBP year
my $start_times = {
    '2005' => 13, '2006' => 12, '2007' => 11, '2008' => 16,
    '2009' => 15, '2012' => 11, '2013' => 17, '2014' => 16,
    '2015' => 15, '2016' => 13, '2017' => 12, '2018' => 11,
    '2019' => 17 };
my $current_year = '2019';
###############################################################
# EVERYTHING BELOW THIS SHOULD "JUST WORK"
###############################################################

use DBI;
use Time::Local;

use vars qw/ $dbh /;
do "/data/benklaas.com/jqmcbp/jq_globals.pl";
my $graph;
my $logo = "/data/benklaas.com/jqmcbp/graphs/jq_graph_logo.gif";
my $font_path = "/usr/share/fonts/truetype/ubuntu";

my %data;
my @legend;
my $labels;
my ($start_time, $end_time, $db);
my $graph_data = [];

for my $year (@$years_of_interest) {
    $start_time = timelocal(00,00,17,$start_times->{$year},2,$year);
    $db = 'jq_' . $year;
    # CHANGE THIS AS NEEDED
    if ($year eq $current_year) {
        $db = 'johnnyquest';
		my $now = time;
		$end_time = $now - $start_time > 327600 ? $start_time + 327600 : $now;
	} else {
		$end_time = $start_time + 327600;
	}
	my $stamps = get_timestamps_from_db($db);
	( my $data, $labels) = compile_data($stamps);
	$data{$year} = $data;
    push @$graph_data, [ @$data ];
	push @legend, $year;
}
unshift @$graph_data, [ @$labels ];

$graph = GD::Graph::lines->new(800,800) or die "couldn't do it: $!";
$graph->set_title_font("$font_path/Ubuntu-B.ttf", 14) or die "couldn't do it: $!";
$graph->set_legend(@legend);

#my $max_y = $data[$#data];
my $max_y = 900;
$graph->set(
	box_axis	=> 0,
        x_tick_number	=> 4,
        x_labels_vertical	=> 1,
	y_max_value => $max_y,
	x_max_value => 90,
	y_tick_number => 18,
	y_min_value =>	0,
	long_ticks => 1,
        transparent	=> 0,
	dclrs	=> [ qw(blue green red black purple cyan) ],
	bgclr	=> "white",
	title	=>	"Rate of Entries",
        logo	=>	$logo,
	logo_position	=>	'LR',
	legend_placement	=> 'RC',
	line_width => 2,
        shadow_depth	=> 3,
	y_label	=>	'Number of Entries',
	x_label	=>	"Hours from JQMCBP Announcement",
        );


my $gd = $graph->plot($graph_data); 
open(IMG, ">/data/benklaas.com/jqmcbp/graphs/entries_yeartoyear.png") or die "couldn't open it: $!";
binmode IMG;
print IMG $gd->png;
	
sub compile_data {
	my $stamps = shift;
	my @timestamps = @$stamps;
	my $i;
	my @data; my @labels;
	my $stamp = 0;
	for ($i=$start_time; $i < $end_time; $i=$i+60) {
		#  my $stamp = localtime($i);
		# works
		push @labels, int($stamp/3600);
		for my $j (0..$#timestamps) {
			my $k = $j+1;
			if ($timestamps[$j] > $i) {
				push @data, $k;
				last;
			}
			if ($j == $#timestamps) {
				push @data, $k;
			}
		}
		$stamp += 60;
	}
	return \@data, \@labels;
}

sub get_timestamps_from_db {
	my @timestamps;
	my $db = shift || 'johnnyquest';
	connect_to_db($db);

	my $sql = "select entry_time from player_info where man_or_chimp = \"man\" order by entry_time";
	if ($db eq 'jq_2005') {
		$sql = "select entry_time from player_info order by entry_time";
	}
	my $aref = multi_row_query($sql);
	for my $href (@$aref) {
		push @timestamps, $href->{'entry_time'};
	}
	$dbh->disconnect();
	return \@timestamps;
}


