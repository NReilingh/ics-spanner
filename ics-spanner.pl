#!/usr/bin/env perl

use strict;
use warnings;

$| = 1;

my $file = 'test.ics';

open(INPUT, $file) or die ("File $file not found.\n");

# we want to store everything up until the first VEVENT
# then copy out VEVENTS until

sub main {
	my $text = 'The code for this device is FJ38327.';

	if ($text =~ /(\w{2}\d{2,6})\./) {
		print "Found code $1\n";
	} else {
		print "not found \n";
	}

};


main();

