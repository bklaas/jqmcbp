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

$PARAMS->{'keywords'} = 'top' unless $PARAMS->{'keywords'};
$CONFIG->{'template_dir'} = '/data/benklaas.com/jqmcbp/templates';
my $tmpl = "index";

if (	$PARAMS->{'keywords'} eq 'enter' || 
	$PARAMS->{'keywords'} eq 'brackettest') {
	connect_to_db('johnnyquest');
	my @brackets = get_bracket_order();
	my $teamRef = get_teams(@brackets);
	my @unsorted = map { $_->{'team'} } @$teamRef ;
	my @teams = sort @unsorted;
	$PARAMS->{'teams'} = \@teams;
} elsif ( $PARAMS->{'keywords'} eq 'howmany' ) {
	my $howmany = "cat /tmp/jq_entries/*.dat | grep -c locale";
	my $thismany = 'foo';
	open(CMD, "$howmany |");
	while (<CMD>) {
		chomp;
		$thismany = $_;
	}
	close(CMD);
	# remedy 2009 fuckup
	$thismany = $thismany - 76;
	my @thismany = split(//, $thismany);
	$PARAMS->{'howmany'} = \@thismany;
}

my %data = (
		'params'	=>	$PARAMS,
		'title'		=> 	'2009',
		);

my $template = Template->new({
		INCLUDE_PATH	=> "$CONFIG->{'template_dir'}"
			}) or die "$!";
$template->process($tmpl, \%data)
        || print "Template process failed: ", $template->error(), "\n";

