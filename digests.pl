#!/usr/bin/perl -w
#
# Copyright (c) 2008 Klaas Freitag <freitag@suse.de>, Novell Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
################################################################
# Contributors:
#  Klaas Freitag <freitag@suse.de>
#
# This a cron job driven script to send message digests in the Hermes
# system.


use strict qw 'vars';
use Getopt::Std;
use Hermes::MessageSender;

use vars qw ($opt_f $opt_t $opt_s $opt_d $opt_h $opt_c);

# Process the commandline arguments.
getopts('f:t:sdhc');

usage() if ((defined $opt_h && $opt_h) || !(defined $opt_f || defined $opt_c));

my $silent = 0;
$silent = 1 if (defined $opt_s && $opt_s);

my $debug = 0;
$debug = 1 if (defined $opt_d && $opt_d);

# Handle optional 'type' parameter, if it's available.
my $type;
$type = $opt_t if (defined $opt_t && $opt_t);

# Validate the "frequency" parameter.
my $frequency;

if ($opt_f && $opt_f =~ /^\d+$/) {
    $frequency = $opt_f;
} elsif ($opt_f && $opt_f =~ /^SEND_/) {
    $frequency = &$opt_f;	# XXX: This will break with 'strict refs'.
} else {
    print "Invalid frequency: '$opt_f'\n";
    exit 1;
}

unless ($silent) {
    if (defined $type) {
	print STDERR "Starting digest run (frequency: $opt_f / type: $type).\n";
    } else {
	print STDERR "Starting digest run (frequency: $opt_f).\n";
    }
}

my $count = sendMessageDigest( $frequency, $type, $debug );

unless ($silent) {
    print STDERR "$count message digest(s) were processed.\n";
}

sub usage
{
    print<<EOF

digests.pl -f FREQUENCY [-t TYPE] [-h] [-d] [-c]

Processes pending messages digests in the Hermes system.

Options:
-f <freq>    digest frequency (SEND_HOURLY, SEND_DAILY, SEND_WEEKLY, SEND_MONTHLY)
-t <type>    restrict to this message type
-s           silent (no output)
-d           debugging mode (no mail will be sent)
-h           help (print this usage message)

EOF
    ;

    exit;
}
