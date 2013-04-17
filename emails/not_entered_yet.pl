#!/usr/bin/perl

use strict;
my %orig;
my %entered;

open(OLD, "<2012emails.txt");
while(<OLD>) {
	chomp;
	$orig{$_}++;
}
close(OLD);

open(ENTERED, "<2013emails.txt");
while(<ENTERED>) {
	chomp;
	$entered{$_}++;
}
close(ENTERED);

my %not_entered_yet;

my $i  = 1;
for my $key (sort keys %orig) {
	unless ($entered{$key}) {
	print $key . "\n" ;
	$i++;
	}
}

