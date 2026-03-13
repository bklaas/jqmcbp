#!/usr/bin/perl
#
use strict;

my $files = [ "/tmp/top10_man.txt", "/tmp/top10_chimp.txt"];

for my $file (@$files) {
    my $out = $file;
    $out =~ s/\.txt/.html/;
    $out =~ s/\/tmp\///;

    open(IN, "<$file") or die $!;
    open(OUT, ">$out") or die $!;

    while(<IN>) {
        my $line = $_;
        print STDOUT $line;
        chomp($line);
        $line =~ s/\t/<\/td><td>/g;
        $line =~ s/<td>$//g;
        $line = "<tr><td>" . $line . "</tr>\n";
        print OUT $line;
    }
    close(IN);
    close(OUT);
}
