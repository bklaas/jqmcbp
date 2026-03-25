#!/usr/bin/perl
#
# ucow.cgi
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
$PARAMS{'cgi'} = 'ucow';
$PARAMS{'title'} = "JQMCBP Unweighted Chance Of Winning&trade;";
$PARAMS{'pool_size'} = get_player_pool_size('man');

my $cookie = cookie("thisisme2");
my $thisisme; my $similarities;
if ($cookie) {
	$thisisme = thisIsMe($cookie);
}

# take in params
for (param()) {
	$PARAMS{$_} = param("$_");
}

# Query UCOW data for each stage
my $ucow_four = get_ucow_data('four');
my $ucow_eight = get_ucow_data('eight');
my $ucow_sixteen = get_ucow_data('sixteen');

my %data = ( 
        'params'        =>      \%PARAMS,
		'thisisme'	=>	$thisisme,
		'cookie'	=>	$cookie,
		'ucow_four'	=>	$ucow_four,
		'ucow_eight'	=>	$ucow_eight,
		'ucow_sixteen'	=>	$ucow_sixteen,
                );

sub get_ucow_data {
	my $stage = shift;
	my $brackets_col = "ucow_${stage}_brackets";
	my $percent_col = "ucow_${stage}_percent";

	# Check if any non-null data exists for this stage
	my $check = single_row_query("SELECT COUNT(*) as cnt FROM ucow WHERE $brackets_col IS NOT NULL");
	return undef unless $check->{cnt} > 0;

	       my $query = "SELECT ucow.player_id, player_info.name, player_info.man_or_chimp, player_info.past_champion, "
		       . "$brackets_col AS brackets, $percent_col AS percent "
		       . "FROM ucow JOIN player_info ON ucow.player_id = player_info.player_id "
		       . "WHERE $brackets_col > 0 "
		       . "ORDER BY $brackets_col DESC";

	return multi_row_query($query);
}

my $file = "cgi_generic";
my $template = Template->new( {
                INCLUDE_PATH => "$config->{'template_dir'}",
} ) or print "couldn't do it $!";
                $template->process($file, \%data)
                || die "Template process failed: ", $template->error(), "\n";

exit;
