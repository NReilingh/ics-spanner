#!/usr/bin/env perl

use strict;
use warnings;
use Encode;

$| = 1;

if (@ARGV < 2 || $ARGV[0] !~ /^[0-9]+$/) {
	usage();
}

my $max_filesize_kb = shift @ARGV;
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
print { $return ? *STDERR : *STDOUT } $success + $return . " files processed, $success successful, $return error(s).\n";
exit $return;

############################################

sub write_files {
	my $filename = $_[0];
	my $cal_ref = $_[1];

	(my $outputdirname = $filename) =~ s/\.ics$//;
	mkdir $outputdirname;
	
	my $filecount = 0;
	my $fh;

	local $\ = "\x0d\x0a"; # User CRLFs to join text and write after prints.
	my $filehead = encode('UTF-8', join($\, @{ $cal_ref->{"head"} }));
	my $filefoot = encode('UTF-8', join($\, @{ $cal_ref->{"foot"} }));

	my $file_base_bytes = length($filehead) + length($filefoot);

	my $max_file_bytes = $max_filesize_kb * 1024;

	#if ($max_filesize_bytes < $filehead_bytes) {
		#print "$filename header is " . sprintf("%.2f", $filehead_bytes / 1024) . "KB, too big for output size of $max_filesize_kb" . "KB";
		#return 1;
	#}
	local $, = $\;
	my $file_bytes = $file_base_bytes;
	my $new_file = 1;
	my $newfile = sub {
		$filecount++;
		open($fh, ">>", $outputdirname . "/" . $filecount . ".ics");
		$file_bytes = $file_base_bytes;
	};
	my @cal_events = @{ $cal_ref->{"events"} };
	foreach my $event (@cal_events) {
		my $event_octets = encode('UTF-8', join($\, @{ $event }));
		$file_bytes += length($event_octets);
		if ($new_file == 1) {
			if ($file_bytes > $max_file_bytes) {
				print "$filename contains events too large for max filesize. Try " . sprintf("%.2f", $file_bytes / 1024) . "KB or larger.";
				return 1;
			}
			&$newfile();
			print $fh $filehead, $event_octets;
			$new_file = 0;
		} elsif ($file_bytes > $max_file_bytes) {
			print $fh $filefoot;
			close $fh;
			&$newfile();
			$file_bytes += length($event_octets);
			if ($file_bytes > $max_file_bytes) {
				print "$filename contains events too large for max filesize. Try " . sprintf("%.2f", $file_bytes / 1024) . "KB or larger.";
				return 1;
			};
			print $fh $filehead, $event_octets;
		} else {
			print $fh $event_octets;
		}
	}
	print $fh $filefoot;
	close $fh;
	return 0;
};

sub span_ics {
	my $error = 0;
	
	# Hash of Arrays. events is an array of arrays.
	my %calendar = (
		head	=> [],
		events	=> [],
		foot	=> [],
	);

	my $inputfile = $_[0];
	my $fh;
	local $/ = "\x0d\x0a";
	open($fh, "<:encoding(UTF-8)", $inputfile) or die ("File $inputfile not found.\n");

	local $\ = "\x0a"; #Set newlines after print
	print "Beginning parsing of $inputfile";
	my $is = 0; # InputStatus: 0 begin, 1 head, 2 in event, 3 end event, 4 end calendar
	my $en = 0; # Event number
	while (<$fh>) {
		chomp;
		if ($is == 0 && $_ =~ /^BEGIN:VCALENDAR$/) {
			$is++;
			push @{ $calendar{"head"} }, $_;
		} elsif ($is == 1) {
			if ($_ =~ /^BEGIN:VEVENT$|^BEGIN:VTODO$/) {
				$is++;
				push @{ $calendar{"events"} }, [ $_ ];
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
			} elsif ($_ =~ /^END:VCALENDAR$/) {
				$is++;
				push @{ $calendar{"foot"} }, $_;
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
	$error += write_files($inputfile, \%calendar);
	return $error;
};

sub usage {
	print "Usage: ics-spanner.pl <filesize_in_Kb> <ICS_file(s)>\n";
	exit 0;
};

