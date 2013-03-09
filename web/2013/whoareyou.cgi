#!/usr/bin/perl

$| = 1;  # make sure output is unbuffered
use strict;
use CGI qw/ :param :header :cookie/;
use DBI;
use vars qw/ $dbh /;
do "jq_globals.pl";
use Template;
my $CONFIG;
my %cookiePrefs;
$CONFIG->{'template_dir'} = 'templates';

my %PARAMS;
for (param()) {
	$PARAMS{$_} = param($_);
}
my $cookieValue = param('thisisme');
connect_to_db();
my $names = grab_names();
$dbh->disconnect();

if (param('submitMe')) {
	my $packed_cookie =  cookie(
				-NAME => 'thisisme2',
				-VALUE => "$cookieValue",
				-EXPIRES	=>	'+10M',
				);
	print header(-COOKIE =>	$packed_cookie);
	$PARAMS{'cookie'} = 'set';
} else {
	print "Content-type: text/html\n\n";
	$cookieValue = cookie('thisisme2');
}
my $tmpl = "thisisme";
my %data = (
		'params'	=>	\%PARAMS,
		'cookieValue'	=>	$cookieValue,
		'names'		=>	$names,
	);

my $template = Template->new({
		INCLUDE_PATH	=> "$CONFIG->{'template_dir'}"
			}) or die "$!";
$template->process($tmpl, \%data)
        || print "Template process failed: ", $template->error(), "\n";

