#!/usr/bin/env perl

use strict;
use warnings;

$| = 1;
my $calendarpattern = qr/(^BEGIN:VCALENDAR\r\n.+?)((?:^BEGIN:VEVENT\r\n.+?^END:VEVENT\r\n)+)(^END:VCALENDAR)(?:\r\n)*/ms;

if (@ARGV < 1) {
	usage();
}

my $return = 0;
foreach (@ARGV) {
	$return += validcalendar($_);
}
exit $return;

############################################

sub validcalendar {
	my $inputfile = @_[0];

	local $/; #slurp mode.
	open(INPUT, $inputfile) or die ("File $inputfile not found.\n");
	my $calendarfile = <INPUT>;
	close INPUT;

	if ($calendarfile =~ /$calendarpattern/) {
		print "$inputfile looks like a valid calendar file!\n";
		return 0;
	} else {
		print "Something is awry with $inputfile.\n";
		return 1;
	}
};

sub usage {
	print "Supply one or more ICS files as command line arguments.\n";
	exit;
};

