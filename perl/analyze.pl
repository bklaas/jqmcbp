#!/usr/bin/perl
#
use strict;

my @ids;
open(IN, "<errors2.txt");
while(<IN>) {
    my @line = split/[\t|\s+]/;
    push @ids, { player_id => $line[1], j2_factor => $line[5] };
}
close(IN);

@ids = sort(@ids);
for my $i (@ids) {
    print "UPDATE player_info set j2_factor = \"$i->{j2_factor}\" where player_id = \"$i->{player_id}\";\n";
}
