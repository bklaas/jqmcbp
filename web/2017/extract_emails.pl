#!/usr/bin/perl 

use DBI;   # perl DBI module

use vars qw/$dbh/;
do "jq_globals.pl";

connect_to_db();

my $query = "select email from player_info where email like \"%@%\" AND man_or_chimp = 'man' group by email order by email";

my $ref = multi_row_query($query);
my @array = @$ref;

for (@array) {
	my %hash = %$_;
	print "$hash{'email'}" . "\n";
}
