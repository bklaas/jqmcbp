#!/usr/bin/perl
#
use strict;

my $file = shift @ARGV;

    my $out = $file;
    $out =~ s/\.txt/.html/;

open(IN, "<$file") or die $!;
#open(OUT, ">$out") or die $!;

my $headings = 0;
while(<IN>) {
    my $line = $_;
    chomp($line);
    if ($line =~ /===/) {
        $line = "</table>\n\n<table>\n";
        $headings = 1;
    }
    elsif ($headings) {
        $line =~ s/\t/<\/th><th>/g;
        $line =~ s/<th>$//g;
        $line = "<tr><th>" . $line . "</th></tr>\n";
        $headings = 0;
    }
    else {
        $line =~ s/\t/<\/td><td>/g;
        $line =~ s/<td>$//g;
        $line = "<tr><td>" . $line . "</td></tr>\n";
    }
    print STDOUT $line;
}
print STDOUT "</table>\n";
close(IN);
#close(OUT);
