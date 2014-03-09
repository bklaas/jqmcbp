#!/usr/bin/perl

use GD;
use GD::Graph::lines;
use strict;

use DBI;
use vars qw/ $dbh /;
do "/data/benklaas.com/jqmcbp/jq_globals.pl";
my $graph;
my $logo = "/data/benklaas.com/jqmcbp/graphs/jq_graph_logo.gif";
#my $font_path = "/usr/share/fonts/truetype/ttf-bitstream-vera";
#my $font_path = "/usr/share/fonts/truetype/ttf-liberation";
my $font_path = "/usr/share/fonts/truetype/ubuntu-font-family";


use Time::Local;
my %data;
my @legend;
my $labels;
my ($start_time, $end_time, $db);
for my $year ('2013', '2012', '2009', '2008', '2007', '2006', '2005') {
	if ($year eq '2005') {
		$start_time = timelocal(00,00,17,13,2,2005);
		$db = 'jq_2005';
	} elsif ($year eq '2006') {
		$start_time = timelocal(00,00,17,12,2,2006);
		$db = 'jq_2006';
	} elsif ($year eq '2007') {
		$start_time = timelocal(00,00,17,11,2,2007);
		$db = 'jq_2007';
	} elsif ($year eq '2008') {
		$start_time = timelocal(00,00,17,16,2,2008);
		$db = 'jq_2008';
	} elsif ($year eq '2009') {
		$start_time = timelocal(00,00,17,15,2,2009);
		$db = 'jq_2009';
	} elsif ($year eq '2012') {
		$start_time = timelocal(00,00,17,11,2,2012);
		$db = 'jq_2012';
	} elsif ($year eq '2013') {
		$start_time = timelocal(00,00,17,17,2,2013);
		$db = 'johnnyquest';
	}

	if ($year eq '2013') {
		my $now = time;
		$end_time = $now - $start_time > 327600 ? $start_time + 327600 : $now;
		print "|$end_time|\n";
	} else {
		$end_time = $start_time + 327600;
	}
my $stamps = get_timestamps_from_db($db);
( my $data, $labels) = compile_data($stamps);
$data{$year} = $data;
push @legend, $year;
}

my $aref = $data{'2013'};
my $aref6 = $data{'2012'};
my $aref1 = $data{'2009'};
my $aref2 = $data{'2008'};
my $aref3 = $data{'2007'};
my $aref4 = $data{'2006'};
my $aref5 = $data{'2005'};
my @graph_data = ( [ @$labels ] , [ @$aref ], [ @$aref6 ], [ @$aref1 ] , [ @$aref2 ], [ @$aref3 ], [ @$aref4 ], [ @$aref5 ] );

#$graph = GD::Graph::lines->new(600,500) or die "couldn't do it: $!";
$graph = GD::Graph::lines->new(800,800) or die "couldn't do it: $!";
$graph->set_title_font("$font_path/Ubuntu-B.ttf", 14) or die "couldn't do it: $!";
$graph->set_legend(@legend);

#my $max_y = $data[$#data];
my $max_y = 750;
$graph->set(
	box_axis	=> 0,
        x_tick_number	=> 4,
        x_labels_vertical	=> 1,
	y_max_value => $max_y,
	x_max_value => 90,
	y_tick_number => 15,
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


my $gd = $graph->plot(\@graph_data); 
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
	print "$sql\n";
	my $aref = multi_row_query($sql);
	for my $href (@$aref) {
		push @timestamps, $href->{'entry_time'};
	}
	$dbh->disconnect();
	return \@timestamps;
}


