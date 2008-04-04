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
# This script diggs through the hermes database and sends the due
# messages, sleeping again for a short time. 

use strict qw 'vars';
use Getopt::Std;
use Hermes::MessageSender;
use SDBM_File;
use Time::HiRes qw( gettimeofday tv_interval );
use Fcntl;

use vars qw ( $opt_h $opt_s $opt_d $opt_w $opt_t );


sub usage()
{
  print "Usage!";
}

# ---------------------------------------------------------------------------

# Process the commandline arguments.
getopts('w:dhst:');

usage() if ($opt_h );

my $silent = 0;
$silent = 1 if( $opt_s );

my $debug = 0;
$debug = 1 if( $opt_d );

# Handle optional 'type' parameter, if it's available.
my $type;
$type = $opt_t if( $opt_t );

# Sending time for daily digests, defaults to midnight
my $dailyHour = $Hermes::Config::DailySendHour || 0;
my $dailyMin  = $Hermes::Config::DailySendHourMinute || 0;

my $timerfile = "workertimes";
my %times;

tie( %times, SDBM_File, $timerfile, O_RDWR|O_CREAT, 0644 ) || die "Cannot open timer file $timerfile\n";

for my $step ( ('minute', 'hour', 'week', 'month') ) {
    $times{ $step } = 0 unless( exists $times{ $step } );
}

my $workerdelay = $opt_w || 10;

my ($t0, $elapsed);
my $cnt;

while( 1 ) {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    # First, send out the messages that were marked with sendImmediately.
    $t0 = [gettimeofday];
    $cnt = sendImmediateMessages();
    $elapsed = tv_interval ($t0);
    print "Sent due messages: $cnt in $elapsed sec.\n";
    
    # send minute digests if $sec >= 0 AND $sec < $workerdelay
    if( $sec >= 0 && $sec < $workerdelay ) {
	
	$t0 = [gettimeofday];
	$cnt = sendMessageDigest( SendMinutely );
	$elapsed = tv_interval( $t0 );
	print "Sent Minute digest at <$min/$sec>: $cnt in $elapsed sec.\n";

	if( $min == 0 ) {
	    print "Send Hour digest at <$hour/$min/$sec>\n";
	    $t0 = [gettimeofday];
	    $cnt = sendMessageDigest( SendHourly );
	    $elapsed = tv_interval($t0);
	    print "Sent Minute digest at <$min/$sec>: $cnt in $elapsed sec.\n";

	}

	if( $hour == $dailyHour && $min == $dailyMin ) {
	    $t0 = [gettimeofday];
	    $cnt = sendMessageDigest( SendDaily );
	    $elapsed = tv_interval($t0);
	    print "Send Daily Digest at <$hour/$min/$sec>: $cnt in $elapsed sec.\n";
	}
    }

    print "* Now sleeping for $workerdelay seconds\n";
    sleep( $workerdelay );
}

untie %times;
