#!/usr/bin/perl 
#
# jq_entry.cgi
#
# this cgi is to serve up the html for the various rounds
# of selection in the johnnyquest pool
#
# complete rewrite of past jqmcbp bracket cgis

use strict;
$| = 1;  # make sure output is unbuffered

use CGI qw/:param :header :image_button/; # cgi.pm module

use DBI;   # perl DBI module
use vars qw/$dbh/;
do "./jq_globals.pl";

my $config = config_variables();

my %PARAMS;
for (param()) {
	$PARAMS{$_} = param($_);
	$PARAMS{$_} =~ s/"/'/g;
	if (/^[A-Z]/) {
		$PARAMS{$_} = 1;
	}
}
if ($PARAMS{"name"}) {
	submit_picks();
        print header( -Refresh=>"0;URL=/jqmcbp/credits.html" );
	print "<html><body></body></html>\n";
	exit;
} else {
	print "Content-type: text/html\n\n";
}

$PARAMS{'year'} = $config->{'year'};

if (!$PARAMS{'name'} ) {
	print "<html><body><b>Somehow you got here without entering a name.<p>Make sure javascript is turned on in your browser, hit back, and submit again</b></body></html>\n";
	exit;
}

sub submit_picks {
        my $stamp = time;
        my $file = $stamp . "." . "fixme.dat";
        my $dir = "/data/fixme";
        mkdir $dir, 0777 unless -d $dir;
        open(DATA,">$dir/$file") or warn "couldn't open $file: $!";
                for (sort keys %PARAMS) {
                        next if /^[A-Z]/;
			my $key = $_;
			$key =~ s/^radio_//;
                        print DATA "$key|$PARAMS{$_}\n";
                }
        close(DATA);
}

