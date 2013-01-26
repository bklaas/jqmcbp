#!/usr/bin/perl

$| = 1;  # make sure output is unbuffered

use strict;
use Template;
print "Content-type: text/html\n\n";
use CGI qw/ :param /;
use DBI;
use vars qw/ $dbh /;
do "/data/cgi-bin/jq_globals.pl";
my $PARAMS; my $CONFIG;

for (param()) {
	$PARAMS->{$_} = param("$_");
}

# change this to overview at launch
$PARAMS->{'keywords'} = 'lehighandnorfolk' unless $PARAMS->{'keywords'};

$CONFIG->{'template_dir'} = '/data/benklaas.com/jqmcbp/templates';
my $tmpl = "temp";

my %data = (
	'params'	=>	$PARAMS,
	'title'		=> 	'2012',
);

my $template = Template->new({
	INCLUDE_PATH	=> "$CONFIG->{'template_dir'}"
}) or die "$!";

$template->process($tmpl, \%data)
        || print "Template process failed: ", $template->error(), "\n";

