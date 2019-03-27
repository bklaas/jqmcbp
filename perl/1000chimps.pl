#!/usr/bin/perl

use strict;

# connect to database
use DBI;
use vars qw/$dbh/;
do "/data/benklaas.com/jqmcbp/jq_globals.pl";

connect_to_db();

#my $name_file = "2000names.txt";
my $name_file = "the1000Chimps2017.txt";
my $bracket_picker = "random_bracket_selector.pl";
my $names = get_names();

# get all of the team names into an ordered array
my @brackets = get_bracket_order();
my $teams = get_teams(@brackets);

#my $query = "select team from teams order by team_id";
#my $ref = multi_row_query($query);
my @teams;
$teams[0] = "TEAMS ARRAY";

for (@$teams) {
	push @teams, $_->{'team'};
}

my $inc = 1;
for my $chimp (keys %$names) {
	my $name = $chimp;
	$name =~ s/ the Chimp//;
	last if $inc == 1001;
	my $outfile = "chimp_data/$name.dat";
	my %losers;
	open(OUT,">$outfile");
	for my $game (1..63) {
		my ($sub, $mult);
		if ($game <= 32) {
			$sub = 1; $mult = 2; 
		} elsif ($game <= 48) {
			$sub = 33; $mult = 4;
		} elsif ($game <= 56) {
			$sub = 49; $mult = 8;
		} elsif ($game <= 60) {
			$sub = 57; $mult = 16;
		} elsif ($game <= 62) {
			$sub = 61; $mult = 32;
		} else {
			$sub = 63; $mult = 64;
		}
		my $game_name = "game_" . $game;
		my $start = ($game - $sub)*$mult + 1;
		my $end = $start + ($mult - 1);
		my $rand = random();
		my ($team1, $team2) = whos_playing($start, $end, \%losers);
		my $which = pick_it($rand, $team1, $team2, \%losers);
		print OUT "$game_name|$teams[$which]\n";
	}
	print OUT "name|$chimp\n";
	print OUT "location|Rancho Cucamonga\n";
	print OUT "candybar|Banana Moon Pie\n";
	print OUT "alma_mater|Bonobo U\n";
	close(OUT);
	$inc++;
}

sub whos_playing {

	my $start = shift;
	my $end = shift;
	my $losers = shift;
	my @return;
	for ($start..$end) {
		push @return, $_ unless $losers->{$_};
	}
	return @return;
}

sub random {
	my $rand = int(rand(2));
	return $rand;
}

sub pick_it {
	my ($rand, $team1, $team2, $losers) = @_;
	if ($rand == 0) {
		$losers->{$team2}++;
		return $team1 if $rand == 0;
	} elsif ($rand == 1) {
		$losers->{$team1}++;
		return $team2 if $rand == 1;
	}
}

sub get_names {
	my %names;
	open(NAMES,"<$name_file");
	while(<NAMES>) {
		chomp;
		$names{$_}++;
	}
	close(NAMES);
	return \%names;
}
