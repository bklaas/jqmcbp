#!/usr/bin/perl -w

use strict; 

use GD::Graph::pie;
use GD;
use DBI;

use vars qw/ $dbh /;
do "/data/cgi-bin/jq_globals.pl";

connect_to_db();
my $png_path = "/data/benklaas.com/jqmcbp/graphs";
my $logo_path = $png_path . "/jq_graph_logo.gif";
my $font_path = "/usr/share/fonts/ttf-bitstream-vera";

my $start = $ARGV[0] || 1; 
my $end = $ARGV[1] || 63;
my $start_angle = $ARGV[2] || 0;

my @fields;
#for (1..63) {
for ($start..$end) {
	my $game = "game_" . $_;
	push @fields, $game;
}

for my $man_or_chimp ('chimp') {
#for my $man_or_chimp ('man') {
#for my $man_or_chimp ('chimp', 'man') {

my $i = 0;
for my $ary_val ($start..$end) {
	#next if $fields[$ary_val] eq 'game_59' && $man_or_chimp eq 'chimp';
	my $data = grab_game_data($fields[$i], $man_or_chimp);
	my $round; my $suppress_angle = 3; 
	$round = "Championship" if $ary_val == 63;
	$round = "Final Four" if $ary_val <= 62;
	$round = "Regional Finals" if $ary_val <= 60;
	$round = "Sweet Sixteen" if $ary_val <= 56;
	$round = "Second Round" if $ary_val <= 48;
	$round = "First Round" if $ary_val <= 32;
	$suppress_angle = 0 if $round eq "First Round";
	$suppress_angle = 5 if $round eq "Regional Finals" || $round eq "Sweet Sixteen" || $round eq "Championship";
	print "$round|$ary_val|$suppress_angle|$start_angle|\n";
	my $graph = GD::Graph::pie->new(650, 650);
	$graph->set_title_font("$font_path/VeraBd.ttf", 14) or die "couldn't do it: $!";

	my $title = $round;
	if ($man_or_chimp eq 'chimp') {
		$title .= ' as picked by chimps';
	}
	print "$title\n";
	  $graph->set( 
       	  title	=> $title,
       	  logo => "$logo_path",
       	  logo_position => 'UR',
       	  suppress_angle => $suppress_angle,
	  start_angle => $start_angle,
         );

	$graph->set_value_font("$font_path/VeraBd.ttf", 12)  or die "couldn't set font: $!";
	my $gd = $graph->plot($data);
	print STDOUT "Making graph for game $fields[$i]\n";

	my $file_name = $fields[$i];
	if ($man_or_chimp eq 'chimp') {
		$file_name = 'chimp_' . $file_name;
	}
	  open(IMG, ">$png_path/$file_name.png") or die $!;
	     binmode IMG;
	     print IMG $gd->png;

	open (HTML,">$png_path/$file_name.html") or die $!;
	print HTML "<html><body><img src=\"$file_name.png\"></body></html>\n";
	close (HTML);
	$i++
}

}

my $disc = $dbh->disconnect ();

sub grab_game_data {
########################################################################
#################### pull in count for a game info #####################
########################################################################
my $game = shift;
my $man_or_chimp = shift;
my @data;

my $game_sql = "select count(*) as count, picks.winner from picks, player_info where picks.player_id = player_info.player_id and player_info.man_or_chimp = \"$man_or_chimp\" and picks.game = \"$game\" group by picks.winner order by count desc";

print "$game_sql\n";
my $ref = multi_row_query($game_sql);

my $i = 0;
for my $hashref (@$ref) {
	my $winner = $hashref->{'winner'};
#	$winner = substr($winner, 0, 10);
	my $count = $hashref->{'count'};
        $data[0][$i] = $winner . " (" . $hashref->{'count'} . ")";
        $data[1][$i] = $count;
        $i++;
 }

return \@data;

}
