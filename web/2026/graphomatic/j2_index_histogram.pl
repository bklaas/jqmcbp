#!/usr/bin/perl 
#
# histogram.pl
#

# makes a png of the histogram of the scores

use DBI;
use GD::Graph::bars;
use GD::Graph::colour;
use File::Copy;

my $datadir = "/tmp";
my $webdir = "/data/benklaas.com/jqmcbp";
my $png_path = "$webdir/graphomatic";
my ($line, $score, $name, $candybar, $gender, $champion, $player_id);
my @names_unsorted;
my @scores;
my %ids;
my @names;
my @headers;

grab_scores();

#for $j ($lowest..$highest) {
for ($j = $lowest; $j <= $highest; $j++) {
#print "$j\n";
   unless ($score_hash{$j}) {
      $score_hash{$j} = 0;
   }
     my $label = ($j / $highest) * 100;
     push @labels, $label;
     push @values, $score_hash{$j};
     $score_dist[0][$j] = $j;
     $score_dist[1][$j] = $score_hash{$j};
     #print "$score_hash{$j}\t$j\n";
   
}

######################################
# Make histogram                     #
######################################

 my $histogram = GD::Graph::bars->new(640,200);

         #y_tick_number => $biggest,
         #y_label_skip => $biggest,
  #$histogram->set_title_font(gdMediumBoldFont) or die "couldn't do it: $!";
  $histogram->set( 
         t_margin => "2",
         b_margin => "2",
         l_margin => "2",
         r_margin => "2",
         box_axis => 0,
         dclrs => ["#c60b0b"],
         x_label_position => 0.5,
         y_min_value => 0,
         y_max_value => $biggest,
         title	=> "J2 Index Distribution",
         x_label => "J Factor",
         x_label_skip => 10,
         y_label => "Frequency",
         logo => "$webdir/graphomatic/jq_graph_logo.png",
         logo_resize => 1,
         logo_position => 'UR',
         );

my @plot_data = ( [ @labels ] , [ @values ] );
 my $gd = $histogram->plot(\@plot_data);

print STDOUT "Making histogram\n";
print STDOUT "$biggest\n";

  open(IMG1, ">$png_path/j_index_histogram.png") or die $!;
     binmode IMG1;
     print IMG1 $gd->png;

sub grab_scores {

###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "johnnyquest";
my $location = "localhost";
my $port_num = "3306";
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

my $dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
###############################################################

$biggest = 1;

#my $query = "select picks.player_id, sum(teams.seed) as total from teams, picks where teams.team = picks.winner and picks.game like \"%1_%\" group by picks.player_id order by total";
my $query = "select j2_factor from player_info where man_or_chimp = \"man\" order by j2_factor";
print "$query\n";
my $sth = $dbh->prepare($query);
    unless ($sth->execute) {
         die "Statement failed" . $sth->errstr;
    }

 while (my $hashref = $sth->fetchrow_hashref()) {
          $score = $hashref->{j2_factor};
          push @scores, $score;
}

$sth->finish;
$dbh->disconnect();


$lowest = 0;
$highest = 100;

for (@scores) {
#    $j_index = ($_ - 144)/256;
	$j_index = $_/100; 

   for my $z (1..$highest) {
       my $div = $z/$highest;
       if ($j_index <= $div) {
	   $percentile = $z;
           last;
        }
    }
 
       if ($score_hash{$percentile}) {
           $tally = $score_hash{$percentile} + 1;
           $score_hash{$percentile} = $tally;
           if ($tally > $biggest) {
              $biggest = $tally;
           }
       } else {
           $score_hash{$percentile} = 1;
       }
              
}

}
