#!/usr/bin/perl

use strict;
use HTML::TokeParser;
use LWP::Simple;

my $file = "babynames.html";
open(FILE,"<$file");
my $content;
$content .= $_ while <FILE>;
close(FILE);

my $p = HTML::TokeParser->new(\$content);

my %names;
while (my $token = $p->get_tag("td")) {
	my $text = $p->get_trimmed_text("/td");
	$names{$text}++ if $text =~ /^[A-Z][a-z]/ && $text !~ /:/;
}
for (sort keys %names) {
	print "$_\n";
}
