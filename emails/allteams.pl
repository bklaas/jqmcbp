#!/usr/bin/perl

my $dbh;

use DBI;
do "/data/benklaas.com/jqmcbp/jq_globals.pl";
connect_to_db();

my $query = "select team from teams";
my $ref = multi_row_query($query);

for (@$ref) {
	print "#" . $_->{'team'} . "\n";
}
