#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

$| = 1;

if (@ARGV < 2 || $ARGV[0] !~ /^[0-9]+$/) {
	usage();
}

my $max_filesize = shift @ARGV;
my $return = 0;
my $success = 0;
foreach (@ARGV) {
	if (-f $_) {
		my $result = span_ics($_);
		if ($result == 0) {
			$success++;
		} else {
			$return++;
		}
	} else {
		print "$_ is not a file\n";
		$return++;
	}
}
print { $return ? *STDERR : *STDOUT } $success + $return . " files processed, $success successful, $return errors.\n";
exit $return;

############################################

sub span_ics {
	my $error = 0;
	
	my %calendar = (
		head	=> [],
		events	=> [],
		foot	=> [],
	);

	my $inputfile = $_[0];
	my $fh;
	local $/ = "\x0d\x0a";
	open($fh, "<", $inputfile) or die ("File $inputfile not found.\n");

	local $\ = "\x0a"; #Set newlines after print
	print "Beginning parsing of $inputfile";
	my $is = 0; # InputStatus: 0 begin, 1 head, 2 in event, 3 end event, 4 end calendar
	my $en = 0; # Event number
	while (<$fh>) {
		chomp;
		if ($is == 0 && $_ =~ /^BEGIN:VCALENDAR$/) {
			$is++;
			push @{ $calendar{"head"} }, $_;
			#print "$.: Begin VCALENDAR";
		} elsif ($is == 1) {
			if ($_ =~ /^BEGIN:VEVENT$|^BEGIN:VTODO$/) {
				$is++;
				push @{ $calendar{"events"} }, [ $_ ];
				#print "$.: First VEVENT";
			} else {
				push @{ $calendar{"head"} }, $_;
			}
		} elsif ($is == 2) {
			if ($_ =~ /^END:VEVENT$|^END:VTODO$/) {
				$is++;
			}
			# pushes onto the array that is at the largest index of events array
			push @{ $calendar{"events"}[-1] }, $_;
		} elsif ($is == 3) {
			if ($_ =~ /^BEGIN:VEVENT$|^BEGIN:VTODO$/) {
				$is--;
				push @{ $calendar{"events"} }, [ $_ ];
				#print "$.: New VEVENT";
			} elsif ($_ =~ /^END:VCALENDAR$/) {
				$is++;
				push @{ $calendar{"foot"} }, $_;
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
		} else {
			print "$.: Something went wrong. Unknown input status or invalid file content.";
			$error++;
			last;
		}
	}
	close $fh;
	print Dumper(\%calendar);
	return $error;
};

sub usage {
	print "Usages: ics-spanner.pl <filesize_in_Kb> <ICS_file(s)>\n";
	exit 0;
};

