#!/usr/bin/perl

$| = 1;

use strict;
use CGI qw/:param :cookie /; # cgi.pm module
use Statistics::Descriptive;
use DBI;
use Template;
use vars qw/ $dbh %PARAMS /;
do "jq_globals.pl";

print "Content-type: text/html\n\n";
my $config = config_variables();
my $cgi = "whatsyourj.cgi";
my @names; my $j_factor; my @j_factors; my $div; my %data;

connect_to_db();

my @min =  (0, 1, 2, 5, 10, 20, 50);
my @max =  (1, 2, 5, 10, 20, 50, 100);
my @div_labels = ( '0-1', '1-2', '2-5', '5-10', '10-20', '20-50', '50-100' );
my ($human_data, $chimp_data) = get_histogram_data(\@min, \@max);

my $playerId = param("player_id");

 %data = (
		'human_data'   => $human_data,
		'frequency_bins' => \@div_labels,
		'chimp_data'   => $chimp_data,
             );

my $tmpl = "highcharts/j_factor_distribution.tmpl";
my $template = Template->new() or print "couldn't do it $!";
$template->process($tmpl, \%data) || die "Template process failed: ", $template->error(), "\n";

sub query_for_count {
	my $min = shift;
	my $max = shift;
	my $man_or_chimp = shift;
	my $query = "select count(*) as count from player_info where man_or_chimp = \"$man_or_chimp\" and (j2_factor > $min and j2_factor <= $max)";
	my $href = single_row_query($query);
	if ($href->{count}) {
		return $href->{count};
	} else {
		return 0;
	}
}

sub get_histogram_data {
	my $min = shift;
	my $max = shift;

	my ($humans, $chimps);
	my $size = @$min - 1;
	for my $elem (0..$size) {
		my $count = query_for_count(@$min[$elem], @$max[$elem], 'man');
		push @$humans, $count;
	}
	for my $elem (0..$size) {
		my $count = query_for_count(@$min[$elem], @$max[$elem], 'chimp');
		push @$chimps, $count;
	}
	return $humans, $chimps;
}

sub get_div {
	my $j_factor = shift;
	my $divs = shift;
	my $j_factors = shift;
	my $div;
	my $i = 0;
	for (@$divs) {
		if ($j_factor <= $j_factors->[$_]) {
			$div = $i;
			$div++;
			last;
		}
		$i++;
	}
	return $div;
}
