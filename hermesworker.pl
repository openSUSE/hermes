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
use Hermes::DB;
use Hermes::Util;
# use Hermes::Delivery::Jabber;

use Time::HiRes qw( gettimeofday tv_interval );
use Hermes::Log;
use vars qw ( $opt_h $opt_c $opt_d $opt_t $opt_o $opt_m $gotTermSignal );

sub gotSignalTerm
{
  $gotTermSignal = 1;
}

sub usage()
{
  print<<END

  hermesworker.pl

  Script to send out all kinds of hermes messages. It has to run
  regularly started with the -o option or it runs forever in a loop.
  To stop it smoothly just send a TERM signal.

  -o:  send only immediate messages once and stop after that
  -m:  send only minute digests and stop after that
  -t:  database name as of the Config.pm file
  -h:  help text
  -d:  switch on debug
  -c:  give some output on console
END
;
  exit;
}

# ---------------------------------------------------------------------------

# Process the commandline arguments.
getopts('omdcht:');
setLogFileName('hermesworker');

usage() if ($opt_h );

connectDB( $opt_t );

$gotTermSignal = 0;
$SIG{TERM} = \&gotSignalTerm;

my $debug = 0;
if( $opt_d ) {
    $debug = 1;
    $Hermes::Config::Debug = 2;
}

if( $Hermes::Config::WorkerInitJabber ) {
    Hermes::Delivery::Jabber::initCommunication();
    Hermes::Delivery::Jabber::sendJabber( { subject => "Hello World", body => 'Hermes talks to you' } );
}

# Sending time for daily digests, defaults to midnight
my $dailyHour = $Hermes::Config::DailySendHour || 0;
my $dailyMin  = $Hermes::Config::DailySendHourMinute || 0;
my $weekDay   = $Hermes::Config::SendWeekDay || 0;

my $workerdelay = $opt_w || 10;

my ($t0, $elapsed);
my $cnt;

print "hermesworker started\n" if( $opt_c );

if( $opt_m ) {
    my $notificationIdsRef = sendMessageDigest( SendMinutely() );
    $cnt = @{$notificationIdsRef};

    print "Sent $cnt messages (minute digests)\n" if( $opt_c );
    foreach my $notiId ( @{$notificationIdsRef} ) {
	log('info', "Sent notification <$notiId>" );
    }

    if( $Hermes::Config::WorkerInitJabber ) {
	Hermes::Delivery::Jabber::quitCommunication();
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
    print "Sent immediate due messages: $cnt in $elapsed sec.\n" if( $opt_c );

    exit if( $opt_o );

    # lets have a check for new stuff every 15 seconds
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $interval = 0;
    $interval = 15-$sec if( $sec >=0 && $sec < 15 );
    $interval = 30-$sec if( $sec >=15 && $sec < 30 );
    $interval = 45-$sec if( $sec >=30 && $sec < 45 );
    $interval = 60-$sec if( $sec >=45 && $sec < 60 );

    log( 'info', "Sleeping for $interval seconds" );
    print "Now sleeping for $interval seconds, current second is $sec.\n" if( $opt_c );

    sleep( $interval );

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    if( 0+$sec >= 0 && 0+$sec < 10) {
	$t0 = [gettimeofday];
	my $notificationIdsRef = sendMessageDigest( SendMinutely() );
	$cnt = @{$notificationIdsRef};

	$elapsed = tv_interval( $t0 );
	log 'info', "nt <$min/$sec>: $cnt in $elapsed sec.";
	print "Sent Minute digest at <$min/$sec>: $cnt in $elapsed sec.\n" if( $opt_c );

	if( 0+$min == 0 ) {
	    log 'info', "Send Hour digest at <$hour/$min/$sec>\n";
	    $t0 = [gettimeofday];
	    my $notificationIdsRef = sendMessageDigest( SendHourly() );
	    $cnt = @{$notificationIdsRef};
	    $elapsed = tv_interval($t0);
	    log 'info', "Sent Hourly digest at <$min/$sec>: $cnt in $elapsed sec.";
	    print "Sent Hourly digest at <$min/$sec>: $cnt in $elapsed sec.\n" if( $opt_c );
	}

	if( 0+$hour == $dailyHour && 0+$min == $dailyMin ) {
	    $t0 = [gettimeofday];
	    my $notificationIdsRef = sendMessageDigest( SendDaily() );
	    $cnt = @{$notificationIdsRef};
	    $elapsed = tv_interval($t0);
	    log 'info', "Send Daily Digest at <$hour/$min/$sec>: $cnt in $elapsed sec.";
	    print "Send Daily Digest at <$hour/$min/$sec>: $cnt in $elapsed sec.\n" if( $opt_c );

	    if( 0+$weekDay == 0+$wday ) { # it's sunday and we send the weekly digest
	      $t0 = [gettimeofday];
	      $notificationIdsRef = sendMessageDigest( SendWeekly() );
	      $cnt = @{$notificationIdsRef};
	      $elapsed = tv_interval($t0);
	      log 'info', "Send Weekly Digest at <$hour/$min/$sec>: $cnt in $elapsed sec.";
	      print "Send Weekly Digest at <$hour/$min/$sec>: $cnt in $elapsed sec.\n" if( $opt_c );
	    }
	}
    }

    if( $gotTermSignal ) {
      log 'info', "Got the term signal, I go outta here...";
      print "## Got the term signal, I go outta here...\n" if( $opt_c );
      exit 0;
    }
    print "* Now sleeping for $workerdelay seconds\n";
    log( 'info', "Sleeping for $workerdelay seconds" );
    sleep( $workerdelay );
}

if( $Hermes::Config::WorkerInitJabber ) {
    Hermes::Delivery::Jabber::quitCommunication();
}
