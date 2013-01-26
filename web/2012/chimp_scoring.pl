#!/usr/bin/perl 

use DBI;   # perl DBI module

use vars qw /$dbh/;
do "jq_globals.pl";

connect_to_db();
my @brackets = get_bracket_order();
my $teams_ref = get_teams(@brackets);

my $data_dir = "/tmp";

my %point_values;
my %winners;
my $run_the_table;
###############################################################
## make variables for the WINNERS
###############################################################

# new SQL for new schema
# WORKS getting winners hash populated from games table!
$winners_sql = "select * from games";

my $ref = multi_row_query($winners_sql);

for (@$ref) {
	$game_name = $_->{game};
	$winners{$game_name} = $_->{winner};
	$point_values{$game_name} = $_->{score};
}

# calculate all scores with one sql statement

$score_sql = "select sum(games.score) as score, 
              picks.name, player_info.candybar, 
              player_info.location, 
              player_info.champion, player_info.j2_factor,
		player_info.player_id
              from games, picks, player_info
              where
              picks.game = games.game and
              picks.winner = games.winner and
		player_info.man_or_chimp = \"chimp\" and
              picks.player_id = player_info.player_id
              group by player_info.player_id order by score desc, player_info.name";

print "$score_sql\n";
my $score_ref = multi_row_query($score_sql);

$i = 0;
my %names;
for my $hashref (@$score_ref) {
   #  put values into player hash
            # score
            $sorted_score_data[$i][0] = $hashref->{score};
            # name
		my $name = $hashref->{name};
            $sorted_score_data[$i][1] = $name;
		$names{$name}++;
            # candybar
            $sorted_score_data[$i][2] = $hashref->{candybar};
            # gender
            $sorted_score_data[$i][3] = "placeholder";
            # location
            $sorted_score_data[$i][4] = $hashref->{location};
	if ($hashref->{location} eq "") {
		$sorted_score_data[$i][4] = "--";
	}
            # champion
            $sorted_score_data[$i][5] = $hashref->{champion};
            # j factor
            $sorted_score_data[$i][6] = $hashref->{j2_factor};
            # player_id
            $sorted_score_data[$i][7] = $hashref->{player_id};
	# run the table
	my $table_run = calculate_table_run($hashref->{player_id});
	$sorted_score_data[$i][8] = $table_run;
            $i++;
}

my $zeroes = "select * from player_info where man_or_chimp = \"chimp\" order by name";
my $zilch_ref = multi_row_query($zeroes);
for my $ref (@$zilch_ref) {
	my $name = $ref->{name};
	next if $names{$name};
            $sorted_score_data[$i][0] = 0;
        $sorted_score_data[$i][1] = $name;
            # candybar
            $sorted_score_data[$i][2] = $ref->{candybar};
            # gender
            $sorted_score_data[$i][3] = "placeholder";
            # location
            $sorted_score_data[$i][4] = $ref->{location};
	if ($ref->{location} eq "") {
		$sorted_score_data[$i][4] = "--";
	}
            # champion
            $sorted_score_data[$i][5] = $ref->{champion};
            # j factor
            $sorted_score_data[$i][6] = $ref->{j2_factor};
            # player_id
            $sorted_score_data[$i][7] = $ref->{player_id};
	# run the table
	my $table_run = calculate_table_run($ref->{player_id});
	$sorted_score_data[$i][8] = $table_run;
            $i++;
}
	
open (SCORES, ">$data_dir/jq_chimp_scores.txt") or die "can't open jq_scores.txt: $!";

my $previous = 1;
my $place;

for $j (0..$#sorted_score_data) {
	my $k = $j - 1;
	if ($sorted_score_data[$j][0] == $sorted_score_data[$k][0]) {
		$place = $previous;
	} else {
		$place = $j + 1;
		$previous = $place;
	}
	print SCORES "$place\t";
   for $i (0..8) {
      print SCORES "$sorted_score_data[$j][$i]";
	if ($i < 8) {
		print SCORES "\t";
	} else {
		print SCORES "\n";
	}
   }
}
close (SCORES);
chmod 0777, "$data_dir/jq_chimp_scores.txt" or warn "couldn't chmod jq_scores.txt: $!";

open(FOREMAIL,">$data_dir/top10_chimps.txt") or warn "can't open top10_chimps.txt: $!";
$place = 1;
for $j (0..$#sorted_score_data) {
$y = $j -1;
$z = $j +1;

   if ($sorted_score_data[$y][0] != $sorted_score_data[$j][0]) {
       $place = $z;
   }
      
  if ($place > 10) {
      last;
  }
    print FOREMAIL "$place.\t";
    foreach $k ("1","4", "2", "5", "0") {
        print FOREMAIL "$sorted_score_data[$j][$k]\t";
    }
   print FOREMAIL "\n";
}
close(FOREMAIL);
chmod 0777, "$data_dir/top10_chimps.txt" or warn "couldn't chmod top10_chimps.txt: $!";

open(WRITE,">$data_dir/top10_chimps_abbr.txt") or warn "can't write top10_chimps_abbr.txt: $!";
$place = 1;

for $j (0..$#sorted_score_data) {

$y = $j -1;
$z = $j +1;

#  ($score, $name, $candybar, $gender, $location, $champion, $player_id) = split /\t/, $sorted[$j];
   if ($sorted_score_data[$y][0] != $sorted_score_data[$j][0]) {
       $place = $z;
   }

  if ($place > 10) {
      last;
  }
    print WRITE "$place.\t";
    foreach $k ("1","2", "0") {
        print WRITE "$sorted_score_data[$j][$k]\t";
    }
   print WRITE "\n";


}
close(WRITE);
chmod 0777, "$data_dir/top10_chimps_abbr.txt" or warn "can't do that: $!";

# make histogram of scores
open (PROG, "/usr/bin/perl histogram.pl \"chimp\"|") or die "couldn't do it: $!";
    while (<PROG>) {
          print;
     }
close(PROG);



##########################################

sub calculate_table_run {
	my $player_id = shift;
	my %picks;
	my %losers;
	my $run_the_table;

	my $player_sql = "select * from picks where player_id=\"$player_id\"";
	my $player_ref = multi_row_query($player_sql);

	for (@$player_ref) {
		my $game = $_->{'game'};
		$picks{$game} = $_->{'winner'};
	}
	

	for (1..63) {

		my $game = "game_" . $_;
		# compare %picks to %winners

       	  # is there a winner and does it match the player's pick?
       	  if ($winners{$game} ne "foo" && $picks{$game} ne $winners{$game} ) {
		my $team = $picks{$game};
		$losers{$team} = 1;
       	  }
     
		$run_the_table += $point_values{$game};
		# does winner match something already found as a loser??
		for my $loser (keys %losers) {
			my $this_pick = $picks{$game};
			if ($losers{$this_pick}) {
				$run_the_table = $run_the_table - $point_values{$game};
                   		last;
			}
               }
	}
	return $run_the_table;
}

