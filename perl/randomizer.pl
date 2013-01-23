#!/usr/bin/perl

$foo{'1'} = "top";
$foo{'2'} = "bottom";
for (1..63) {
my $rand = int(rand(4)) + 1;
print "$rand\n";
#print "game $_:\t$foo{$rand}\n";
}
