#!/usr/bin/perl

use strict;
my $dbh;

use DBI;
do "/home/bklaas/jqmcbp/perl/jq_globals.pl";
connect_to_db();

my $query = "select name, candybar from player_info group by candybar order by candybar";

my $ref = multi_row_query($query);

for my $href (@$ref) {
	my $shref = sanitize_quotes($href);
    print "[$shref->{name}] $shref->{'candybar'}\n";
}

sub sanitize_quotes {
	my $href = shift;
	my $return;
	for my $key (keys %$href) {
		my $val = $href->{$key};
		$val =~ s/"/'/g;
		$return->{$key} = $val;
	}
	return $return;
}
