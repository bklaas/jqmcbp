#!/usr/bin/perl

my $dbh;

use DBI;
do "/data/cgi-bin/jq_globals.pl";
connect_to_db();

my $query = "select name, candybar from player_info group by candybar order by candybar";
my $ref = multi_row_query($query);

for (@$ref) {
	print $_->{'candybar'} . "\t" . $_->{'name'} . "\n";
}
