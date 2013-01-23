sub send_email {

	my $message = "Ben's PingBot wants to inform you of the following shipments: \n\n";
	for my $package (@shipments) {
		$message .= "$package\n";
	}
	$message .= "\nhttp://benklaas.com/precious_moments/\ncheers,\nBen's PingBot\n";

	my $file = '/tmp/foo.txt';
	open(FILE, ">$file");
	print FILE $message;
	close(FILE);

	#my $to = 'ben@benklaas.com,mcstayinskool@yahoo.com';
	my $to = 'lancev@ping.com,jeremyw@pinggolf.com,ben@benklaas.com';
	my $cmd =  "/home/bklaas/bin/mailsend -smtp smtp.gmail.com -port 587 -t $to -f 'ben\@benklaas.com' -sub 'Shipment' -starttls -auth -user 'ben\@benklaas.com' -pass bk9711bk < $file";
	`$cmd`;
	unlink($file);

}

