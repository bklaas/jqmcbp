#!/usr/bin/perl 

use strict; 

use GD::Graph::linespoints;
use GD;
use DBI;


use vars qw/ $dbh /;
do "/data/benklaas.com/jqmcbp/jq_globals.pl";

connect_to_db();

my $some_player = 28329;

my $webdir = "/data/benklaas.com/jqmcbp";
my $png_path = "$webdir/graphomatic";
my $logo_path ="../images/jq_graph_logo.png";
#my $font_path = "/usr/share/fonts/truetype/ttf-bitstream-vera";
my $font_path = "/usr/share/fonts/truetype/ttf-dejavu";
my $graphdir = "$webdir/graphomatic";
my @data;
my @size;
my @ids;
my $graphname_stub;
if ($ARGV[0] eq 'filter') {
	my $filter = $ARGV[1];
	my $ids = get_filter_ids($filter);
	for (keys %$ids) {
		push @ids, $_;
	}
	@size = (900, 500);
	$graphname_stub = "step_graph_filter_" . $filter . "_";
} else {
	@ids = @ARGV;
	#@size = (640, 340);
	@size = (900, 500);
	my $string = join('vs', @ids);
	$graphname_stub = $string . "_step_graph_";
}

my @scores;
my ($name_href, $name_aref) = grab_these_names(\@ids);
my %names = %$name_href;
my @names = @$name_aref;
my $steps = get_steps();
my @steps = @$steps;

my $data = grab_score_data(\@ids);
$dbh->disconnect();

for my $statistic ('score', 'darwin', 'rank', 'rtt') {
my $max_y;
my @sorted_data;
for my $player_aref (@$data) {
	my @ary;
	for my $href (@$player_aref) {
		push @ary, $href->{$statistic};
		$max_y = $href->{$statistic} if $href->{$statistic} > $max_y;
	}
	@sorted_data = (@sorted_data, [ @ary ]);
}

my @data_sorted = ( [ @steps ] , @sorted_data );

# shorten those long ass names
my @shortened_names;
for my $name (@names) {
	push @shortened_names, substr($name, 0, 25);
}

my $graph = GD::Graph::linespoints->new(@size);

$graph->set_title_font("$font_path/DejaVuSans-Bold.ttf", 14) or die "couldn't do it: $!";
       $graph->set_x_label_font("$font_path/DejaVuSans-Bold.ttf", 10) or die "$!";
       $graph->set_y_label_font("$font_path/DejaVuSans-Bold.ttf", 10) or die "$!";
       $graph->set_x_axis_font("$font_path/DejaVuSans.ttf", 8) or die "$!";
       $graph->set_y_axis_font("$font_path/DejaVuSans-Bold.ttf", 8) or die "$!";
       $graph->set_values_font("$font_path/DejaVuSans.ttf", 8) or die "$!";

#  $graph->set_title_font(gdMediumBoldFont) or die "couldn't do it: $!";
  $graph->set_legend(@names);
$graph->set_legend_font("$font_path/DejaVuSans.ttf", 6) or die "couldn't do it: $!";
#  my $values = $graph->copy;
  
  $graph->set( 
         t_margin => "2",
         b_margin => "2",
         l_margin => "2",
         r_margin => "2",
         box_axis => 0,
         x_label_position => 0.5,
	 y_max_value => $max_y,
         y_min_value => 0,
         title	=> "JQMCBP Progress Comparison: $statistic",
         x_label => "Step",
         y_label => "$statistic",
         logo => "$logo_path",
         logo_resize => 1,
         logo_position => 'UR',
	 legend_placement => 'RC'
         );

my $gd = $graph->plot(\@data_sorted);
#open(IMG, ">$png_path/bentest_$statistic.png") or die $!;
my $graphMe = "$png_path/$graphname_stub$statistic.png\n";
#open(IMG, ">$png_path/$graphname_stub$statistic.png") or die $!;
open(IMG, ">$graphMe") or die $!;
print "$graphname_stub$statistic.png\n";
     binmode IMG;
     print IMG $gd->png;
chmod(0777,"$graphMe");
}


sub grab_score_data {
	my $ids = shift;
	my @id_sorted = sort { $a <=> $b } @$ids;
        my @return;
	for my $id (@id_sorted) {
		my $query = "select * from player_info, scores where player_info.player_id = scores.player_id AND player_info.player_id = $id order by scores.step";
        	my $ref = multi_row_query($query);
		push @return, $ref;
	}
	# each element of the array return is a player's LoH, sorted by step
        return \@return;
}

sub grab_these_names {
	my $ids = shift;
	my $or_frag; 
	for my $id (@$ids) {
		$or_frag .= " player_id = $id OR";
	}
	$or_frag =~ s/OR$//;
       	my $name_sql = "select name, player_id from player_info where $or_frag order by player_id";
	my $ref = multi_row_query($name_sql);
	my %return;
	my @return;
	for my $href (@$ref) {
		my $id = $href->{'player_id'};
		$return{$id} = $href->{'name'};      
		push @return, $href->{'name'};
        }
	return \%return, \@return;
}

sub get_steps {

	my $query = "select step from scores where player_id = $some_player order by step";
	my $ref = multi_row_query($query);
	my @return;
	for (@$ref) {
		push @return, $_->{'step'};
	}
	return \@return;
}
