#!/usr/bin/perl

use strict;
my $dbh;

use DBI;
do "/home/bklaas/jqmcbp/perl/jq_globals.pl";
connect_to_db();

my $step = get_step();

my $query = "select * from player_info where how_found = 'bracket_fix' order by player_info.name";

my $ref = multi_row_query($query);

print "email, name, candybar, player_id, darwin, score, rank, leader\n";
for my $href (@$ref) {
	my $shref = sanitize_quotes($href);
	#print "\"$shref->{email}\",\"$shref->{name}\",\"$shref->{candybar}\",\"$shref->{player_id}\",\"$shref->{darwin}\",\"$shref->{\n";
	for my $key ( qw/ email name /) {
		print $shref->{$key} . ",";
	}
	print "\"x\",";
	
		print $shref->{player_id} . ",";
	for my $key ( qw/darwin score rank/ ) {
		print "\"x\",";
	}
	print "\"x\"\n";
}

# XXX only for 2016
#print join(",", '"jgmikulay@gmail.com"', '"Jenny Gator"', '"Did not enter one"', '"0"', '"1000"', '"0"', '"757"', '"757"');
#print "\n";

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
