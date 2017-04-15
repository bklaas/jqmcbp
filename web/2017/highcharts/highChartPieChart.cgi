#!/usr/bin/perl -w

use strict; 

use DBI;
use Data::Dump;
use Template;
use JSON;

print "Content-type: text/html\n\n";
use CGI qw/ :param /;
my $PARAMS;
for (param()) {
        $PARAMS->{$_} = param("$_");
}

if ($ARGV[0]) {
	$PARAMS->{game} = $ARGV[0];
}
if ($ARGV[1]) {
	$PARAMS->{man_or_chimp} = $ARGV[1];
}
$PARAMS->{man_or_chimp} = 'man' unless $PARAMS->{man_or_chimp};

die "Must enter game number" unless $PARAMS->{game};
die "Game number must be between 1 and 63" if $PARAMS->{game} < 1 || $PARAMS->{game} > 63;

use vars qw/ $dbh /;
do "/data/cgi-bin/jq_globals.pl";
connect_to_db();

my $png_path = "/data/benklaas.com/jqmcbp/highcharts";
#my $logo_path = $png_path . "/jq_graph_logo.gif";

my $game = "game_" . $PARAMS->{game};

#next if $fields[$PARAMS->{game}] eq 'game_59' && $man_or_chimp eq 'chimp';
my $data = grab_game_data($game, $PARAMS->{man_or_chimp});
my $round; 

#                        data: [
#                                ['Firefox',   45.0],
#                                ['IE',       26.8],
#                                ['Chrome',   12.8],
#			]

$round = "Championship" if $PARAMS->{game} == 63;
$round = "Final Four" if $PARAMS->{game} <= 62;
$round = "Regional Finals" if $PARAMS->{game} <= 60;
$round = "Sweet Sixteen" if $PARAMS->{game} <= 56;
$round = "Second Round" if $PARAMS->{game} <= 48;
$round = "First Round" if $PARAMS->{game} <= 32;

my $title = $round;
if ($PARAMS->{man_or_chimp} eq 'chimp') {
	$title .= ' as picked by chimps';
}

#Data::Dump::dump($data);
# to send to the template:
# title
# game data
# ??
# TBD: do something awesome for the winning team, like pulling the slice out of the pie or something


my $CONFIG;
#$CONFIG->{'template_dir'} = '/data/benklaas.com/content';
my $tmpl = "pie.tmpl";

my $template_data = {
	title => $title,
	series => $data,
	params => $PARAMS,
};

my $template = Template->new({
                #INCLUDE_PATH    => "$CONFIG->{'template_dir'}"
                        }) or die "$!";
$template->process($tmpl, $template_data)
        || print "Template process failed: ", $template->error(), "\n";

my $disc = $dbh->disconnect;

sub grab_game_data {
	my $game = shift;
	my $man_or_chimp = shift;
	my @data;

#	my $game_sql = "select count(*) as count, picks.winner from picks, player_info where picks.player_id = player_info.player_id and player_info.man_or_chimp = \"$man_or_chimp\" and picks.game = \"$game\" group by picks.winner order by count desc";
	my $game_sql = "select count(*) as count, picks.winner, teams.seed from picks, player_info, teams where picks.winner = teams.team and picks.player_id = player_info.player_id and player_info.man_or_chimp = \"$man_or_chimp\" and picks.game = \"$game\" group by picks.winner order by count desc";

#	print "$game_sql\n";
	my $ref = multi_row_query($game_sql);

	my $i = 0;
	for my $hashref (@$ref) {
		my $winner = $hashref->{'winner'};
		my $seed = $hashref->{'seed'};
	#	$winner = substr($winner, 0, 10);
		my $count = $hashref->{'count'};
		$data[$i][0] = $winner . ' (' . $seed . ')';
		$data[$i][1] = $count;
		$i++;
	 }

	return \@data;

}
