#!/usr/bin/perl

use strict;
my $dbh;

use DBI;
#do "/home/bklaas/jqmcbp/perl/jq_globals.pl";
do "/home/bklaas/jqmcbp/web/jq_globals.pl";
connect_to_db();

my $query = "select * from player_info where player_info.man_or_chimp = 'man' order by player_info.name";
my $ref = multi_row_query($query);

print "email, name, candybar, player_id\n";
for my $href (@$ref) {
	my $shref = sanitize_quotes($href);
	for my $key ( qw/ email name candybar player_id / ) {
		print $shref->{$key} . ",";
	}
    print "\n";
}

sub sanitize_quotes {
	my $href = shift;
	my $return;
	for my $key (keys %$href) {
		my $val = $href->{$key};
		$val =~ s/"/'/g;
		$val = '"' . $val . '"';
		$return->{$key} = $val;
	}
	return $return;
}
