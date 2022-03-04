#!/usr/bin/perl

use strict;
use CGI qw/:param/;
print "Content-type: text/html\n\n";

my %PARAMS;
for (param()) {
	$PARAMS{$_} = param($_);
}

my $prog = "/data/benklaas.com/jqmcbp/graphomatic/step-o-matic.pl filter $PARAMS{'filter'} 1> /dev/null";
system($prog);

my $graph_name = "/jqmcbp/graphomatic/step_graph_filter_" . $PARAMS{'filter'} . "_" . $PARAMS{'statistic'} . ".png";

print "<html><head><title>Step-O-Matic Graph: $PARAMS{'statistic'}</title></head><body>\n";
print "<img src = '$graph_name'>\n";
print "</body></html>\n";


