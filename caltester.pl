#!/usr/bin/env perl

use strict;
use warnings;

$| = 1;

if (@ARGV < 1) {
	usage();
}

my $return = 0;
my $success = 0;
foreach (@ARGV) {
	my $result = validcalendar($_);
	if ($result == 0) {
		$success++;
	} else {
		$return++;
	}
}
print { $return ? *STDERR : *STDOUT } $success + $return . " files checked, $success valid, $return errors.\n";
exit $return;

############################################

# Doesn't actually validate the ICS file, just makes sure we know how to parse it.
# Assumes well-formedness.
sub validcalendar {
	my $inputfile = $_[0];
	my $input;
	my @calendarfile;
	my $error = 0;
	local $/ = "\x0d\x0a";
	open($input, "<", $inputfile) or die ("File $inputfile not found.\n");
	local $\ = "\x0a"; #Set newlines after print
	print "Beginning validation of $inputfile";
	my $is = 0; # InputStatus: 0 begin, 1 head, 2 in event, 3 end event, 4 end calendar
	while (<$input>) {
		chomp;
		if ($is == 0 && $_ =~ /^BEGIN:VCALENDAR$/) {
			$is++;
			#print "$.: Begin VCALENDAR";
		} elsif ($is == 1) {
			if ($_ =~ /^BEGIN:VEVENT$|^BEGIN:VTODO$/) {
				$is++;
				#print "$.: First VEVENT";
			} # else continue reading lines at this InputStatus.
		} elsif ($is == 2) {
			if ($_ =~ /^END:VEVENT$|^END:VTODO$/) {
				$is++;
			} # else continue reading lines at this InputStatus.
		} elsif ($is == 3) {
			if ($_ =~ /^BEGIN:VEVENT$|^BEGIN:VTODO$/) {
				$is--;
				#print "$.: New VEVENT";
			} elsif ($_ =~ /^END:VCALENDAR$/) {
				$is++;
				#print "$.: End VCALENDAR";
			} else {
				print "$.: Something doesn't look right. Exiting.";
				$error++;
				last;
			}
		} elsif ($is == 4) {
			if ($_ =~ /.+/) {
				print "$.: Trailing data for some reason. Exiting.";
				$error++;
				last;
			}
		}
	}
	close $input;
	return $error;
};

sub usage {
	print "Supply one or more ICS files as command line arguments.\n";
	exit;
};

