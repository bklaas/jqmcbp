#!/usr/bin/perl

use strict;
use CGI qw/:all/; # cgi.pm module
use DBI;
use JSON;
use vars qw/$dbh/;
do "jq_globals.pl";
$| = 1;

connect_to_db();
my $config = config_variables();

my $ref;
# $ref = get_people_scores();
$ref = tally_locations();

my $json = JSON->new->allow_nonref;

my $json_text   = $json->encode( $ref );
my $pretty_printed = $json->pretty->encode( $ref ); # pretty-printing

print $pretty_printed . "\n";
exit;

sub get_people_scores {

        # find out what the last 'step' was
        my $query = 'select step from scores order by step desc limit 1';
        my $ref = single_row_query($query);
        my $step = $ref->{'step'};

        # grab all scores sorted by $PARAMS{'sort'}
        my $where_frag = "player_info.player_id = scores.player_id and scores.step = \"$step\" and  player_info.man_or_chimp = 'man'";
        $query = "select * from scores, player_info where $where_frag order by scores.score , player_info.man_or_chimp desc, player_info.player_id";
	$ref = multi_row_query($query);
	return $ref;
}

sub tally_locations {
	my $query = "select count(*) as count, location from player_info where man_or_chimp = 'man' group by location order by count";
	my $ref = multi_row_query($query);
	return $ref;
}
