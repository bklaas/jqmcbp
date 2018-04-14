#!/usr/bin/perl

use strict;

while (<>) {
	s/^/<tr><td>/;
	s/\t/<\/td><td>/g;
	s/<td>$/<\/tr>/;
	print;
}
