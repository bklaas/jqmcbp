#!/usr/bin/perl 
#
# jqmcbp_filter.cgi
#

$| = 1;  # make sure output is unbuffered

print "Content-type: text/html\n\n";

use CGI qw/:param :cookie/; # cgi.pm module
use File::Copy;   # file copy module for perl
use DBI;   # perl DBI module
use vars qw/$dbh/;
do "./jq_globals.pl";
connect_to_db();

my $cookie = cookie('thisisme2');
my $thisisme;
if ($cookie) {
	$thisisme = thisIsMe($cookie);
}
my $config = config_variables();
my %PARAMS;
$PARAMS{'high_score'} = get_high_score();
for (param()) {
	$PARAMS{$_} = param($_);
}

my $player_sql = "select * from player_info where man_or_chimp = \"man\" order by name";
#my $player_sql = "select * from player_info order by name";
my $player_info = multi_row_query($player_sql);
my $tm = "&#0153;";

my $update;
if ($PARAMS{'submit_filter'} =~ /this filter/ || $PARAMS{'update_filter'}) {
	# get current filter names
	my $name_query = multi_row_query("select name from filter");
	# check that it's not in use
	if ($PARAMS{'update_filter'}) {
		# delete the existing filter_link info
		$dbh->do("DELETE from filter_link where filter_id = \"$PARAMS{'filter_id'}\"") or bail("POOP! This SQL insert: $insert<p>Please let the Candymeister know about this immediately");
		# delete the existing filter
		$dbh->do("DELETE from filter where filter_id = \"$PARAMS{'filter_id'}\"") or bail("POOP! This SQL insert: $insert<p>Please let the Candymeister know about this immediately");
	} else {
		for (@$name_query) {
			if ($PARAMS{'filter_name'} eq $_->{'name'}) {
				bail("The filter name $PARAMS{'filter_name'} is already taken. Hit back on your browser and try a different one.");
			}
		}
	}
	# first enter the filter name
	my $insert = "INSERT into filter (name) values (\"$PARAMS{'filter_name'}\")";
	$dbh->do($insert) or bail("POOP! This SQL insert: $insert<p>Please let the Candymeister know about this immediately");

	# then extract the id
	my $get_it_back = single_row_query("select filter_id from filter where name = \"$PARAMS{'filter_name'}\"");
	my $filter_id = $get_it_back->{'filter_id'};
	# finally, add the filter_link infO
	for (keys %PARAMS) {
		if (/^id_/) {
			my $insert = "INSERT into filter_link (filter_id, player_id) values (\"$filter_id\", \"$PARAMS{$_}\")";
			$dbh->do($insert) or bail("POOP! This SQL insert: $insert<p>did not work<br>Please let the Candymeister know about this immediately");
		}
	}
	$update = "<h5 class = 'enter'>Filter named $PARAMS{'filter_name'} has been updated/added</h2>";
}

my $filters = get_filter_info();
my $filter_name;
for (@$filters) {
	if ($_->{'filter_id'} eq $PARAMS{'filter'}) {
		$filter_name = $_->{'name'};
	}
}
my $filter_ids;
if ($PARAMS{'filter'} ne "") {
        $filter_ids = get_filter_ids($PARAMS{'filter'});
} else {
        $filter_ids = "";
}
my $cols = 3;

use Template;
$PARAMS{'title'} = "Filtermatic$tm";
$PARAMS{'cgi'} = 'filtermatic';
my $ary_size = scalar(@$player_info);
my $divs = int($ary_size/$cols);
$divs++;
my %data = ( 
              'params'  =>      \%PARAMS,
	    	'tableCols'	=>	$cols,
	    	'player_info'	=>	$player_info,
		'filter_ids'	=>	$filter_ids,
		'filters'	=>	$filters,
		'filter_name'	=>	$filter_name,
		'update'	=>	$update,
		'divs'		=>	$divs,
		'cookie'	=>	$cookie,
		'thisisme'	=>	$thisisme,
            );

my $tmpl = "cgi_generic";
my $template = Template->new( {
            INCLUDE_PATH => "$config->{'template_dir'}",
																 } ) or print "couldn't do it $!";
$template->process($tmpl, \%data) || die "Template process failed: ", $template->error(), "\n";

exit;

sub bail {
	my $message = shift;
	print "<h2 class = 'enter'>$message</h2>\n";
	print "</div>\n";
	print "</body></html>\n";
	exit;
}
