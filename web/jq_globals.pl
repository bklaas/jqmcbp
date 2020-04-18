sub config_variables {

	my @time = localtime();
	my $year = sprintf("%04d", $time[5] + 1900);
	my %return =
	(	
	"year"	=>	$year,
	"template_dir"	=>	"/home/bklaas/jqmcbp/web/$year/templates",
	);
	return \%return;

}

sub connect_to_db {
    ###############################################################
    ############### connect to database ###########################
    ###############################################################
    my $database_name = shift || "johnnyquest";
    my $location = "localhost";
    my $port_num = "3306";
    my $database = "DBI:mysql:$database_name:$location:$port_num";
    #my $db_user = "nobody";
    my $db_user = "root";
    my $pass = "hoopoe";

    $dbh = DBI->connect($database,$db_user,$pass) or die $DBI::errstr;
    ###############################################################
}

sub single_row_query {

	#
	# takes an arbitrary SQL query that will return a single row in and returns a hash reference 
	# with keys the field names and the data as the values
	#
	# this is identical to multi_row_query except instead of a 1-element array of a single hash reference,
	# it simplifies to just a hash
	my $query = shift;
	my %return;
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $ref = $sth->{NAME};
	my @array = @$ref;
	while (my $hashref = $sth->fetchrow_hashref()) {
		for (@array) {
			$return{$_} = $hashref->{$_};
		}
	}
	$sth->finish;
	my $return = \%return;
	return $return;

}

sub multi_row_query {

	# takes an arbitrary SQL query in and returns a LoH (array of hashes) array reference
	# with each return row from MySQL an element in the array
	# and each element a hash reference to data from the the table with the field name as the key and the data as the value
	my $query = shift;
	my @return;
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $ref = $sth->{NAME};
	my @array = @$ref;
	my $i = 0;
	while (my $hashref = $sth->fetchrow_hashref()) {
		for (@array) {
			$return[$i]{$_} = $hashref->{$_};
		}
		$i++;
	}
	$sth->finish;
	my $return = \@return;
	return $return;
}

sub get_bracket_order {

	my @return;
	open(BRACKETS,"</data/benklaas.com/jqmcbp/brackets.order");
	while(<BRACKETS>) {
		chomp;
		push @return, $_;
	}
	return @return;
}

sub get_teams {

	# returns an arrayref of hashrefs similar to what multi_row_query does
	# elements are ordered by bracket order first, then by team_id
	# bracket order is defined in /data/benklaas.com/jqmcbp/brackets.order
	my @brackets = @_;
	my @return;
	for (@brackets) {
		my $query = "select * from teams where bracket_name = \"$_\" order by team_id";
		my $ref = multi_row_query($query);
		for (@$ref) {
			$_->{'team'} =~ s/'//g;
			push @return, $_;
		}
	}
	return \@return;
}

sub get_teams_allinfo {

	# returns an hashref of hashrefs similar to what multi_row_query does
	# elements are ordered by bracket order first, then by team_id
	# bracket order is defined in /data/benklaas.com/jqmcbp/brackets.order
	my @brackets = @_;
	my @return;
	for (@brackets) {
		my $query = "select * from teams where bracket_name = \"$_\" order by team_id";
		my $ref = multi_row_query($query);
        for my $row (@$ref) {
        	$row->{'team'} =~ s/'//g;
            push @return, $row;
        }
	}
	return \@return;
}


sub log_to_file {
	my @message = @_;
	open(LOG,">>/tmp/jq.debug");
	for (@message) {
		print LOG $_ . "\n";
	}
	close(LOG);
}

sub get_last_updated {
	my $last_updated = "select * from last_updated";
	my $ref = single_row_query($last_updated);
	return $ref->{'last_updated'};
}
sub print_last_updated {

	my $last_updated = "select * from last_updated";
	my $ref = single_row_query($last_updated);
	print "$ref->{'last_updated'}";
}

sub get_player_info {

	# returns hashref for single player data
	# returns arrayref for all player data
	my $id;
	$id = shift if $_[0];
	my $query = "select * from player_info";
	my $return;
	if ($id) {
		$query .= " where player_id = '$id'";
		$return = single_row_query($query);
	} else {
		$return = multi_row_query($query);
	}
	return $return;
}

sub get_player_and_score_info {

	my $step = shift;
	my $id;
	$id = shift if $_[0];
	my $query = "select scores.*, player_info.email, player_info.man_or_chimp, player_info.player_id as pi_id, player_info.name as pi_name, player_info.candybar from player_info left join scores on player_info.player_id = scores.player_id and scores.step = \"$step\" ";
	if ($id) {
		$query .= " where player_info.email = '$id'";
	} else {
		$query .= " where player_info.man_or_chimp = 'man'";
	}
	#print "$query\n"; exit;
	my $return = multi_row_query($query);
	return $return;
}

sub get_step {
	my $q = 'select step from scores order by step desc limit 1';
	my $ref = single_row_query($q);
	my $return = 0;
	$return = $ref->{'step'} if $ref->{'step'};
	return $return;
}

sub get_high_score {
	#find out high score
	my $query = "select score from scores order by score desc, step desc limit 1";
	my $ref = single_row_query($query);
	my $high_score = $ref->{'score'};
	$high_score = '0' unless $ref->{'score'};
	return $high_score;
}

sub get_player_pool_size {
	my $man_or_chimp = shift;
	my $query;
	if ($man_or_chimp eq 'man' || $man_or_chimp eq 'chimp' ) {
		$query = "select count(*) as count from player_info where man_or_chimp = \"$man_or_chimp\"";
	} else {
		$query = "select count(*) as count from player_info";
	}
	my $ref = single_row_query($query);
	return $ref->{'count'};
}
sub print_filter_menu {
        my $selected = shift;
        my $filter_ref = shift;
        print "<select name=\"filter\">\n";
        if ($selected eq "none") {
                print "<option value=\"\" SELECTED>none\n";
        } else {
                print "<option value=\"\">\n";
        }
        for (@$filter_ref) {
                if ($_->{'filter_id'} == $selected) {
                        print "<option value = \"$_->{'filter_id'}\" SELECTED>$_->{'name'}\n";
                } else {
                        print "<option value = \"$_->{'filter_id'}\">$_->{'name'}\n";
                }
        }
        print "</select>\n";
}
                                                                                                            
sub get_filter_info {
                                                                                                            
        my $return = multi_row_query("select * from filter order by name");
        return $return;
}
                                                                                                            
sub get_filter_ids {
                                                                                                            
        my $id = shift;
        my $return = multi_row_query("select * from filter_link where filter_id = \"$id\"");
        my %ids;
        for (@$return) {
                my $id = $_->{'player_id'};
                $ids{$id} = 1;
        }
        return \%ids;
}

sub print_number_images {
	my @num_strings = @_;
	for (@num_strings) {
		my $img_name = $_ . "BRSD.GIF";
		#my $img_name = $_ . "SBR.GIF";
		print "<img src = \"/jqmcbp/images/$img_name\">\n";
	}
}

sub grab_names {
	my $query = "select name, player_id from player_info where man_or_chimp = \"man\" order by name";
        my $aref = multi_row_query($query);
	return $aref;
}

sub thisIsMe {
        my $id = shift;
        my $q = "select * from player_info, scores where player_info.player_id = scores.player_id and player_info.player_id = \"$id\" order by step desc limit 1";
        my $ref = single_row_query($q);
        return $ref;
}
sub getSimilarities {
        my $id = shift;
        my %return;
        my $q = "select * from similarity_index where first_player_id = \"$id\"";
        my $aref = multi_row_query($q);
        for my $href (@$aref) {
            my $other_id = $href->{'second_player_id'};
            $return{$other_id} = $href;
       }
       $q = "select * from similarity_index where second_player_id = \"$id\"";
       $aref = multi_row_query($q);
       for my $href (@$aref) {
			my $other_id = $href->{'first_player_id'};
			$return{$other_id} = $href;
       }
       return \%return;
}

# identical to single_row_query() except pulls in a statement handle and wildcard values instead of a raw query
sub srq {
        my $sth = shift;
        my @values = @_;
        my %return;
        $sth->execute(@values) or warn "Couldn't execute query (srq)\n@values\n$DBI::ERRSTR";
        my $ref = $sth->{NAME};
        my @array = @$ref;
        while (my $hashref = $sth->fetchrow_hashref()) {
                for (@array) {
                        $return{$_} = $hashref->{$_};
                }
        }
        $sth->finish;
        return \%return;
}

# identical to multi_row_query except pulls in a statement handle and wildcard entries instead of a raw query
sub mrq {
        my $sth = shift;
        my @values = @_;
        my @return;
        $sth->execute(@values) or warn "Couldn't execute (mrq) query\n\n$DBI::ERRSTR";
        my $ref = $sth->{NAME};
        my @array = @$ref;
        my $i = 0;
        while (my $hashref = $sth->fetchrow_hashref()) {
                for (@array) {
                        $return[$i]{$_} = $hashref->{$_};
                }
                $i++;
        }
        $sth->finish;
        my $return = \@return;
        return $return;
}

sub print_links {

	my $tm = "&#0153;";
	print "<div id = 'leftcontent'>\n";
	print "<h3 class = 'links'>Links</h3>\n";
	print "<a href = '/cgi-bin/leaderboard.cgi'>Leaderboard</a>\n";
	print "<a href = '/cgi-bin/player_bracket_selection.cgi'>Prognosticationland$tm</a>\n";
	print "<a href = '/cgi-bin/graphomatic.cgi'>Graphomatic$tm</a>\n";
	print "<a href = '/cgi-bin/whatsyourj.cgi'>Your \"J\" Factor$tm</a>\n";
	print "<a href = '/cgi-bin/filtermatic.cgi'>Filtermatic$tm</a>\n";
	print "<a href = '/cgi-bin/hallofshame.cgi'>Hall of Shame$tm</a>\n";
	print "</div>\n";
}


