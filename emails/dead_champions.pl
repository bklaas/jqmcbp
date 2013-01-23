#!/usr/bin/perl

my $dbh;

use DBI;
do "/data/cgi-bin/jq_globals.pl";
connect_to_db();

my @gone;
my @goners;

open(CHAMPS,"<allgone");
while(<CHAMPS>) {
	chomp;
	next if /^$/ || /^#/;
	push @gone, $_;
}
close(CHAMPS);

for (@gone) {
	my $query = "select name, champion from player_info where champion = \"$_\" and man_or_chimp = 'man'";
	my $ref = multi_row_query($query);
	my @temp = @$ref;
	@goners = (@goners, @temp);
}

my ($this_one, $last_one);
my $inc;
for (0..$#goners) {
	$this_one = $goners[$_]{'champion'};
	if ($this_one eq $last_one) {
		print "$goners[$_]{'name'}, ";
	} else {
		print "\n\n$this_one: ";
		print "$goners[$_]{'name'}, ";
	}
	$last_one = $goners[$_]{'champion'};
	$inc++;
}
print "\n$inc\n";
