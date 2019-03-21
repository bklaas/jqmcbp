#!/usr/bin/perl
#
# hallofshame.cgi
#

print "Content-type: text/html\n\n";
use strict;
use CGI qw/:all/; # cgi.pm module
use DBI;
use vars qw/$dbh/;
do "./jq_globals.pl";
$| = 1;

my $config = config_variables();
my $data_dir = "/tmp";
my $javascript = "/jqmcbp/effects.js";
my $link = "/cgi-bin/hallofshame.cgi";
my $stylesheet = "/johnnyquest/$config->{'year'}/jqmcbp.css";
	my $class1 = "brackets1";
	my $class2 = "brackets2";
	my $class3 = "brackets_clear";
my $heading_color = "#c60b0b";
my $table_color = "silver";
my ($first, $last, $next);
# first set up defaults of 25 and place
my %PARAMS;
$PARAMS{"sort"} = "rank";
$PARAMS{"view"} = "All";
$PARAMS{"order"} = "asc";
# take in params
for (param()) {
	$PARAMS{$_} = param("$_");
}
 
if ($PARAMS{"order"} eq "asc") {
	$PARAMS{"toggle_order"} = "desc";
} else {
	$PARAMS{"toggle_order"} = "asc";
}
my $tm = "&#0153;";
	
my %sort_item = (
		"place"	=>	"Rank",
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

connect_to_db();
$PARAMS{'high_score'} = get_high_score();
my $cookie = cookie('thisisme2');
my $thisisme; my $similarities;
if ($cookie) {
	$thisisme = thisIsMe($cookie);
	$similarities = getSimilarities($cookie);
}
my $high_score = get_high_score();
my $step = get_step();
my ($scores, $tally) = get_shameful_scores_db();
# first pass just try to display Top 25
my $sort = $PARAMS{"sort"};
my %sort_hash = ();
for (keys %$scores) {
	$sort_hash{$_} = $scores->{$_}{$sort};
}

# numerical sorts are: place, score
# alphabetical scores are: name, candybar
my $sorted_scores;
if ($PARAMS{"sort"} eq "rank" || $PARAMS{"sort"} eq "j2_factor" || $PARAMS{'sort'} eq "rtt") {
	if ($PARAMS{"order"} eq "asc") {
		$sorted_scores = num_asc_sort();
	} else {
		$sorted_scores = num_desc_sort();
	}
} else {
	if ($PARAMS{"order"} eq "desc") {
		$sorted_scores = alpha_desc_sort();
	} else {
		$sorted_scores = alpha_asc_sort();
	}
}

my $last_updated = get_last_updated();
	
$dbh->disconnect();

use Template;
$PARAMS{'title'} = "The Hall of Shame$tm";
$PARAMS{'cgi'} = 'hallofshame';
my @tally_strings = split(//, $tally);
$tally_strings[0] = 0 if $tally eq "";
my %data = ( 
              'params'  =>      \%PARAMS,
	    	'sort_item'	=>	\%sort_item,
		'order'		=>	\%order,
		'view'		=>	\%view,
		'last_updated'	=>	$last_updated,
		'scores'	=>	$sorted_scores,
		'tally'		=>	$tally,
		'tally_strings'	=>	\@tally_strings,
		'step'		=>	$step,
		'high_score'	=>	$high_score,
		'next'		=>	$next,
		'cookie'	=>	$cookie,
		'thisisme'	=>	$thisisme,
		'similarities'	=>	$similarities,
            );

my $tmpl = "cgi_generic";
my $template = Template->new( {
            INCLUDE_PATH => "$config->{'template_dir'}",
																 } ) or print "couldn't do it $!";
$template->process($tmpl, \%data) || die "Template process failed: ", $template->error(), "\n";

exit;

unless ($PARAMS{'view'} =~ /All/) {
	print "<a href = \"$link?sort=$PARAMS{'sort'}&order=$PARAMS{'order'}&view=$PARAMS{'view'}&next=$next\">Next $PARAMS{'view'}</a>";
}

sub alpha_desc_sort {
	my $inc = 1;
	my $got_it = 0;
	my @return;
	my $index;
	if ($PARAMS{'previous'} && $PARAMS{'get_previous'}) {
		$index = $PARAMS{'previous'};
	} elsif ($PARAMS{'next'}) {
		$index = $PARAMS{'next'};
	}
	for my $key ( sort { $sort_hash{$b} cmp $sort_hash{$a} }  keys %sort_hash) {
		if ($index && !$got_it) {
			if ($key == $index) {
				$got_it = 1;
			} else {
				next;
			}
		}
		$first = $key if $inc == 1;
		# show x number of records
		$next = $key;
		last if $inc > $PARAMS{"view"} && $PARAMS{"view"} ne "All"; 
		$last = $key;
		$inc++;
		push @return, $scores->{$key};
	}
	return \@return;
}

sub alpha_asc_sort {
	my $inc = 1;
	my $got_it = 0;
	my $index;
	my @return;
	if ($PARAMS{'previous'} && $PARAMS{'get_previous'}) {
		$index = $PARAMS{'previous'};
	} elsif ($PARAMS{'next'}) {
		$index = $PARAMS{'next'};
	}

	for my $key ( sort { $sort_hash{$a} cmp $sort_hash{$b} }  keys %sort_hash) {
		if ($index && !$got_it) {
			if ($key == $index) {
				$got_it = 1;
			} else {
				next;
			}
		}
		$first = $key if $inc == 1;
		# show x number of records
		$next = $key;
		last if $inc > $PARAMS{"view"} && $PARAMS{"view"} ne "All";
		$last = $key;
		$inc++;
		push @return, $scores->{$key};
	}
	return \@return;
}

sub num_desc_sort {
	my $inc = 1;
	my $got_it = 0;
	my $index;
	my @return;
	if ($PARAMS{'previous'} && $PARAMS{'get_previous'}) {
		$index = $PARAMS{'previous'};
	} elsif ($PARAMS{'next'}) {
		$index = $PARAMS{'next'};
	}
	for my $key ( sort { $sort_hash{$b} <=> $sort_hash{$a} }  keys %sort_hash) {
		if ($index && !$got_it) {
			if ($key == $index) {
				$got_it = 1;
			} else {
				next;
			}
		}
		$first = $key if $inc == 1;
		# show x number of records
		$next = $key;
		last if $inc > $PARAMS{"view"} && $PARAMS{"view"} ne "All";
		$last = $key;
		$inc++;
		push @return, $scores->{$key};
	}
	return \@return;
}

sub num_asc_sort {
	my $inc = 1;
	my $got_it = 0;
	my $previous;
	my $index;
	my @return;
	if ($PARAMS{'previous'} && $PARAMS{'get_previous'}) {
		$index = $PARAMS{'previous'};
	} elsif ($PARAMS{'next'}) {
		$index = $PARAMS{'next'};
	}
	for my $key ( sort { $sort_hash{$a} <=> $sort_hash{$b} }  keys %sort_hash) {
		if ($index && !$got_it) {
			if ($key == $index) {
				$got_it = 1;
			} else {
				next;
			}
		}
		$first = $key if $inc == 1;
		$next = $key;
		# show x number of records
		unless ($sort_hash{$key} == $previous) {
			last if $inc > $PARAMS{"view"} && $PARAMS{"view"} ne "All";
		}
		# show x number of records plus ties
		$last = $key;
		$inc++;
		$previous = $sort_hash{$key};
		push @return, $scores->{$key};
	}
	return \@return;
}

sub get_shameful_scores_db {

	my $query = "select * from scores, player_info where player_info.player_id = scores.player_id and scores.step = \"$step\" and scores.rtt < $high_score and player_info.man_or_chimp = 'man' order by scores.rank, player_info.name";
	my $ref = multi_row_query($query);
	my %return;
	my $inc;
	for my $href (@$ref) {
		my $id = $href->{'player_id'};
		for my $key (keys %$href) {
			$return{$id}{$key} = $href->{$key};
		}
		$inc++;
	}
	return \%return, $inc;
}
