#!/usr/bin/perl
#
# sss.cgi
#

use strict;
use CGI qw/:param :cookie/; # cgi.pm module
use DBI;
use Template;
use vars qw/$dbh/;
do "jq_globals.pl";
$| = 1;

print "Content-type: text/html\n\n";
connect_to_db();
my $config = config_variables();
my %PARAMS;
my $tm = "&#0153;";
$PARAMS{'high_score'} = get_high_score();
$PARAMS{'cgi'} = 'dougletter';
$PARAMS{'title'} = "Hail Purdue";
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

my %data = ( 
                'params'        =>      \%PARAMS,
		'thisisme'	=>	$thisisme,
		'cookie'	=>	$cookie,
                );

my $file = "cgi_generic";
my $template = Template->new( {
                INCLUDE_PATH => "$config->{'template_dir'}",
} ) or print "couldn't do it $!";
                $template->process($file, \%data)
                || die "Template process failed: ", $template->error(), "\n";

exit;

