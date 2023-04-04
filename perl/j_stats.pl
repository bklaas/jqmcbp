#!/usr/bin/perl

use strict;
use DBI;

use Data::Dump qw/dump/;

use vars qw/ $dbh /;
do "/data/cgi-bin/jq_globals.pl";

my $years = [qw/ 2004 2005 2006 2007 2008 2009 2012 2013 2014 2015 2016 2017 2018 2019 2021 2022 johnnyquest/];

print "year\tperfect_j\n";
for my $year (@$years) {
    my $db;
    if ($year eq "johnnyquest") {
        $db = $year;
    } else {
        $db = "jq_" . $year;
    }
    my $first = first_round($db);
    my $third = third_round($db);
    my $perfect_j = calculate_j($first, $third);
    my $median_j = median_j("man");
    my $median_chimp_j = median_j("chimp");
    if ($year eq "johnnyquest") {
        my $this_year = this_year();
        print "$this_year\t$perfect_j\t$median_j\t$median_chimp_j\n";
    } else {
        print "$year\t$perfect_j\n";
    }
}

sub median_j {
    my $man_or_chimp = shift;
    # XXX
}
sub calculate_j {
    my $sigma1 = shift;
    my $sigma2 = shift;

	my $j = (($sigma1 - 144) / 256);
	my $j2 = 20 * ( $j + ( 4 * (($sigma2 - 12)/112)) );
    return $j2;

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
