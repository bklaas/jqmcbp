#!/usr/bin/perl

use strict;

my $file = $ARGV[0];

open(IN, "<$file") or die "$!";
while (<IN>) {
	s/^/<tr><td>/;
	s/\t/<\/td><td>/g;
	s/<td>$/<\/tr>/;
	print;
}
close(IN);


