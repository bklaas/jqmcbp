#!/usr/bin/perl 
#
# jq_entry.cgi
#
# this cgi is to serve up the html for the various rounds
# of selection in the johnnyquest pool
#
# complete rewrite of past jqmcbp bracket cgis

use strict;
$| = 1;  # make sure output is unbuffered

use CGI qw/:param :header :image_button/; # cgi.pm module

use DBI;   # perl DBI module
use Template;
use vars qw/$dbh/;
do "jq_globals.pl";
my $config = config_variables();
my %PARAMS;
for (param()) {
	$PARAMS{$_} = param($_);
	$PARAMS{$_} =~ s/"/'/g;
	if (/^[A-Z]/) {
		$PARAMS{$_} = 1;
	}
}

print "Content-type: text/html\n\n";

# enter the fix
if ($PARAMS{"ENTER_PICKS.x"} > 0) {
	submit_fix();
	my $file = "fixit.html.tmpl";
	my %data = ( 'submitted' => 'true' );
	my $template = Template->new( {
					INCLUDE_PATH => "$config->{'template_dir'}",
	} ) or print "couldn't do it $!";
	$template->process($file, \%data)
			|| die "Template process failed: ", $template->error(), "\n";
	exit;
}

$PARAMS{'year'} = $config->{'year'};

#$PARAMS{'id'} = 17418;
if (!$PARAMS{'id'} ) {
	print "<html><body><b>DOES NOT COMPUTE</b></body></html>\n";
	exit;
}

# html colors
connect_to_db();

my $query = "select name, email, player_id from player_info where player_id = \"$PARAMS{'id'}\"";
my $href = single_row_query($query);
my $name;
my $email;

if (!$href->{player_id}) {
	print "<html><body><b>WAT? DOES NOT COMPUTE</b>" . $query;
	for my $key ( sort keys %$href ) {
		print "$key<br>\n";
	}
	print "</body></html>\n";
	exit;
}
else {
	$name = $href->{name};
	$email = $href->{email};
}

# get games 57-60
my $ff = get_final_four();

$dbh->disconnect();

my %data = ( 
	'name'  => $name,
	'email'  => $email,
	'PARAMS'	=>	\%PARAMS,
	'teams'	=>	$ff,
);

my $file = "fixit.html.tmpl";
my $template = Template->new( {
                INCLUDE_PATH => "$config->{'template_dir'}",
} ) or print "couldn't do it $!";
		$template->process($file, \%data)
		|| die "Template process failed: ", $template->error(), "\n";

sub submit_fix {
        my $stamp = time;
        my $file = $stamp . "." . $PARAMS{'email'} . ".dat";
        my $dir = "/tmp/jq_fix";
        mkdir $dir, 0777 unless -d $dir;
        open(DATA,">$dir/$file") or warn "couldn't open $file: $!";
			for (sort keys %PARAMS) {
				next if /^[A-Z]/;
				my $key = $_;
				$key =~ s/^radio_//;
				print DATA "$key|$PARAMS{$_}\n";
		}
        close(DATA);
}

sub get_final_four {
	my @games = ( 'game_57', 'game_58', 'game_59', 'game_60' );
	my $return = [];
	for my $game (@games) {
		my $query = "select picks.winner as winner from picks, player_info where picks.player_id = player_info.player_id and picks.player_id = '$PARAMS{'id'}' and picks.game = '$game'";
		my $href = single_row_query($query);
		push @$return, $href->{winner};
	}
	return $return;
}
