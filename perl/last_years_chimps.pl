#!/usr/bin/perl
#
use strict;
use DBI;
use vars qw/ $dbh /;
do "/data/benklaas.com/jqmcbp/jq_globals.pl";

connect_to_db("jq_2006");

my $query = "select name from player_info where man_or_chimp = 'chimp' order by name";
my $aref = multi_row_query($query);
for my $href (@$aref) {
	print "$href->{'name'}\n";
}
