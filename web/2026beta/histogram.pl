#!/usr/bin/perl 
#
# histogram.pl
#
# makes a png of the histogram of the scores

use strict;
use GD::Graph::bars;
use GD::Graph::colour;
use File::Copy;

my $lowest = 0;
my $highest;
my $interval;
my $x_skip;
my $datadir = "/tmp";
my $x_max;
# $x_max is highest of all scores
open(COMBINED, "$datadir/combined_scores.txt");
while(<COMBINED>) {
	my (@data) = split /\t/;
	$highest = $data[1];
	last;
}
close(COMBINED);

my $webdir = "/data/benklaas.com";
my $png_path = "$webdir/jqmcbp/graphomatic";

for my $man_or_chimp ('man', 'chimp') {

my @score_dist;
my $y_max;
my @names_unsorted;
my @scores;
my %ids;
my @names;
my @headers;
my ($tally, $biggest, $scores, $scorehash) = grab_scores($man_or_chimp);
my %score_hash = %$scorehash;
my @scores = @$scores;

	$score_dist[0][0] = 0;
       $score_dist[1][0] = 0;
#open (LOG, ">/tmp/hist.log");
my $inc = 0;
for my $j ($lowest..$highest) {
   unless ($score_hash{$j}) {
      $score_hash{$j} = 0;
   }
	$score_dist[0][$inc] = $j;
	$score_dist[1][$inc] = $score_hash{$j};
	$inc++;
   
}
#close(LOG);
######################################
# Make histogram                     #
######################################

 my $histogram = GD::Graph::bars->new(640,200);

# these params are set by man and inherited by chimp
	$y_max = $biggest;
	while ($y_max%6) {
		$y_max++;
	}
	$interval = $biggest / 6;

my $dclrs;
my $logo;
my $title;
my $bgclr = 'white';
if ($man_or_chimp eq 'man') {
	$dclrs = '#c60b0b';
	$logo = '/data/benklaas.com/jqmcbp/graphs/jq_graph_logo.gif';
	if ($highest > 70) {
		$x_skip = 10;
	} elsif ($highest > 30) {
		$x_skip = 5;
	} else {
		$x_skip = 0;
	}
        $title	= "JQMCBP PEOPLE Score Distribution";
} else {
	$dclrs = 'gold';
	$logo = '/data/benklaas.com/johnnyquest/images/lucky.gif';
        $title	= "JQMCBP CHIMP Score Distribution";
	$bgclr = 'black';
}
  #$histogram->set_title_font(gdMediumBoldFont) or die "couldn't do it: $!";
  #my $ttfFont = "/usr/share/fonts/ttf-bitstream-vera/VeraBd.ttf";
#  my $ttfFont = "/usr/share/fonts/truetype/ttf-bitstream-vera/VeraBd.ttf";
my $ttfFont = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf";

  $histogram->set_title_font($ttfFont, 10) or die "couldn't do it: $!";
       $histogram->set_x_label_font($ttfFont, 8);
       $histogram->set_y_label_font($ttfFont, 8);
       $histogram->set_y_axis_font($ttfFont, 8);
       $histogram->set_x_axis_font($ttfFont, 8);
       #$histogram->set_values_font(font specification)

  $histogram->set( 
         t_margin => "2",
         b_margin => "2",
         l_margin => "2",
         r_margin => "2",
         box_axis => 0,
         dclrs => ["$dclrs"],
         fgclr => "$dclrs",
	labelclr => "black",
	axislabelclr => "black", 
	legendclr => "black", 
	valuesclr => "black", 
	textclr => "black",
	transparent => 1,
         x_label_position => 0.5,
         y_min_value => 0,
         y_max_value => $y_max,
         y_tick_number => 6,
         title	=> "$title",
         x_label => "Score",
	 x_min_value => 0,
	 x_max_value => $x_max,
         x_label_skip => $x_skip,
         y_label => "Frequency",
         logo => "$logo",
         logo_resize => 1,
         logo_position => 'UR',
         );

#print "$webdir/jqmcbp/images/jq_graph_logo.png\n";
 my $gd = $histogram->plot(\@score_dist);

print STDOUT "Making histogram for $man_or_chimp\t$x_max\n";

my $graph_name;
$graph_name = "histogram.png" if $man_or_chimp eq "man";
$graph_name = "chimp_histogram.png" if $man_or_chimp eq "chimp";
  open(IMG1, ">$png_path/$graph_name") or die $!;
     binmode IMG1;
     print IMG1 $gd->png;
close(IMG1);
chmod 0777, "$png_path/$graph_name";

use File::Copy;
copy("$png_path/$graph_name", "$webdir/johnnyquest/images/$graph_name");
}

sub grab_scores {

	my $man_or_chimp = shift;
	my $score_hash;
	my $tally;
	my @return;
	my $biggest = 1;
	my $data_file;
	if ($man_or_chimp eq "man") {
		$data_file = "jq_scores.txt";
	} else {
		$data_file = "chimp_scores.txt";
	}
    open (SORTED,"<$datadir/$data_file") or die "$datadir/$data_file";

    while (<SORTED>) {

       my $line = $_;
        my ($place, $score, @garbage) = split /\t/, $line;

       push @return, $score;

       if ($score_hash->{$score}) {
           $tally = $score_hash->{$score} + 1;
           $score_hash->{$score} = $tally;
           if ($tally > $biggest) {
              $biggest = $tally;
           }
       } else {
           $score_hash->{$score} = 1;
       }

              
     }
$biggest++;
close(SORTED);

return ($tally, $biggest, \@return, $score_hash);
}
