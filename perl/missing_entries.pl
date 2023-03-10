#!/usr/bin/perl 
use strict;
use DBI;   # perl DBI module
 
use File::Copy;

use vars qw/ $dbh /;
do "./jq_globals.pl";
connect_to_db();

my $email_sql = "select email from player_info where man_or_chimp = 'man'";

my $sth = $dbh->prepare($email_sql);
$sth->execute;

my $in_db;
while (my $hashref = $sth->fetchrow_hashref()) {
    my $email = $hashref->{email};
    $in_db->{$email}++;
}

open(DAT, "/tmp/raw_emails.txt");
while(<DAT>) {
    chomp;
    my ($trash, $email) = split /\|/;
    my ($file, $foo) = split /:/, $trash;
    if (!defined $in_db->{$email}) {
        print $file . "\n";
        copy("/data/jq_entries/$file", "/tmp/missing_entries/$file");
    }
}
close(DAT);
