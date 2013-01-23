#!/usr/bin/perl


unless ($ARGV[0]) {
  die "specify path of data files on @ARGV please";
}

my $dirpath = $ARGV[0];
opendir(DIR,"$dirpath");
my %emails; my %names;

# iterate through data files
while (defined(my $datfile = readdir(DIR))) {

if ($datfile =~ /\.dat$/) {
	my ($timestamp, $email, @trash) = split /\./, $datfile;
	#print "DUPLICATE FOUND: $datfile...checking\n" if $emails{$email};
	$emails{$email}++;
	open(DAT,"<$dirpath/$datfile");
	while(<DAT>) {
		chomp;
		$names{$email}{$_}++ if /^name\|/;
		print "THIS IS A DUP-- $datfile\t$_\n" if $names{$email}{$_} > 1;
	}
	close(DAT);
}

}
closedir(DIR);
