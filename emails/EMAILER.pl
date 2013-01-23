#!/usr/bin/perl

#use strict;
use DBI;	# perl DBI module
use Mail::Mailer; # 
use Data::Dump;

use vars qw/$dbh/;
do "/data/cgi-bin/jq_globals.pl";

$ENV{'MAILADDRESS'} = 'jqmcbp@gmail.com';
$ENV{'XMAILER'} = 'benmail 1.0';
$ENV{'MAILER'} = 'benmail 1.0';
$| = 1;

my @player_info;

die "usage: ./EMAILER.pl file subject" unless -e $ARGV[0] && $ARGV[1];

my $send_all = "y";

$send_all = $ARGV[2] || '?';
my ($file, $subject) = ($ARGV[0], $ARGV[1]);

if ($send_all ne "n" && $send_all ne "y") {
	print "TO EVERYONE (y/n)? ";
	$send_all = read_choice();
	die "yes or no" unless $send_all eq "y" || $send_all eq "n";
}

my $bracket_info;
open(BRACKET,"<bracket_info");
while(<BRACKET>) {
	$bracket_info .= $_;
}
close(BRACKET);


my $link_info;
open(LINK,"<link_info");
while(<LINK>) {
	$link_info .= $_;
}
close(LINK);

my $message;
open(EMAIL,"<$file") or die "couldn't open $file: $!";

while(<EMAIL>) {
	$message .= $_;
}
close(EMAIL);

connect_to_db();
my $player_info;
my $high_score = get_high_score();
my $step = get_step();
my $player_pool_size = get_player_pool_size('man');

if ($ARGV[2] =~ /@/) {
	$player_info = get_player_and_score_info($step, $ARGV[2]);
	@player_info = @$player_info;
	my @extras = (
		);
	unshift @player_info, @extras;
} elsif ($send_all eq "n") {
	$player_info = get_player_and_score_info($step, 'ben@benklaas.com');
	my @extras = (
#			{'email'   => 'mcstayinskool@yahoo.com'},
			#{'email'   => 'mcstayinskool@gmail.com'},
#			{'email'   => 'jqmcbp@gmail.com'},
		);
	@player_info = @$player_info;
	unshift @player_info, @extras;
} else {
	$player_info = get_player_and_score_info($step);
	@player_info = @$player_info;
	unshift @player_info, @extras;
}

$dbh->disconnect();
my %omit;

$omit{'lucky@bananas.net'}++;

for (@player_info) {

	next if $_->{'man_or_chimp'} eq 'chimp';
	my $email = $_->{'email'};
	if ($omit{$email}) {
		print "SKIPPING $email\n";
		next;
	}
	my $this_message = $bracket_info . $message . "\n" . $link_info;
	#my $this_message = $bracket_info . $message . "\n";
	#my $this_message = $message . "\n" . $link_info;
	$_->{'darwin'} = '0' unless $_->{'darwin'};
	$_->{'score'} = '0' unless $_->{'score'};
	$_->{'rank'} = '0' unless $_->{'rank'};
	$this_message =~ s/NAME/$_->{'pi_name'}/g;
	$this_message =~ s/CANDYBAR/$_->{'candybar'}/g;
	$this_message =~ s/DARWIN/$_->{'darwin'} chimp(s) have as many or more points as you/g;
	$this_message =~ s/SCORE/$_->{'score'}/g;
	$this_message =~ s/LEADER/$high_score/g;
	$this_message =~ s/RANK/$_->{'rank'}/g;
	$this_message =~ s/POOL_SIZE/$player_pool_size/g;
	if ($_->{'pi_id'}) {
	$this_message =~ s/PLAYERID/$_->{'pi_id'}/g;
	} else {
	$this_message =~ s/PLAYERID/winners/g;
	}
	print "Mailing to $_->{'email'} -----> ";
	open(OUT,">mail.out") or die "$!";
	print OUT $this_message;
	close(OUT) or die "$!";
	send_email($_->{'email'}, $_->{'name'}, $subject);
	print "DONE\n";
	sleep 2;
		
}


sub send_email {

	my $email = shift;
	my $name = shift;
	my $subject = shift;

        my $cmd =  "/home/bklaas/bin/mailsend -smtp smtp.comcast.net -port 587 -t '$email' -f 'jqmcbp\@gmail.com' -sub '$subject' -starttls -auth -user wvolkman -pass roofclip -attach mail.out,text/plain,i";
#	print $cmd . "\n"; 
	open(CMD, "$cmd |") or die "$!";
	while (<CMD>) { print; }
	close(CMD);

}

sub read_choice {
	my $input = <STDIN>;
	chomp($input);
	return $input;

}

