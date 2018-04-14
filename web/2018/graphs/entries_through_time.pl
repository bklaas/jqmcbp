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
#for my $year ('2015', '2014', '2013', '2012', '2009', '2008', '2007', '2006', '2005') {
#for my $year ('2018', '2017', '2016', '2015', '2014', '2013', '2012' ) {
#for my $year ('2018', '2017', '2016', '2015', '2014', '2013' ) {
for my $year ('2018', '2017') {
	if ($year eq '2005') {
		$start_time = timelocal(00,00,17,13,2,$year);
		$db = 'jq_2005';
	} elsif ($year eq '2006') {
		$start_time = timelocal(00,00,17,12,2,$year);
		$db = 'jq_2006';
	} elsif ($year eq '2007') {
		$start_time = timelocal(00,00,17,11,2,$year);
		$db = 'jq_2007';
	} elsif ($year eq '2008') {
		$start_time = timelocal(00,00,17,16,2,$year);
		$db = 'jq_2008';
	} elsif ($year eq '2009') {
		$start_time = timelocal(00,00,17,15,2,$year);
		$db = 'jq_2009';
	} elsif ($year eq '2012') {
		$start_time = timelocal(00,00,17,11,2,$year);
		$db = 'jq_2012';
	} elsif ($year eq '2013') {
		$start_time = timelocal(00,00,17,17,2,$year);
		$db = 'jq_2013';
	} elsif ($year eq '2014') {
		$start_time = timelocal(00,00,17,16,2,$year);
		$db = 'jq_2014';
	} elsif ($year eq '2015') {
		$start_time = timelocal(00,00,17,15,2,$year);
		$db = 'jq_2015';
	} elsif ($year eq '2016') {
		$start_time = timelocal(00,00,17,13,2,$year);
		$db = 'jq_2016';
	} elsif ($year eq '2017') {
		$start_time = timelocal(00,00,17,12,2,$year);
		$db = 'jq_2017';
	}
	if ($year eq '2018') {
		my $now = time;
		$start_time = timelocal(00,00,17,11,2,$year);
		$db = 'johnnyquest';
		$end_time = $now - $start_time > 327600 ? $start_time + 327600 : $now;
	} else {
		$end_time = $start_time + 327600;
	}

	my $stamps = get_timestamps_from_db($db);
	( my $data, $labels) = compile_data($stamps);
	$data{$year} = $data;
	push @legend, $year;
}

my $aref11 = $data{'2018'};
my $aref10 = $data{'2017'};
my $aref9 = $data{'2016'};
my $aref8 = $data{'2015'};
my $aref7 = $data{'2014'};
my $aref6 = $data{'2012'};

my $aref  = $data{'2013'};
my $aref1 = $data{'2009'};
my $aref2 = $data{'2008'};
my $aref3 = $data{'2007'};
my $aref4 = $data{'2006'};
my $aref5 = $data{'2005'};

#my @graph_data = ( [ @$labels ] , [ @$aref8 ], [ @$aref7 ], [ @$aref ], [ @$aref6 ], [ @$aref1 ] , [ @$aref2 ], [ @$aref3 ], [ @$aref4 ], [ @$aref5 ] );
#my @graph_data = ( [ @$labels ] , [ @$aref11 ], [ @$aref10 ], [ @$aref9 ], [ @$aref8 ], [ @$aref7 ], [ @$aref ], [ @$aref6 ], );
#my @graph_data = ( [ @$labels ] , [ @$aref11 ], [ @$aref10 ], [ @$aref9 ], [ @$aref8 ], [ @$aref7 ], [ @$aref ], );
my @graph_data = ( [ @$labels ] , [ @$aref11 ], [ @$aref10 ],);

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
	print "$db\t$sql\n";
	my $aref = multi_row_query($sql);
	for my $href (@$aref) {
		push @timestamps, $href->{'entry_time'};
	}
	$dbh->disconnect();
	return \@timestamps;
}


