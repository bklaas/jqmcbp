#!/usr/bin/perl

use DBI;             # perl DBI module
use DBD::mysql;      # perl module for mySQL interface
use Mail::Mailer;    #
use strict;

$ENV{'MAILADDRESS'} = 'jqmcbp@gmail.com';
$ENV{'XMAILER'}     = 'benmail 1.0';
$ENV{'MAILER'}      = 'benmail 1.0';
$|                  = 1;

use vars qw/$dbh/;
do "/etc/httpd/cgi-bin/jq_globals.pl";

die "usage: ./invite_emailer.pl file subject" unless $ARGV[1];
my $file         = $ARGV[0];
my $title_string = $ARGV[1];

my $player_info = get_emails();
#my $player_info;
#$player_info->{'ben@benklaas.com'}++;

my $i = 0;
for my $email ( sort keys %$player_info ) {
    print "Mailing to $email -----> ";
    send_email($email);
    print "DONE\n";
    $i++;
}
print "$i\n";

sub get_emails {

    my %return;
    open( LIST, "<2009emails.txt" );
    while (<LIST>) {
	chomp;
        my @ary = split /\t/;
        $return{ $ary[0] }++ if $ary[0] =~ /@/;
    }
    close(LIST);
    return \%return;
}

sub send_email {

    my $email = shift;

        my $cmd =  "/home/bklaas/bin/mailsend -smtp smtp.comcast.net -port 587 -t '$email' -f 'jqmcbp\@gmail.com' -sub '$title_string' -starttls -auth -user wvolkman -pass roofclip < $file";
#	my $cmd =  "/home/bklaas/bin/mailsend -smtp smtp.gmail.com -port 587 -t $email -f 'jqmcbp\@gmail.com' -sub '$title_string' -starttls -auth -user 'jqmcbp\@gmail.com' -pass bk9711bk < $file";

print "|$email|\n";

	open(CMD, "$cmd |");
	while(<CMD>) {
		print;
	}
	close(CMD);
	sleep 1;

}

