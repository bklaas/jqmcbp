#!/usr/bin/perl

$| = 1;  # make sure output is unbuffered

use strict;
use Template;
print "Content-type: text/html\n\n";
use CGI qw/ :param /;
use DBI;
use vars qw/ $dbh /;
do "/data/cgi-bin/jq_globals.pl";
my $PARAMS; 
my $CONFIG = config_variables();

for (param()) {
	$PARAMS->{$_} = param("$_");
}

if (    $PARAMS->{'keywords'} eq 'enter' ||
        $PARAMS->{'keywords'} eq 'enter2' ||
        $PARAMS->{'keywords'} eq 'brackettest'
	) {
        connect_to_db('johnnyquest');
        my @brackets = get_bracket_order();
        my $teamRef = get_teams(@brackets);
        my @unsorted = map { $_->{'team'} } @$teamRef ;
        my @teams = sort @unsorted;
        $PARAMS->{'teams'} = \@teams;
}

# change this to overview at launch
$PARAMS->{'keywords'} = 'overview' unless $PARAMS->{'keywords'};

my $tmpl = "index";

unless (-e "$CONFIG->{'template_dir'}/$PARAMS->{'keywords'}") {
	$PARAMS->{'keywords'} = 'filenotfound';
}

my %data = (
	'params'	=>	$PARAMS,
	'title'		=> 	$CONFIG->{'year'},
	'year'		=>  $CONFIG->{'year'},
);

my $template = Template->new({
	INCLUDE_PATH	=> "$CONFIG->{'template_dir'}"
}) or die "$!";

$template->process($tmpl, \%data)
        || print "Template process failed: ", $template->error(), "\n";

