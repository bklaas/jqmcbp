#!/usr/bin/perl

use strict;
use DBI;

use Data::Dump qw/dump/;

use vars qw/ $dbh /;
do "/data/cgi-bin/jq_globals.pl";

my $bracket_j_factors = {};

my $years = [qw/ 2004 2005 2006 2007 2008 2009 2012 2013 2014 2015 2016 2017 2018 2019 2020/];
#for my $year (2012..2019) {
for my $year (@$years) {
    my $db = "jq_" . $year;
    my $first = first_round($db);
    my $third = third_round($db);
    my $j = calculate_j($first, $third);
    print "$db\t$j\n";
}

sub calculate_j {
    my $sigma1 = shift;
    my $sigma2 = shift;

	my $j = (($sigma1 - 144) / 256);
	my $j_factor = 100 * $j;
	my $j2 = ( $j + ( 4 * (($sigma2 - 12)/112)) );
	my $j2_factor = 20 * $j2;
    if ($j2_factor == 100) {
        $j2_factor = 99.99;
    }
    return $j2_factor;


}
sub first_round {
    my $db = shift;
    return _round($db, 1, 32);
}

sub third_round {
    my $db = shift;
    return _round($db, 49, 56);
}


sub _round {
    my $db = shift;
    my $start = shift;
    my $end = shift;

    connect_to_db($db);
    # get the seeds of all the teams
    my $teams_sql = "select team, seed from teams";
    my $ref = multi_row_query($teams_sql);

    my $team_seeds;
    for my $href( @$ref ) {
        $team_seeds->{$href->{"team"}} = $href->{'seed'};    
    }

    my $winners_sql = "select winner from games where";
    my $frag = make_frag($start, $end);

    $ref = multi_row_query($winners_sql . $frag);
    my $first_round = 0;
    for my $href ( @$ref ) {
        $first_round += $team_seeds->{$href->{'winner'}};
    }
    return $first_round;
}

sub make_frag {
	# sub to deal with new naming scheme for games
	my $first = shift;
	my $last = shift;
        my $frag;
        for ($first..$last) {
                $frag .= " game = \"game_$_\" ";
                $frag .= "OR " unless $_ == $last;
        }
        return $frag;
}
