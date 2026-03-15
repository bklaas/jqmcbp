#!/usr/bin/perl 

$| = 1;
use strict;
use CGI qw/:param :cookie /; # cgi.pm module
use DBI;
use Template;
use vars qw/ $dbh %PARAMS /;
do "./jq_globals.pl";
print "Content-type: text/html\n\n";

my $config = config_variables();
my $cgi = "player_bracket.cgi";
my $webdir = "/etc/httpd/htdocs";
my $javascript = "/jqmcbp/effects.js";
my $stylesheet = "/jqmcbp/jqmcbp.css";
my $heading_color = "#800080";
my $table_color = "#3B6C71";
my $cookie = cookie('thisisme2');
my $thisisme;
connect_to_db();
$PARAMS{'pool_size'} = get_player_pool_size('man');
$PARAMS{'high_score'} = get_high_score();
if ($cookie) {
	$thisisme = thisIsMe($cookie);
}
my ($names) = grab_names();
$dbh->disconnect();

my @vars;
my $tm = "&#0153;";
$PARAMS{'title'} = "Prognosticationland$tm";
$PARAMS{'cgi'} = 'player_bracket_selection';

 my %data = ( 
              'params'  =>      \%PARAMS,
	      'names'	=>	$names,
	      'cookie'	=>	$cookie,
	      'thisisme'	=>	$thisisme,
            );

 my $tmpl = "cgi_generic";
 my $template = Template->new( {
             INCLUDE_PATH => "$config->{'template_dir'}",
 } ) or print "couldn't do it $!";
 $template->process($tmpl, \%data) || die "Template process failed: ", $template->error(), "\n";

