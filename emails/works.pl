#!/usr/bin/perl

use Mail::Mailer; 
use strict;

#$ENV{'MAILADDRESS'} = 'ben@benklaas.com';
#$ENV{'XMAILER'} = 'benmail 1.0';
#$ENV{'MAILER'} = 'benmail 1.0';
$| = 1;

#send_email();

my $file = 'test_invite';
my $email = 'ben@benklaas.com';
$email = 'jqmcbp@gmail.com';
my $cmd =  "/home/bklaas/bin/mailsend -smtp smtp.gmail.com -port 587 -t 'ben\@benklaas.com' -f '$email' -sub 'Stuff & Things' -starttls -auth -user '$email' -pass SECUREPASS < $file";
`$cmd`;

sub send_email {

        use Net::SMTP::TLS;
        my $mailer = new Net::SMTP::TLS(
               'smtp.gmail.com',
               Hello   =>      'benklaas.com',
               Port    =>      587, 
               User    =>      'ben@benklaas.com',
               Password=>      'SECUREPASS',
		);
        $mailer->mail('ben@benklaas.com');
        $mailer->to('ben@benklaas.com');
        $mailer->subject('stuff and things');
        $mailer->data;
        $mailer->datasend("Sent thru TLS!");
        $mailer->dataend;
        $mailer->quit;

}
