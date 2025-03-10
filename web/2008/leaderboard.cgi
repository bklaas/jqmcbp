#!/usr/bin/perl
#
# leaderboard.cgi
#

#use strict;
use CGI qw/:all/; # cgi.pm module
use DBI;
use Template;
use vars qw/$dbh/;
do "jq_globals.pl";
$| = 1;

print "Content-type: text/html\n\n";
connect_to_db();
my $config = config_variables();
my %PARAMS;
# start with some defaults
$PARAMS{"sort"} = "rank";
$PARAMS{"view"} = "25";
$PARAMS{"order"} = "asc";
$PARAMS{'man_or_chimp'} = 'both';
$PARAMS{'last_updated'} = get_last_updated();
$PARAMS{'year'} = '2008';
my $tm = "&#0153;";
$PARAMS{'cgi'} = 'leaderboard';
$PARAMS{'title'} = 'JQMCBP Leaderboard';
$PARAMS{'pool_size'} = get_player_pool_size('man');
my $cookie = cookie("thisisme2");
my $thisisme; my $similarities;
if ($cookie) {
	$thisisme = thisIsMe($cookie);
	$similarities = getSimilarities($cookie);
}

# take in params
for (param()) {
	$PARAMS{$_} = param("$_");
}

my $filters = get_filter_info();
my $filter_ids;
if ($PARAMS{'filter'} > 0) {
	$filter_ids = get_filter_ids($PARAMS{'filter'});
	$PARAMS{'man_or_chimp'} = 'man';
} else {
	$filter_ids = "";
}
	my $class1 = "brackets1";
	my $class2 = "brackets2";
	my $class3 = "brackets_clear";
my $heading_color = "#c60b0b";
my $table_color = "silver";
my %sort_fields = ( 
			'rank'		=>	'scores.rank',
			'j2_factor'	=>	'player_info.j2_factor',
			'location'	=>	'player_info.location',
			'name'		=>	'player_info.name',
			'candybar'	=>	'player_info.candybar',
			'location'	=>	'player_info.location',
			'champion'	=>	'player_info.champion',
			'rtt'		=>	'scores.rtt',
		);
$sort_fields{'rank'} = 'scores.combined_rank' if $PARAMS{'man_or_chimp'} eq 'both';
($PARAMS{'tally'}, $PARAMS{'high_score'}, $PARAMS{'last'}, $PARAMS{'next'}, my $score_ref) = get_scores_from_db();
$PARAMS{'prev'} = $prev unless $PARAMS{'prev'};

my ($first, $last, $next);
# first set up defaults of 25 and rank
 
if ($PARAMS{"order"} eq "asc") {
	$PARAMS{"toggle_order"} = "desc";
} else {
	$PARAMS{"toggle_order"} = "asc";
}


my %sort_item = (
		"rank"	=>	"Rank",
		"name"	=>	"Name",
		"candybar"	=> "Candybar",
		"location"	=> "Location",
		"j2_factor"	=> "J Factor$tm",
		"champion"	=> "Champion",
		"rtt"	=>	"RtT$tm"
		);
my %order = (
		"desc"	=>	"High to Low",
		"asc"	=>	"Low to High"
		);

my %view = (	"10"	=> "10",
		"25" => "25",
		"100" => "100",
                "All" => "All",
            );

my %data = ( 'view'    =>      \%view,
                'params'        =>      \%PARAMS,
                'order' =>      \%order,
		'sort_item' =>	\%sort_item,
		'filters' => $filters,
		'scores'  => $score_ref,
		'filter_ids' => $filter_ids,
		'thisisme'	=>	$thisisme,
		'cookie'	=>	$cookie,
		'similarities'	=>	$similarities,
                );

my $file = "cgi_generic";
my $template = Template->new( {
                INCLUDE_PATH => "$config->{'template_dir'}",
} ) or print "couldn't do it $!";
                $template->process($file, \%data)
                || die "Template process failed: ", $template->error(), "\n";

exit;

sub get_scores_from_db {
	# find out what the last 'step' was
	my $query = 'select step from scores order by step desc limit 1';
	my $ref = single_row_query($query);
	my $step = $ref->{'step'};
	# find out high score
	$query = "select score from scores where step = \"$step\" order by score desc limit 1";
	$ref = single_row_query($query);
	my $high_score = $ref->{'score'} || '0';
	# find out tally of people
	$query = "select count(*) as count from player_info where man_or_chimp = 'man'";
	$ref = single_row_query($query);
	my $tally = $ref->{'count'};

	# grab all scores sorted by $PARAMS{'sort'}
	my $sort = $PARAMS{'sort'};
	my $where_frag = "player_info.player_id = scores.player_id and scores.step = \"$step\" ";
	if ($PARAMS{'man_or_chimp'} ne 'both') {
		$where_frag .= "and player_info.man_or_chimp = \"$PARAMS{'man_or_chimp'}\" ";
	}
	# if there are filters add all the filter_ids here
	if ($PARAMS{'filter'} > 0) {
		$where_frag .= "AND (";
		for my $key (keys %$filter_ids) {
			$where_frag .= "player_info.player_id = \"$key\" OR ";
		}
		$where_frag =~ s/OR $/)/;
	}
	
	my $order_frag = "$sort_fields{$sort}";
	$order_frag .= " desc" if $PARAMS{'order'} eq 'desc';
	$query = "select * from scores, player_info where $where_frag order by $order_frag, player_info.man_or_chimp desc, player_info.player_id";

	my $aref = multi_row_query($query);
	my %return;
	my $slurp = 1;
	if ($PARAMS{'next'}) {
		$slurp = 0;
	}
	my $inc = 1;
	my @return;
	my $next = 0;
	my $prev = 0;
	for my $href (@$aref) {
		my $id = $href->{'player_id'};
		if ($id == $PARAMS{'next'}) {
			$slurp = 1;
		}
		if ($PARAMS{'view'} !~ /all/i && $inc > $PARAMS{'view'}) {
			$next = $id;
			last;
		}
		next unless $slurp;
		last if $id == $PARAMS{'prev'};
		push @return, $href;
		$inc++;
	}
	if ($PARAMS{'next'}) {
		$prev = $return[0]->{'player_id'};
	} else {
		$prev = 0;
	}
	return ($tally, $high_score, $prev, $next, \@return);
}

