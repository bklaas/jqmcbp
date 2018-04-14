#!/usr/bin/perl

use strict;
my $dbh;

use DBI;
do "/home/bklaas/jqmcbp/perl/jq_globals.pl";

# 2019 BEN! Change this to jq_2018
connect_to_db("jq_2017");

my $step = get_step();

my $query = "select * from player_info, scores where player_info.player_id = scores.player_id and player_info.man_or_chimp = 'man' and step = $step order by player_info.name";

my $ref = multi_row_query($query);

my $high_score_query = "select score from scores where step = \"$step\" order by score desc limit 1";
my $high_score_ref = single_row_query($high_score_query);
my $high_score = $high_score_ref->{'score'} || '0';

print "email, name, candybar, player_id, darwin, score, rank, leader\n";
for my $href (@$ref) {
	next if $href->{email} eq 'Anders.kurtis@gmail.com';

	my $shref = sanitize_quotes($href);
	#print "\"$shref->{email}\",\"$shref->{name}\",\"$shref->{candybar}\",\"$shref->{player_id}\",\"$shref->{darwin}\",\"$shref->{\n";
	for my $key ( qw/ email name candybar player_id darwin score rank/ ) {
		print $shref->{$key} . ",";
	}
	print "\"$high_score\"\n";
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
