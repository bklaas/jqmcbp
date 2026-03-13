#!/usr/bin/perl
#
# sss.cgi
#

use strict;
use CGI qw/:param :cookie/; # cgi.pm module
use DBI;
use Template;
use vars qw/$dbh/;
do "./jq_globals.pl";
$| = 1;

print "Content-type: text/html\n\n";
connect_to_db();
my $config = config_variables();
my %PARAMS;
my $tm = "&#0153;";
$PARAMS{'high_score'} = get_high_score();
$PARAMS{'cgi'} = 'sss';
$PARAMS{'title'} = "JQMCBP Scientific Similarity Score$tm";
$PARAMS{'pool_size'} = get_player_pool_size('man');

my $cookie = cookie("thisisme2");
my $thisisme; my $similarities;
if ($cookie) {
	$thisisme = thisIsMe($cookie);
	$similarities = getSimilarities($cookie);
	$PARAMS{'Leaderboard Top 25'} = sssTables('scores.score desc');
	$PARAMS{'Leaderboard Bottom 25'} = sssTables('scores.score');
	$PARAMS{'Most Similar Brackets to You'} = sssTables('similarity_index.score desc');
	$PARAMS{'Least Similar Brackets to You'} = sssTables('similarity_index.score');

}

# take in params
for (param()) {
	$PARAMS{$_} = param("$_");
}

my %data = ( 
                'params'        =>      \%PARAMS,
		'thisisme'	=>	$thisisme,
		'cookie'	=>	$cookie,
		'similarities'	=>	$similarities,
                );

my $file = "cgi_generic";
my $template = Template->new( {
                INCLUDE_PATH => "$config->{'template_dir'}",
} ) or print "couldn't do it $!";
                $template->process($file, \%data)
                || die "Template process failed: ", $template->error(), "\n";

exit;

sub sssTables {
	my $order = shift;
	my $q = "select * from similarity_index, scores, player_info where similarity_index.second_player_id = player_info.player_id and similarity_index.second_player_id = scores.player_id and similarity_index.first_player_id = \"$cookie\" order by scores.step desc, $order limit 25";
	my $ref = multi_row_query($q);
	return $ref;
}

