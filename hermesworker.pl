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

use strict;
use Getopt::Std;

use Hermes::MessageSender;
use Hermes::Message;
use SDBM_File;
use Time::HiRes qw( gettimeofday tv_interval );
use Fcntl;
use Hermes::Log;
use vars qw ( $opt_h $opt_s $opt_d $opt_w $opt_t $opt_o $opt_m );


sub usage()
{
  print<<END

  hermesworker.pl

  Script to send out all kinds of hermes messages.

  -o:  send only immediate messages once and stop after that
  -m:  send only minute digests and stop after that
  -h:  help text
  -d:  switch on debug
END
;
  exit;
}

# ---------------------------------------------------------------------------

# Process the commandline arguments.
getopts('omw:dhst:');

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

# tie( %times, SDBM_File, $timerfile, O_RDWR|O_CREAT, 0644 ) || die "Cannot open timer file $timerfile\n";

for my $step ( ('minute', 'hour', 'week', 'month') ) {
    $times{ $step } = 0 unless( exists $times{ $step } );
}

my $workerdelay = $opt_w || 10;

my ($t0, $elapsed);
my $cnt;

if( $opt_m ) {
    $cnt = 0+sendMessageDigest( SendMinutely() );
    print "Sent $cnt messages (minute digests)\n";
    for( my $i = 0; $i < 20; $i++ ) {
	log( 'info', "Filler $i" );
    }
    exit;
}

while( 1 ) {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    # First, send out the messages that were marked with sendImmediately.
    $t0 = [gettimeofday];
    $cnt = sendImmediateMessages();
    $elapsed = tv_interval ($t0);
    log 'info', "Sent due messages: $cnt in $elapsed sec.\n";
    print "Sent immediate due messages: $cnt in $elapsed sec.\n";
    
    exit if( $opt_o );

    # send minute digests if $sec >= 0 AND $sec < $workerdelay
    if( $sec >= 0 && $sec < $workerdelay ) {
	
	$t0 = [gettimeofday];
	$cnt = sendMessageDigest( SendMinutely() );
	$elapsed = tv_interval( $t0 );
	log 'info', "Sent Minute digest at <$min/$sec>: $cnt in $elapsed sec.";
	print "Sent Minute digest at <$min/$sec>: $cnt in $elapsed sec.\n";

	if( $min == 0 ) {
	    log 'info', "Send Hour digest at <$hour/$min/$sec>\n";
	    $t0 = [gettimeofday];
	    $cnt = sendMessageDigest( SendHourly() );
	    $elapsed = tv_interval($t0);
	    log 'info', "Sent Minute digest at <$min/$sec>: $cnt in $elapsed sec.";
	    print "Sent Minute digest at <$min/$sec>: $cnt in $elapsed sec.\n";

	}

	if( $hour == $dailyHour && $min == $dailyMin ) {
	    $t0 = [gettimeofday];
	    $cnt = sendMessageDigest( SendDaily() );
	    $elapsed = tv_interval($t0);
	    log 'info', "Send Daily Digest at <$hour/$min/$sec>: $cnt in $elapsed sec.";
	    print "Send Daily Digest at <$hour/$min/$sec>: $cnt in $elapsed sec.\n";
	}
    }

    print "* Now sleeping for $workerdelay seconds\n";
    log( 'info', "Sleeping for $workerdelay seconds" );
    sleep( $workerdelay );
}

untie %times;
