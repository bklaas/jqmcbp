#!/usr/bin/perl

use DBI;	# perl DBI module
use DBD::mysql;	# perl module for mySQL interface
use Mail::Mailer; # 
use strict;

$ENV{'MAILADDRESS'} = 'jqmcbp@gmail.com';
$ENV{'XMAILER'} = 'benmail 1.0';
$ENV{'MAILER'} = 'benmail 1.0';
$| = 1;

use vars qw/$dbh/;
do "/data/cgi-bin/jq_globals.pl";

die "usage: ./batch_emailer.pl file subject" unless $ARGV[1];
my $file = $ARGV[0];
my $title_string = $ARGV[1];

my $player_info; 
#$player_info{'jqmcbp@gmail.com'}++;
#$player_info->{'ben@benklaas.com'}++;
$player_info->{'mcstayinskool@gmail.com'}++;

 for my $email (sort keys %$player_info) {
	print "Mailing to $email -----> ";
	send_email($email);
	print "DONE\n";
}

sub get_emails {

	my %return;
	open(LIST,"<invite_list.2007");
	while(<LIST>) {
		my @ary = split /\t/;
		$return{$ary[0]}++ if $ary[0] =~ /@/;
	}
	close(LIST);
	return \%return;
}

sub send_email {

	my $elem = shift;
	my $body_of_email; 
	my $todays_email;
	open(TODAY,"<$file") or die "$!";
	my $quit = 0;
	my $wrap_on = 1;
	while (<TODAY>) {
		$body_of_email .= $_;
	}
	close(TODAY);

open(LOG,">todays.email");
print LOG $body_of_email;
close(LOG);


	#my $mailer2 = new Mail::Mailer 'smtp', Server => 'smtp.gmail.com', port => '587' or die "$!";
if (0) {
	my $server = 'smtp.gmail.com';
	my $port = '587';
	my $debug = 1;
	#my $mailer2 = Mail::Mailer->new('smtp', Server => $server, Debug => $debug, Port => $port, Auth => 'TLS');
	my $mailer2 = Mail::Mailer->new('smtp', Server => $server, Debug => $debug, Port => $port);
	#my $mailer2 = new Mail::Mailer 'smtp', Server => 'smtp.comcast.net' or die "$!";
	my $email = $elem;
	print $mailer2 "STARTTLS\n";
	my %headers = (	"From"	=> "The Candymeister <jqmcbp\@gmail.com>",
		"To"	=> "$email",
		"Subject"	=> "$title_string",
		'Return-Path' => 'jqmcbp@gmail.com',
		'X-Clue'  => 'That Secret line in the Header',
		'X-Mailer'      => 'benmail 1.0',
		"Content-type"	=>	"text/plain\n\n");
	$mailer2->open(\%headers) or die "$!";
        print $mailer2 "$body_of_email\n" or die "$!";
        $mailer2->close(); 
}

        use Net::SMTP::TLS;
        my $mailer = new Net::SMTP::TLS(
               'smtp.gmail.com',
               Hello   =>      'benklaas.com',
               Port    =>      587, 
               User    =>      'jqmcbp',
               Password=>      'bk9711bk',
		);
        $mailer->mail('jqmcbp@gmail.com');
        $mailer->to('ben@benklaas.com');
        $mailer->data;
        $mailer->datasend("Sent thru TLS!");
        $mailer->dataend;
        $mailer->quit;

}
