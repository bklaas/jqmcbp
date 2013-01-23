#!/usr/bin/perl

# ben, consider this for 2003 JQMCBP emails...

use Net::SMTP;
$smtp = new Net::SMTP('mail1.occamnetworks.com');

$from = 'bklaas@occamnetworks.com';
$to = 'bklaas@occamnetworks.com';

$smtp->mail($from);
$smtp->to($to);

$smtp->data();
$smtp->datasend("Subject:  testing123\n");
$smtp->datasend("Your message");
$smtp->dataend();

$smtp->quit;


