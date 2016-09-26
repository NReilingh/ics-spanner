# ics-spanner

Usage: ics-spanner.pl <size-limit-in-KB> <input-file(s)>

This script will process ICS files into folders of one or more smaller files that are each no larger than the supplied size limit in KB. Calendar-wide properties will be replicated in each file, but each event in the input ICS will only be written to one output file. In this way, all of the files in the output folder can be imported to the same destination (like a Google Calendar) such that they will merge together to reconstitute the original input ICS.

This technique is required to get around Google Calendar's file size limit on imports.
