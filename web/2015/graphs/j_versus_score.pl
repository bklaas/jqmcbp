#!/usr/bin/perl

use DBI;
$| = 1;

my $webdir = "/data/benklaas.com/jqmcbp/graphs/";

my $graph_name;

my $graph = "score_vs_j.png";
my $field1 = "Score";
my $field2 = "J factor";
my $title = "Score vs. J Factor comparison";

my $highest;
my $graph_name = "$webdir/$graph";
my @y_data; my @x_data;

print "making scatter plot...";

query_for_data();
make_scatter_plot($graph_name, $field1, $field2, $title);

print "done\n";

sub query_for_data {

open(FILE,"</tmp/jq_scores.txt");
#open(FILE,"</tmp/combined_scores.txt");
while(<FILE>) {
next if /Crazy Ramon/;
	chomp;
	my (@ary) = split /\t/;
	push @ary0, $ary[7];
	push @ary1, $ary[1];
}
close(FILE);
}

sub make_scatter_plot {
######################################
# Make scatter plot                  #
######################################

use Chart::Plot;

  my $graphomatic = shift;
  my $field1 = shift;
  my $field2 = shift;
  my $title = shift;

my $x_label = $field1; 
my $y_label = $field2; 

#my $plot = Chart::Plot->new(500,500);
my $plot = Chart::Plot->new(800,800);

my $gd = $plot->getGDobject;
my $occam_blue = $gd->colorAllocate(0,38,137);

for (0..$#ary0) {
	print "$ary0[$_]\t$ary1[$_]\n";
}
$plot->setData (\@ary1, \@ary0, "Points Noline Red");
$plot->setGraphOptions ('title' => $title,
                        'horAxisLabel' => "Score",
                        'vertAxisLabel' => "J Factor");


           open (WR,">$graphomatic") or die ("Failed to write file: $!");
           binmode WR;            # for DOSish platforms
           print WR $plot->draw();
           close WR;

  chmod 0777, $graphomatic;

}


