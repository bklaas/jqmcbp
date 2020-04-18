#!/usr/bin/perl

use DBI;             # perl DBI module
use DBD::mysql;      # perl module for mySQL interface
use strict;

use vars qw/$dbh/;
do "/home/bklaas/jqmcbp/web/2020/jq_globals.pl";

connect_to_db('johnnyquest');
my $player_info = get_emails();

my %done;
for my $email ( @$player_info ) {
    print "$email->{email}\n" unless $done{$email->{email}};
	$done{$email->{email}}++;
}

sub get_emails {
	my $query = "select * from player_info order by email";
	my $return = multi_row_query($query);
	return $return;
}

