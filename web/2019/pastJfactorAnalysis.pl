#!/usr/bin/perl

$| = 1;

use strict;
use Statistics::Descriptive;
use DBI;
use vars qw/ $dbh %PARAMS /;
do "./jq_globals.pl";

my $config = config_variables();
my @names; my $j_factor; my @j_factors; my $div; my %data;

my @databases = ( 'johnnyquest', 'jq_2007', 'jq_2006', 'jq_2005', 'jq_2004', 'jq_2003' );

for my $db (@databases) {

	connect_to_db($db);

	my $j_factors = get_j_factors($db);
	my $winningJ = get_winning_j_factors($db);
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(@$j_factors);
	my $min = $stat->min();
	my $max = $stat->max();
	my $median = $stat->median();
	my $median_abbr = sprintf("%.2f", $median);
	my $winningJ_abbr = sprintf("%.2f", $winningJ);
	print "$db\tmedian: $median_abbr\twinner j factor: $winningJ_abbr\n";
	$dbh->disconnect();
}

sub get_winning_j_factors {
	my $db = shift;
	my $query = "select sum(teams.seed) as sigma from games, teams where games.winner = teams.team and games.round = ";
	my $return;
	my @sigma;
	for my $round (1, 3) {
		my $href = single_row_query($query . $round);
		push @sigma, $href->{'sigma'};
	}
	$return = 20 * (($sigma[0] - 144)/256) + (4 * ( $sigma[1] - 12 ) / 112 );
	return $return;
}

sub get_j_factors {
	my $db = shift;
	my $query;
	if ($db =~ /200[345]/) {
		$query = "select j2_factor from player_info order by j2_factor";
	} else {
		$query = "select j2_factor from player_info where man_or_chimp = \"man\" order by j2_factor";
	}
	my $aref = multi_row_query($query);
	my @j_factors;
	for my $href (@$aref) {
		push @j_factors, $href->{'j2_factor'};
	}
	return \@j_factors;
}

