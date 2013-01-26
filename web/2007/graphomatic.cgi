#!/usr/bin/perl -w
#
# graphomatic.cgi
#

use strict;
$| = 1;

print "Content-type: text/html\n\n";
use CGI qw/:param :cookie/; # cgi.pm module
use Template;
use vars qw/ $dbh  %PARAMS %data /;
use DBI;
do "jq_globals.pl";

my $config = config_variables();
my $data_dir = "/tmp";
my $webdir = "/data/benklaas.com/jqmcbp/";
my $graphdir = "graphomatic";
my ($line, $score, $name, $candybar, $gender, $champion, $player_id);
my (@names_unsorted, %ids, @names);

connect_to_db();

$PARAMS{'high_score'} = get_high_score();
my $cookie = cookie('thisisme2');
my $thisisme;
my $similarities;
if ($cookie) {
	$thisisme = thisIsMe($cookie);
	$similarities = getSimilarities($cookie);
}
my $step = get_step();
my $names = grab_names();
## pull in passed parameters

my @vars;

my $first_player = param("first_player");
my $second_player = param("second_player");
my $submit = param("submit.x") || 0;


my $tm = "&#0153;";
$PARAMS{'pool_size'} = get_player_pool_size('man');
$PARAMS{'title'} = "Graphomatic$tm";
my $tmpl = "cgi_generic";

if ($submit > 0) {

my $first_player_score = get_scores($first_player);
my $second_player_score = get_scores($second_player);
my $first_player_name = get_player_name($first_player);
my $second_player_name = get_player_name($second_player);
my $similarity = get_similarity($first_player, $second_player);
my @fp_strings = split(//, $first_player_score);
my @sp_strings = split(//, $second_player_score);
my $graphs = make_them_graphs();

sub get_similarity {
	my ($first_player, $second_player) = @_;
	my $q = "select similarity from similarity_index where first_player_id = \"$first_player\" and second_player_id = \"$second_player\"";
	my $ref = single_row_query($q);
	return $ref->{'similarity'};
}
$PARAMS{'cgi'} = 'graphomatic';

%data = ( 
		'params'  =>      \%PARAMS,
	      	'names'	=>	$names,
		'first_player_strings'	=>	\@fp_strings,
		'second_player_strings'	=>	\@sp_strings,
		'similarity'	=>	$similarity,
		'first_player'	=>	$first_player_name,
		'second_player'	=>	$second_player_name,
		'graphs'	=>	$graphs,
		'cookie'	=>	$cookie,
		'thisisme'	=>	$thisisme,
		'similarities'	=>	$similarities,
            );
} else {

$PARAMS{'cgi'} = 'graphomatic_selection';
%data = ( 
              'params'  =>      \%PARAMS,
	      	'names'	=>	$names,
		'cookie'	=>	$cookie,
		'thisisme'	=>	$thisisme,
		);
}

my $template = Template->new( {
            INCLUDE_PATH => "$config->{'template_dir'}",
																 } ) or print "couldn't do it $!";
$template->process($tmpl, \%data) || die "Template process failed: ", $template->error(), "\n";
$dbh->disconnect();

exit;


sub make_them_graphs {
my @graph_names;
# execute graphomatic.pl
 
my $prog_string = "perl $webdir/$graphdir/graph-o-matic.pl $first_player $second_player";
my @prog_strings = (
			"/usr/bin/perl $webdir/$graphdir/step-o-matic.pl $first_player $second_player",
			"/usr/bin/perl $webdir/$graphdir/graph-o-matic.pl $first_player $second_player",
			);

for my $prog_string (@prog_strings) {
	my $pid = open(README, "$prog_string |") or die "can't run program: $!\n";
	while(<README>) {
		chomp;
		push @graph_names, $_;
	}
	close(README);  
}
return \@graph_names;
}

sub get_scores {
	my $id = shift;
	my $score;
	my $query = "select score from scores where player_id = \"$id\" and step = \"$step\"";
	my $ref = single_row_query($query);
	return $ref->{'score'};
}

sub get_player_name {
	my $id = shift;
	my $query = "select name from player_info where player_id = $id";
	my $ref = single_row_query($query);
	return $ref->{'name'};
}
