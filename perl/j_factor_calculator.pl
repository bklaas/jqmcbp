#!/usr/bin/perl

use strict;
use DBI;

use vars qw/ $dbh /;
do "/data/cgi-bin/jq_globals.pl";
connect_to_db();

# grab player_id from PLAYER_INFO table
my $player_id_sql = "SELECT name, player_id, date_created, j2_factor from player_info where j2_factor order by player_id";
my $ref = multi_row_query($player_id_sql);

my $inc;
for my $href (@$ref) {
	my $player_id = $href->{'player_id'};
	# calculate j and j2 factors
	my $frag = make_frag("1","32");
	my $query = "select sum(teams.seed) as total, picks.name from teams, picks where teams.team = picks.winner and picks.player_id = \"$player_id\" and ( $frag ) group by picks.player_id order by total";
	my $frag2 = make_frag("49","56");
	my $query2 = "select sum(teams.seed) as total, picks.name from teams, picks where teams.team = picks.winner and picks.player_id = \"$player_id\" and ( $frag2 ) group by picks.player_id order by total";
	my $ref1 = single_row_query($query);
	my $sigma1 = $ref1->{'total'};
	$ref1 = single_row_query($query2);
	my $sigma2 = $ref1->{'total'};
	my $j = (($sigma1 - 144) / 256);
	my $j_factor = 100 * $j;
	my $j2 = ( $j + ( 4 * (($sigma2 -12)/112)) );
	my $j2_factor = 20 * $j2;
    if ($j_factor == 100) {
        $j_factor = 99.99;
    }
    if ($j2_factor == 100) {
        $j2_factor = 99.99;
    }

	print "DB: $href->{j2_factor}|CALC: $j2_factor\n";

    print "DB: $href->{j2_factor}|CALC: $j2_factor\n";
    my $update = "UPDATE player_info set date_created = \"$href->{date_created}\", j_factor = \"$j_factor\", j2_factor = \"$j2_factor\" where player_id = \"$player_id\"";
    print "$href->{name}|$update\n";
    $dbh->do($update) or die "$DBI::ERRSTR";
    $inc++;
}
print "$inc\n";
$dbh->disconnect();


sub make_frag {
	# sub to deal with new naming scheme for games
	my $first = shift;
	my $last = shift;
        my $frag;
        for ($first..$last) {
                $frag .= " picks.game = \"game_$_\" ";
                $frag .= "OR " unless $_ == $last;
        }
        return $frag;
}
