#!/usr/bin/perl 
#
# winners.cgi
#
# this cgi is to enter the winners of the tournament as it progresses
#
# bklaas 3.00

$| = 1;  # make sure output is unbuffered

use CGI qw/:all/; # cgi.pm module
use File::Copy;   # file copy module for perl
use DBI;   # perl DBI module
use vars qw/$dbh/;
do "jq_globals.pl";

my $config = config_variables();
my $scoring_prog = "/data/cgi-bin/scoring.pl";
my $histogram_prog = "/data/cgi-bin/histogram.pl";
my %winners;
my @games;
for (1..63) {
	my $game = "game_" . $_;
	push @games, $game;
}
package main;
 
connect_to_db();

###############################################################
## make variables for the WINNERS
###############################################################
# this is with the new schema
# winners hash is populated from games table
 
my $winner_sql = "select game, winner from games";

my $winner_ref = multi_row_query($winner_sql);

for my $hashref (@$winner_ref) {
        $game_name = $hashref->{game};
	$winners{$game_name} = $hashref->{winner};
#        $winner_hash{$game_name} = $hashref->{winner};
}

for (@games) {
	$winners{$_} = "foo" unless $winners{$_};
}
#foreach my $keys (keys %winners) {
#	$winner = $winners{$keys};
#	$var_name = "winner_" . $keys;
#	$$var_name = $winner;
#	if ($$var_name eq "foo") {
#		$$var_name = '&nbsp;';
#	}
#}

########################################################################
########################initialize some variables#######################
########################################################################

$javascript = "/jqmcbp/effects.js";
$imagedir = "/jqmcbp/images";
$stylesheet = "/jqmcbp/jqmcbp.css";
#$stylesheet = "/johnnyquest/johnnyquest_style.css";

# ben, this one needs to change to reflect region pairings
my @brackets = get_bracket_order();
my $teams = get_teams(@brackets);

for my $hash_ref (@$teams) {
	push @team_names, $hash_ref->{team};
	push @seeds, $hash_ref->{seed};
}

# pull in all passed parameters
foreach $input (param()) {
   $$input = param("$input");
}

########################################################################

print header,
start_html(-title=>"JohnnyQuest$config->{'year'} Admin Page",
           -script=>{-src=>"$javascript",
           -language=>'JavaScript'},
           -style=>{
           -src=>"$stylesheet" }
           );

print <<EOHTML;
<center>
<img src = "$imagedir/johnnyquest.gif">
<br>
<hr>
EOHTML

if (!param("SubmitIt") && !param("BRACKETS")) {
########################################################
#### first round code and html #########################
########################################################

	print "<form><input type = submit name = 'BRACKETS' value = 'Submit Bracket Order'></form>\n";
   print "<B>Here's your chance to enter the winners</B>\n";
print <<EOHTML;
  </center>
EOHTML

print <<EOHTML;
<form method=POST>
<p>
<center>
<table cellpadding=4 cellspacing=2 border=1>
<tr bgcolor=#FF7F00 align=center>
<td><font face="Arial black" size=-2 color=#FFFFFF></font></td>
<td><font face="Arial black" size=-2 color=#FFFFFF>1ST ROUND</font></td>
<td><font face="Arial black" size=-2 color=#FFFFFF>2ND ROUND</font></td>
<td><font face="Arial black" size=-2 color=#FFFFFF>SWEET 16</font></td>
<td><font face="Arial black" size=-2 color=#FFFFFF>GREAT 8</font></td>
<td><font face="Arial black" size=-2 color=#FFFFFF>FINAL FOUR</font></td>
<td><font face="Arial black" size=-2 color=#FFFFFF>FINALS</font></td>
</tr><p>
EOHTML

$which_row = 33;
$b = 0;
for ($j = 0; $j <= 63; $j=$j+2) {
# make variables for table formatting of brackets
$row_modulus2 = $which_row%2; 
$row_modulus4 = $which_row%4;
$row_modulus8 = $which_row%8;
$row_modulus16 = $which_row%16;
$row_modulus32 = $which_row%32;

$k = $j+1;

if ($row_modulus8 ==1) {
print "<td rowspan=8 bgcolor=white>
       <img src=\"$imagedir/$brackets[$b]_banner.gif\">
       </td>";
 $b = $b+1;
}
print "<td bgcolor=#4D4DFF>
      <b><font face=\"Arial\" size=-1>";

#### print first round opponents
    $game = $j/2; # game counts from 0 to 31


   if ($winners{$games[$game]} eq "$team_names[$j]") {

    print "<INPUT TYPE=radio NAME=\"$games[$game]\" VALUE=\"$team_names[$j]\" CHECKED>
    $seeds[$j] $team_names[$j]<BR>";

   } else {

    print "<INPUT TYPE=radio NAME=\"$games[$game]\" VALUE=\"$team_names[$j]\">
    $seeds[$j] $team_names[$j]<BR>";

   }

   if ($winners{$games[$game]} eq "$team_names[$k]") {

print "<INPUT TYPE=radio NAME=\"$games[$game]\" VALUE=\"$team_names[$k]\" CHECKED>
    $seeds[$k] $team_names[$k]\n";

    } else {

print "<INPUT TYPE=radio NAME=\"$games[$game]\" VALUE=\"$team_names[$k]\">
    $seeds[$k] $team_names[$k]\n";

}
print "</b></td>\n"; 

#### print second round opponents
if ($row_modulus2 == 1) {
   $game = $j/4; # game counts from 0 to 15
   $place = $game + 32; # place counts from 32 to 47
   print "<td rowspan=2 bgcolor=#8B3A3A><b>";
   print "<INPUT TYPE=text NAME=\"$games[$place]\" 
   VALUE=\"$winners{$games[$place]}\">";
  print "</b></td>";
}
#### print third round opponents
if ($row_modulus4 == 1) {
  $game = $j/8; # counts from 0 to 7
  $place = $game + 48; # counts from 48 to 55
   print "<td rowspan=4 bgcolor=#4D4DFF><b>";
 print "<input type=text name=\"$games[$place]\"
       value=\"$winners{$games[$place]}\">
 </b></td>\n";
}          

if ($row_modulus8 == 1) {
   $game = $j/16; # counts from 0 to 3
   $place = $game + 56; # counts from 56 to 59
   print "<td rowspan=8 bgcolor=#8B3A3A>";
 print "<input type=text name=\"$games[$place]\"
   value=\"$winners{$games[$place]}\">
 </b></td>\n";
}
if ($row_modulus16 == 1) {
   $game = $j/32; # counts from 0 to 1
   $place = $game + 60; # counts from 60 to 61
   print "<td rowspan=16 bgcolor=#4D4DFF>";
print"<input type=text name=\"$games[$place]\"
   value=\"$winners{$games[$place]}\">
 </b></td>\n";
}
if ($row_modulus32 == 1) {
   print "<td rowspan=32 bgcolor=#8B3A3A>";
print"<input type=text name=\"game_63\"
   value=\"$winners{'game_63'}\">
 </b></td>\n";
}
print "</tr><p><p>\n";
$which_row = $which_row+1;
}
print "<tr><td colspan=7 align=center>\n";

   print "<input type = submit name=\"SubmitIt\" value = \"GO BEN GO!\">\n";
print "</td></tr></table>\n";
print "</form>\n";
print end_html;
exit(0);

} elsif (param("BRACKETS")) {

	if (!param("SUBMIT_BRACKETS")) {
		print "</center><h2>Enter bracket order</h2><form>\n";
		my $inc;
		for (@brackets) {
			$inc++;
			print "<input type = text name = 'region_$inc' value = '$_'><br>\n";
		}
		print "<input type = submit name = \"SUBMIT_BRACKETS\" value = \"WRITE IT\">\n";
		print "<input type = hidden name = \"BRACKETS\" value = '1'>\n";
		print "</form>\n";
		print "data are written to /etc/httpd/htdocs/jqmcbp/brackets.order";
	} else {
		print "</center>\n";
		my @order;
		for ('region_1', 'region_2', 'region_3', 'region_4') {
			print param($_) . "<br>\n";
			push @order, param($_);
		}
		write_order(@order);
		update_games(@order);
		
	}

	print "</body></html>\n";
	exit;

} elsif (param("SubmitIt")) {

	print "teams are entered.\n";
	for (@games) {
		if (param($_)) {
			$winners{$_} = param($_);
		} else {
			$winners{$_} = "foo";
		}
	}
}

#for my $game (0..31) {
#	if (!$$game) {
#		$$game = "foo";
#	}
#}

print_record();

#print "<br>$sql_update\n";
#system("perl $scoring_prog") or die "can't do it foo";
#`perl $scoring_prog` or warn "can't do it foo: $!";
#`perl $histogram_prog` or warn "can't do it: $!";

for my $prog ($scoring_prog, $histogram_prog) {
	print "<br>RUNNING $prog<br>\n";
	open(PROG, "/usr/bin/perl $prog |") or die "$!";
	while(<PROG>) {
		print "$_<br>\n";;
	}
	close(PROG);
}

print "<br>\n";
print "<a href=\"/jqmcbp/leaderboard.cgi\">LEADERBOARD</a>\n";
print end_html;
exit(0);



sub print_record {

	# update last_updated table
	my $timestamp = localtime;
	my $update = "update last_updated set last_updated = \"$timestamp\"";
	$dbh->do($update);

	for (@games) {
		my $sql = "UPDATE games SET
			winner=\"$winners{$_}\" where
			games.game=\"$_\"";
#print "$sql<br>\n" if $winners{$_} ne "foo";
		$dbh->do($sql) or die "$DBI::ERRSTR";

 	}
}

sub write_order {

	my @order = @_;
	open(ORDER,">/etc/httpd/htdocs/jqmcbp/brackets.order");
	for (@order) {
		print ORDER $_ . "\n";
	}
	close(ORDER);
}

sub update_games {

	my @order = @_;

	my @first = qw/ 1 2 3 4 5 6 7 8 33 34 35 36 49 50 57/;
	my @second = qw/ 9 10 11 12 13 14 15 16 37 38 39 40 51 52 58/;
	my @third = qw/ 17 18 19 20 21 22 23 24 41 42 43 44 53 54 59/;
	my @fourth = qw/ 25 26 27 28 29 30 31 32 45 46 47 48 55 56 60/;

	my @games = ( \@first, \@second, \@third, \@fourth);

	for my $i (0..3) {
		my $region = $order[$i];
		my $nums = $games[$i];
		for (@$nums) {
			my $game = "game_" . $_;
			my $update = "update games set region = \"$region\" where game = \"$game\"";
			$dbh->do($update) or die "$DBI::ERRSTR";
			print $update . "<br>\n";
		}
			
	}

}
