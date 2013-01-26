#!/usr/bin/perl
#
# emails.cgi
#

#use strict;
use CGI qw/:all/; # cgi.pm module
use DBI;
use Template;
use vars qw/$dbh/;
do "jq_globals.pl";
$| = 1;
connect_to_db();

print "Content-type: text/html\n\n";
my $config = config_variables();
my $dir = 'emails';

my %PARAMS;
# start with some defaults
$PARAMS{'year'} = '2008';
my $tm = "&#0153;";
$PARAMS{'cgi'} = 'emails';
$PARAMS{'title'} = 'JQMCBP Email Vault';
$PARAMS{'pool_size'} = get_player_pool_size('man');
$PARAMS{'high_score'} = get_high_score();
my $cookie = cookie("thisisme2");
my $thisisme; my $similarities;
my $emails = get_emails();

if ($cookie) {
	$thisisme = thisIsMe($cookie);
	$similarities = getSimilarities($cookie);
}

# take in params
for (param()) {
	$PARAMS{$_} = param("$_");
}

my $page = 'top';
my $content;
if ($PARAMS{'email'}) {
	$page = $PARAMS{'email'};
	$content = get_content($page);
}

my %data = ( 
                'params'        =>      \%PARAMS,
		'thisisme'	=>	$thisisme,
		'cookie'	=>	$cookie,
		'whichone'	=>	$page,
		'emails'	=>	$emails,
		'content'	=>	$content,
                );

my $file = "cgi_generic";
my $template = Template->new( {
                INCLUDE_PATH => "$config->{'template_dir'}",
} ) or print "couldn't do it $!";
                $template->process($file, \%data)
                || die "Template process failed: ", $template->error(), "\n";

exit;

sub get_content {
	my $email = shift;
	my $content;
	open(EMAIL,"<$dir/$email");
	while(<EMAIL>) {
		$content .= $_;
	}
	return $content;
}

sub get_emails {
	my @emails;
	opendir(DIR,"$dir");
	while(my $file = readdir(DIR)) {
		next if $file =~ /^\./;
		push @emails, $file;
	}
	closedir(DIR);
	my @sort = sort @emails;
	return \@sort;
}
