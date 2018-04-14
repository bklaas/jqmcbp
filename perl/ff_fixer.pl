#!/usr/bin/perl

use strict;
use DBI;
use vars qw/ $dbh /;
do "/data/cgi-bin/jq_globals.pl";

my $dirpath = "/tmp/jq_fix";

connect_to_db();

opendir(DIR,"$dirpath");

my %done;
open(DONE,"</home/bklaas/jqmcbp/perl/fix_done");
while(<DONE>) {
	chomp;
	$done{$_}++;
}
close(DONE);

# iterate through data files
open(DONE,">>/home/bklaas/jqmcbp/perl/fix_done");

while (defined(my $datfile = readdir(DIR))) {

	next unless $datfile =~ /\.dat$/;
	next if $done{$datfile};

	print "fixing final four for $datfile\n";
	my ($name, $value);

	my $info;
	open (DATAFILE,"<$dirpath/$datfile");
        while (<DATAFILE>) {
			chomp;
			my $line = $_;
			# escape quote characters
			$line =~ s/\"/\'/g;
			$line =~ s/\'/\\\'/g;
			($name, $value) = split /\|/, $line;
			$info->{$name} = $value;
		}
		close(DATAFILE);
		$info->{'game_63'} = $info->{ $info->{'champ_pointer'} };

		for my $col ( 'game_57', 'game_58', 'game_59', 'game_60', 'game_61', 'game_62', 'game_63' ) {
			my $update = "UPDATE picks set winner = \"$info->{$col}\" where game = \"$col\" and player_id = \"$info->{player_id}\"";
			print "$update\n";
			$dbh->do($update);
        }
		my $champ = "UPDATE player_info set champion = \"$info->{'game_63'}\", how_found = \"fix_complete\" where player_id = \"$info->{player_id}\"";
		print "$champ\n";
		$dbh->do($champ);
		
	close (DATAFILE);
	print DONE "$datfile\n";

}
close(DONE);
