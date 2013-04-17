#!/usr/bin/perl

use strict;
my $dbh;

use DBI;
do "/home/bklaas/jqmcbp/perl/jq_globals.pl";
connect_to_db();

my $step = get_step();

my $query = "select * from player_info, scores where player_info.player_id = scores.player_id and player_info.man_or_chimp = 'man' and step = $step order by player_info.name";

my $ref = multi_row_query($query);

my $high_score_query = "select score from scores where step = \"$step\" order by score desc limit 1";
my $high_score_ref = single_row_query($high_score_query);
my $high_score = $high_score_ref->{'score'} || '0';

for my $href (@$ref) {
	next if $href->{email} eq 'Anders.kurtis@gmail.com';

	my $shref = sanitize_quotes($href);
	#print "\"$shref->{email}\",\"$shref->{name}\",\"$shref->{candybar}\",\"$shref->{player_id}\",\"$shref->{darwin}\",\"$shref->{\n";
	for my $key ( qw/ email name candybar player_id darwin score rank/ ) {
		print $shref->{$key} . ",";
	}
	print "\"$high_score\"\n";
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
