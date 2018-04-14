#!/usr/bin/perl

my $dbh;

use DBI;
do "/data/cgi-bin/jq_globals.pl";
connect_to_db();

my $what = shift;
my $query = "select $what from player_info where man_or_chimp = 'man' order by $what";
my $ref = multi_row_query($query);
for (@$ref) {
	print $_->{$what} . "\n";
}
