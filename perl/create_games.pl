#!/usr/bin/perl

use strict;

my @sql;
my $sql = "INSERT into games (game, score, region, round, upset, winner) VALUES ('GAME','SCORE','NULL','ROUND','NULL','NULL');";
for (1..32) {
	my $game = "game_" . $_;
	my $round = 1;
	my $score = 1;
	my $insert = $sql;
	$insert =~ s/GAME/$game/;
	$insert =~ s/SCORE/$score/;
	$insert =~ s/ROUND/$round/;
	print $insert . "\n";
}

for (33..48) {
	my $game = "game_" . $_;
	my $round = 2;
	my $score = 2;
	my $insert = $sql;
	$insert =~ s/GAME/$game/;
	$insert =~ s/SCORE/$score/;
	$insert =~ s/ROUND/$round/;
	print $insert . "\n";
}

for (49..56) {
	my $game = "game_" . $_;
	my $round = 3;
	my $score = 4;
	my $insert = $sql;
	$insert =~ s/GAME/$game/;
	$insert =~ s/SCORE/$score/;
	$insert =~ s/ROUND/$round/;
	print $insert . "\n";
}
for (57..60) {
	my $game = "game_" . $_;
	my $round = 4;
	my $score = 6;
	my $insert = $sql;
	$insert =~ s/GAME/$game/;
	$insert =~ s/SCORE/$score/;
	$insert =~ s/ROUND/$round/;
	print $insert . "\n";
}
for (61..62) {
	my $game = "game_" . $_;
	my $round = 5;
	my $score = 8;
	my $insert = $sql;
	$insert =~ s/GAME/$game/;
	$insert =~ s/SCORE/$score/;
	$insert =~ s/ROUND/$round/;
	print $insert . "\n";
}
	my $game = "game_" . 63;
	my $round = 5;
	my $score = 16;
	my $insert = $sql;
	$insert =~ s/GAME/$game/;
	$insert =~ s/SCORE/$score/;
	$insert =~ s/ROUND/$round/;
	print $insert . "\n";

