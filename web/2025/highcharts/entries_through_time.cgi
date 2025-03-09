#!/usr/bin/perl

use strict;

use DBI;
use vars qw/ $dbh /;
print "Content-type: text/html\n\n";
do "/data/benklaas.com/jqmcbp/jq_globals.pl";

use Template;
use Time::Local;

my %data;
my @legend;
my $labels;
my ($start_time, $end_time, $db);
for my $year ('2013', '2012', '2009', '2008', '2007', '2006', '2005') {
	if ($year eq '2005') {
		$start_time = timelocal(00,00,17,13,2,2005);
		$db = 'jq_2005';
	} elsif ($year eq '2006') {
		$start_time = timelocal(00,00,17,12,2,2006);
		$db = 'jq_2006';
	} elsif ($year eq '2007') {
		$start_time = timelocal(00,00,17,11,2,2007);
		$db = 'jq_2007';
	} elsif ($year eq '2008') {
		$start_time = timelocal(00,00,17,16,2,2008);
		$db = 'jq_2008';
	} elsif ($year eq '2009') {
		$start_time = timelocal(00,00,17,15,2,2009);
		$db = 'jq_2009';
	} elsif ($year eq '2012') {
		$start_time = timelocal(00,00,17,11,2,2012);
		$db = 'jq_2012';
	} elsif ($year eq '2013') {
		$start_time = timelocal(00,00,17,17,2,2013);
		$db = 'johnnyquest';
	}

	if ($year eq '2013') {
		my $now = time;
		$end_time = $now - $start_time > 327600 ? $start_time + 327600 : $now;
	} else {
		$end_time = $start_time + 327600;
	}
my $stamps = get_timestamps_from_db($db);
my $data = compile_data($stamps);

my $key = 'year_' . $year;
$data{$key} = $data;
push @legend, $year;

}

#my $tmpl = "entries_through_time.tmpl";
my $tmpl = "line.tmpl";

my $template_data = {
        data => \%data,
};

my $template = Template->new({ }) or die "$!";
$template->process($tmpl, $template_data)
        || print "Template process failed: ", $template->error(), "\n";


sub compile_data {
	my $stamps = shift;
	my @timestamps = @$stamps;
	my $i;
	my @return;
	my $stamp = 0;
	my $running_total;
	for ($i=$start_time; $i < $end_time; $i=$i+3600) {
		my $href;
		$href->{label} = $i;
		$href->{tally} = 0;
		for my $j (0..$#timestamps) {
			$href->{tally}++;
			if ($timestamps[$j] > $i) {
				last;
			}
		}
		push @return, $href->{tally};
	}
	return \@return;
}

sub get_timestamps_from_db {
	my @timestamps;
	my $db = shift || 'johnnyquest';
	connect_to_db($db);

	my $sql = "select entry_time from player_info where man_or_chimp = \"man\" order by entry_time";
	if ($db eq 'jq_2005') {
		$sql = "select entry_time from player_info order by entry_time";
	}
	my $aref = multi_row_query($sql);
	for my $href (@$aref) {
		push @timestamps, $href->{'entry_time'};
	}
	$dbh->disconnect();
	return \@timestamps;
}


