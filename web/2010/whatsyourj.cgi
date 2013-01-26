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

$PARAMS{'high_score'} = get_high_score();
my $cookie = cookie('thisisme2');
my $thisisme;
if ($cookie) {
	$thisisme = thisIsMe($cookie);
}
my ($divs, $j_factors) = calculate_divisions();
my $stat = Statistics::Descriptive::Full->new();
$stat->add_data(@$j_factors);
my $min = $stat->min();
my $max = $stat->max();
my $median = $stat->median();
my $median_abbr = sprintf("%.2f", $median);
my $names = grab_names();
my $tm = "&#0153;";
my $playerId = param("player_id");
$PARAMS{'title'} = "The J Factor$tm";

if ($playerId) {
   my $info = get_player_info($playerId);
   my $div = get_div($info->{'j2_factor'}, $divs, $j_factors);
   my $j_abbr = sprintf("%.2f", $info->{'j2_factor'});
   my @strings = split //, $j_abbr;

 $PARAMS{'cgi'} = 'jfactor';
 %data = (
	     'params'		=>      \%PARAMS,
	     'strings'		=>	\@strings,
	     'player_info'	=>	$info,
	     'thisDiv'		=>	$div,
	     'j_factor'		=>	$j_abbr,
	     'median_abbr'	=>	$median_abbr,
	     'cookie'		=>	$cookie,
	     'thisisme'		=>	$thisisme,
             );
} else {

 $PARAMS{'cgi'} = 'whatsyourj';
 %data = (
       'params'  =>      \%PARAMS,
       'names'   =>      $names,
	     'cookie'		=>	$cookie,
	     'thisisme'		=>	$thisisme,
             );
}

my $tmpl = "cgi_generic";
my $template = Template->new( {
               INCLUDE_PATH => "$config->{'template_dir'}",
    } ) or print "couldn't do it $!";
$template->process($tmpl, \%data) || die "Template process failed: ", $template->error(), "\n";

sub calculate_divisions {
	my $query = "select j2_factor from player_info where man_or_chimp = \"man\" order by j2_factor";
	my $aref = multi_row_query($query);
	my (@divs, @j_factors);
	for my $href (@$aref) {
		push @j_factors, $href->{'j2_factor'};
	}
	my $total = $#j_factors;
	for my $division ("0.2", "0.4","0.6","0.8","1.0") {
		my $div = int($total*$division);
		push @divs, $div;
	}
	return \@divs, \@j_factors;
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
