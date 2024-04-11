#!/usr/bin/perl

use DBI;
#use Data::Dump qw(dump);

die "usage: ./dat2db.pl path_to_files man_or_chimp" unless (-d $ARGV[0] && ($ARGV[1] eq "man" || $ARGV[1] eq "chimp" ));

    my @time = localtime();
    my $year = sprintf("%04d", $time[5] + 1900);

my $dirpath = $ARGV[0];
my $man_or_chimp = $ARGV[1];
my $dbh;
connect_to_database();

opendir(DIR,"$dirpath");
my @player_data = ("name","email","candybar","location","champion","entry_time", "man_or_chimp", 'alma_mater');

my @pick_data = ("name");
for (1..63) {
	my $game = "game_" . $_;
	push @pick_data, $game;
}

my %done;
open(DONE,"</home/bklaas/jqmcbp/perl/done");
while(<DONE>) {
	chomp;
	$done{$_}++;
}
close(DONE);

# iterate through data files
while (defined($datfile = readdir(DIR))) {

	next unless $datfile =~ /\.dat$/;
	#next if $done{$datfile};
    if ($done{$datfile}) {
        print STDERR "$datfile already in DB.\n";
        next;
	}
	#print "$datfile this one ain't done\n";
	my ($timestamp, @trash) = split /\./, $datfile;
	# blank out arrays for use in loop
	@vals = ();
	@picks_vals = ();
	@fields = ();
	@picks_fields = ();
	%picks = ();
	%player_info = ();

	# read data file into name value pairs
	#$datfile =~ s/\@/\\@/g;
	print "entering data for $datfile\n";
	open (DATAFILE,"<$dirpath/$datfile");
     
        while (<DATAFILE>) {
		chomp;
              $line = $_;
		# escape quote characters
              $line =~ s/\"/\'/g;
              $line =~ s/\'/\\\'/g;
		
              ($name, $value) = split /\|/, $line;
              if ($name eq "locale") {
                 $name = "location";
              }
		if ($name eq 'candy') {
			$name = 'candybar';
		}
		# remove leading spaces
		$value =~ s/^\s+//;
              for $i (0..$#player_data) {
                  if ($player_data[$i] eq $name) {
                     $player_info{$name} = $value;
                  }
              }
              # tack in timestamp as well since it's not in the file
	      $player_info{'entry_time'} = $timestamp;
              for $i (0..$#pick_data) {
                 if ($pick_data[$i] eq $name) {
                  $picks_info{$name} = $value;
                 }
              }
              # this hash is for the old PLAYERS table. leave it as a backup
              $picks{$name} = $value;
        }
	close (DATAFILE);
    if ($man_or_chimp eq 'man') {
    	open(DONE,">>/home/bklaas/jqmcbp/perl/done");
    	print DONE "$datfile\n";
    	close(DONE);
    }


# champion as well
$player_info{'champion'} = $picks_info{'game_63'};
# man or chimp
$player_info{'man_or_chimp'} = $man_or_chimp;

foreach $key (keys %player_info) {
       push @fields, $key;
       push @vals, $player_info{$key};
}

foreach $key (keys %picks_info) {
       push @picks_fields, $key;
       push @picks_vals, $picks_info{$key};
       #print "'$key', ";
}


# write to PLAYER_INFO table
construct_playerinfo_sql();

unless ($test) {
	$dbh->do($playerinfo_sql) unless $test;

}

# grab player_id from PLAYER_INFO table
my $player_id_sql = "SELECT player_id from player_info where name = \"$picks{name}\" order by player_id desc limit 1";

my $sth;
unless ($test) {
	$sth = $dbh->prepare($player_id_sql);
	$sth->execute();
	$player_id = $sth->fetchrow_array();
	$sth->finish();
}

# write to PICKS table
foreach $key (keys %picks_info) {
	next if $key eq "name";
	$picks_sql = "INSERT INTO picks (name, game, winner, player_id)
                      VALUES('$player_info{name}', '$key', '$picks_info{$key}', '$player_id')\n";
	# put it in the DB
    print "$picks_sql\n";
	$dbh->do($picks_sql) unless $test;
}

###################################
# calculate j and j2 factors
my $sigma1; my $sigma2;
my $frag = make_frag("1","32");

my $query = "select sum(teams.seed) as total, picks.name from teams, picks where teams.team = picks.winner and picks.player_id = \"$player_id\" and ( $frag ) group by picks.player_id order by total";
my $frag2 = make_frag("49","56");
my $query2 = "select sum(teams.seed) as total, picks.name from teams, picks where teams.team = picks.winner and picks.player_id = \"$player_id\" and ( $frag2 ) group by picks.player_id order by total";

unless ($test) {
	$sth = $dbh->prepare($query);
	$sth->execute();
	while (my $hashref = $sth->fetchrow_hashref) {
		$sigma1 = $hashref->{total};
	}
	$sth->finish();
}

unless ($test) {
	$sth = $dbh->prepare($query2);
	$sth->execute();
	while (my $hashref = $sth->fetchrow_hashref) {
		$sigma2 = $hashref->{total};
	}
	$sth->finish();
}

my $j = (($sigma1 - 144) / 256);
my $j_factor = 100 * $j;
my $j2 = ( $j + ( 4 * (($sigma2 -12)/112)) );
my $j2_factor = 20 * $j2;

if ($j_factor == 100) {
    $j_factor = 99.99;
}
if ($j2_factor == 100) {
    $j2_factor = 99.99;
}

print "j_factor: $j_factor\tj2_factor: $j2_factor\n";
my $insert = "UPDATE player_info set j_factor = \"$j_factor\", j2_factor = \"$j2_factor\" where player_id = \"$player_id\"";
$dbh->do($insert) unless $test;

# end readdir while loop
}
closedir(DIR);

# fix weird quote chars
my $q1 = "update `player_info` set `candybar` = REPLACE(`candybar`, CHAR(145), \"'\")";
my $q2 = "update `player_info` set `candybar` = REPLACE(`candybar`, CHAR(146), \"'\")";
$dbh->do($q1);
$dbh->do($q2);

# finally, write the entry_count.json file
my $howmany = "SELECT count(*) as count from player_info where man_or_chimp = 'man'";
$sth = $dbh->prepare($howmany);
$sth->execute();
my $count = 0;
while (my $hashref = $sth->fetchrow_hashref) {
	$count = $hashref->{count};
}
$sth->finish();

open(COUNT, ">/home/bklaas/jqmcbp/web/$year/entry_count.json") or die $!;
print COUNT "{ \"entry_count\": \"$count\" }\n";
close(COUNT);

sub construct_playerinfo_sql {

$frag = "";
$frag2 = "";

for $i (0..$#fields) {

    unless ($i == $#player_data) {
         $join = ", ";
    } else {
         $join = " ";
    }

    $frag .= $fields[$i] . $join;
    $frag2 .= "'$player_info{$fields[$i]}'" . $join;
    #print "$fields[$i]\n";
}
	$frag =~ s/\s*,\s*$//;
	$frag2 =~ s/\s*,\s*$//;

$playerinfo_sql = "INSERT INTO player_info (" . $frag . ") VALUES(" . $frag2 . ")";
#print "$playerinfo_sql\n";

}

$dbh->disconnect();

sub make_frag {
	# sub to deal with new naming scheme for games
	my $first = shift;
	my $last = shift;
	my $frag;
	for ($first..$last) {
		$frag .= " picks.game = \"game_$_\" ";
		$frag .= "OR " unless $_ == $last;
	}
	return $frag;
}

sub connect_to_database {
###############################################################
############### connect to database ###########################
###############################################################
my $database_name = "johnnyquest";
my $location = "localhost";
my $port_num = "3306";
my $database = "DBI:mysql:$database_name:$location:$port_num";
my $db_user = "nobody";

$dbh = DBI->connect($database,$db_user) or die $DBI::errstr;
################################################################
}
