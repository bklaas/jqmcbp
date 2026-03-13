#!/usr/bin/perl
#
# jq_admin.cgi
#
# this cgi is to serve up the html for the 
# adding of teams to the johnnyquest pool database
#
# this implementation uses the Perl DBI module and the Perl DBD::mysql
# module together with a local installation of mysql
#
# bklaas 3.00

$| = 1;  # make sure output is unbuffered


use CGI qw/:all/; # cgi.pm module
print header;
use File::Copy;   # file copy module for perl
use DBI;   # perl DBI module

package main;
my @brackets;
 
###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "johnnyquest";
my $location = "localhost";
my $port_num = "3306";
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

$dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
###############################################################

my @time = localtime();
my $year = $time[5] + 1900;
my $outfile = "/home/bklaas/jqmcbp/web/$year/brackets.order";

# pull in all passed parameters
my %PARAMS;
foreach $name (param()) {
   $$name = param("$name");
	$PARAMS{$name} = param($name);
}

################################################################
#######################get teams into array####################
################################################################
$sql = "select * from teams order by bracket, team_id";
my $sth = $dbh->prepare($sql);
unless ($sth->execute) {
   die "Statement failed" . $sth->errstr;
   }

my $hash_ref;
  $i=0;
        while ($hash_ref = $sth->fetchrow_hashref) {
			push @spot, $hash_ref->{spot};
			my $bracket = $hash_ref{bracket_name};
			$bracket{$bracket} = 1;
			push @team_names, $hash_ref->{team};
			push @seeds, $hash_ref->{seed};
			$i=$i+1;
        }
$sth->finish;
#

########################################################################
########################initialize some variables#######################
########################################################################
# the following two arrays end up getting used by the subroutine
# print_radio_list (see end of program)

$javascript = "/jqmcbp/effects.js";
$imagedir = "/johnnyquest/images";
$stylesheet = "/johnnyquest/johnnyquest_style.css";
@brackets = ("west", "south", "midwest", "east");
#my @mixed_up_brackets = ("midwest", "west", "south", "east");

########################################################################
if (param("SubmitIt")) {


#print header(-Refresh=>"3;URL=/jqmcbp/");
#print header();
print start_html(-title=>'Entering Teams...',
                 -author=>'mcstayinskool@yahoo.com',
                 -style=>{-src=>$stylesheet}),
    hr,
    h1({-align=>CENTER},'Entering teams...');

# set bracket order
write_order($PARAMS{'region_1'}, $PARAMS{'region_2'}, $PARAMS{'region_3'}, $PARAMS{'region_4'});

for (sort keys %PARAMS) {
	if (/^west_/ || /^midwest_/ || /^east_/ || /^south_/) {
		my $update = "UPDATE teams SET team = \"$PARAMS{$_}\" where spot = \"$_\"";
		print $update . "<br>\n";
		$dbh->do($update) or warn "couldn't do the update: $update <p> $DBI::ERRSTR";
	}
}
# set region for each game
update_games($PARAMS{'region_1'}, $PARAMS{'region_2'}, $PARAMS{'region_3'}, $PARAMS{'region_4'});
print hr;
print end_html;
exit(0);
}

print start_html(-title=>'JohnnyQuest2013',
           -script=>{-src=>"$javascript",
           -language=>'JavaScript'},
           -style=>{
           -src=>'/johnnyquest/johnnyquest_style.css' }
           );

print <<EOHTML;
<center>
   <B>JohnnyQuest Admin Page</B><BR>
  </center>
<form method=post>
<input type="hidden" name="name" value="[name]">
<input type="hidden" name="email" value="[email]">
<input type="hidden" name="location" value="[location]">
<p>
<center>
<table cellpadding=4 cellspacing=2 border=1>
<tr bgcolor=#FF7F00 align=center>
<td></td>

EOHTML
                print "<h2>Enter bracket order</h2>\n";
                my $inc;
                for (@brackets) {
                        $inc++;
                        print "<input type = text name = 'region_$inc' value = '$_'><br>\n";
                }
                print "data are written to $outfile";


for (@brackets) {
	my $foobar = $_;
print <<HEADING;
	<td><font face="Arial black" size=-2 color=#FFFFFF>$_ REGIONAL</font></td>
	<td><font face="Arial black" size=-2 color=#FFFFFF></font></td>
HEADING
}
print "</tr><p>\n";

$which_row = 33;
$b = 0;

for ($j = 0; $j <= 15; $j=$j+1) {
$row_modulus16 = $which_row%16;

for $region (0..3) {
    $multiplier = $region;
    $counter = ($multiplier*16)+$j;

#print banner if it's the first row
if ($row_modulus16 ==1) {
print "<td rowspan=16 bgcolor=white><img src=\"$imagedir/$brackets[$region]_banner.gif\"></td>";
 $b = $b+1;
}

print "<td nowrap bgcolor='#4D4DFF'>
       <b>
       $seeds[$counter]";
      if ($seeds[$counter] < 10) { print "&nbsp"; }
      #print"<INPUT TYPE=text size=15 maxlength=25 NAME=\"$spot[$counter]\" VALUE=\"$spot[$counter]\"> 
      #print"<INPUT TYPE=text size=15 maxlength=25 NAME=\"$spot[$counter]\" VALUE=\"$spot[$counter]\"> 
      print"<INPUT TYPE=text size=15 maxlength=25 NAME=\"$spot[$counter]\" VALUE=\"$team_names[$counter]\"> 
       <BR>
       </td>\n"; 

}

print "</tr><p><p>\n";
$which_row = $which_row+1;
}
print"<tr>
<td colspan = 8 align=center>
<input type = submit name = \"SubmitIt\" value = \"Go Ben Go\">
"; 
print "</table>\n";
print "</form>\n";
print end_html;
exit(0);

sub write_order {

        my @order = @_;
        open(ORDER,">$outfile") or die "$!";
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

