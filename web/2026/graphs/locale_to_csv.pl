#!/usr/bin/perl

use strict;
use Data::Dump qw(dump);
my $year = '2014';
my %tallies;
my @category_data;
my @tally_data;
my @graph_data;
my $graph;

get_tallies_from_db();

for (sort {$tallies{$b} <=> $tallies{$a} } keys %tallies) {
     push @category_data, '"' . $_ . '"';
     push @tally_data, $tallies{$_};
#	print "{ label: \"$_\", value: $tallies{$_} },\n";
	print "$_\t$tallies{$_}\n";
}

#print join(', ', @category_data);
#print "\n";

#print join(', ', @tally_data);
#print "\n";

#@graph_data = ( [ @category_data ] , [ @tally_data ] );
#print dump(@graph_data);

sub get_tallies_from_db {

use DBI;
###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "johnnyquest";
my $location = "localhost";
my $port_num = "3306";

# this would need to be slightly altered for other databases
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

my $dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
###############################################################

  my $sql = "select location from player_info where man_or_chimp = \"man\"";

  my $sth = $dbh->prepare ($sql);
  $sth->execute ();

  while (my $hashref = $sth->fetchrow_hashref()) {
        my $locale = $hashref->{location};
        $tallies{$locale}++;
   }

  $dbh->disconnect();


}

