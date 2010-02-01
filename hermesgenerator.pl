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
# This script diggs through the hermes database and generates messages
# from the raw notifications stored through herminator

use strict;
use Getopt::Std;
use Data::Dumper;

use Hermes::Log;
use Hermes::DB;
use Hermes::Message;
use Hermes::Proxy;

use Time::HiRes qw( gettimeofday tv_interval );

use vars qw ( $opt_h $opt_s $opt_l $opt_w $opt_o $opt_t $opt_p $gotTermSignal);


sub usage()
{
  print<<END

  hermesgenerator.pl

  Script to generate hermes messages from raw notifications.

  This script runs forever, make sure it is started as weak user in an 
  environment that makes sure that this script is running.
  To stop it smoothly send it a TERM signal.

  -o:  process messages only one times and stop after that
  -h:  help text
  -s:  silent, no output is generated.
  -p url:   proxy: send raw data of each notification to another Hermes
            instance identified by url. 
	    Example: hermesgenerator.pl -p http://testhermes.suse.de/herminator
  -l limit: limit processing to limit notifications
  -w delay: sleeping time in seconds, default 10
  -t database name as of the Config.pm file

END
;
  exit;
}

sub gotSignalTerm
{
  $gotTermSignal = 1;
}

# ---------------------------------------------------------------------------

# Process the commandline arguments.
getopts('ohl:w:t:p:');

usage() if ($opt_h );

print "Connecting to database $opt_t\n" if defined $opt_t;
setLogFileName('hermesgenerator');
connectDB( $opt_t );

my $silent = 0;
$silent = 1 if( $opt_s );

my $limit = 100;
$limit = 0+$opt_l if( $opt_l && $opt_l =~ /^\d+$/ );

my $delay = $opt_w || 10; # ten seconds default delay

$gotTermSignal = 0;
$SIG{TERM} = \&gotSignalTerm;

log( 'info', "#################################### generator rocks the show" );

my $sql = "SELECT n.*, msgt.msgtype FROM notifications n, msg_types msgt WHERE ";
$sql   .= "n.generated=0 AND n.msg_type_id=msgt.id order by n.received limit $limit";
log( 'info', "SQL: $sql " );
my $notiSth = dbh()->prepare( $sql );

$sql = "SELECT np.*, mtp.name FROM notification_parameters np, parameters mtp ";
$sql .= "WHERE np.parameter_id=mtp.id AND np.notification_id=?";
my $paramSth = dbh()->prepare( $sql );

$sql = "UPDATE notifications SET generated=NOW() WHERE id=?";
my $generatedSth = dbh()->prepare( $sql );

$sql = "INSERT INTO generated_notifications(notification_id, subscription_id, created_at) " .
       "VALUES (?, ?, ?)";
my $genSth = dbh()->prepare( $sql );

while( 1 ) {
    # my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
 
    my $t0 = [gettimeofday];
 
    $notiSth->execute();

    my $cnt = 0;
    while( my ($id, $msgTypeId, $received, $sender, $gen, $type ) = $notiSth->fetchrow_array() ) {
	print " [$type]" unless( $silent );
	$paramSth->execute( $id );
	my %params;
	my $pCount = 0;
	while( my ($nId, $notiId, $paramId, $val, $name) = $paramSth->fetchrow_array()) {
	    # print "$name = $val\n" unless( $silent );
	    $params{$name} = $val;
	    $pCount++;
	}
	print " with $pCount Arguments:" unless( $silent );

	# send to another herminator if configured
	sendToHermes( $opt_p, $type, \%params ) if( $opt_p );
	
	# generateNotification returns the count of generated notifications
	my $subsIdsRef = generateNotification( $type,  \%params );
	unless( $subsIdsRef ) {
	    print " no subscribers!\n";
	    next;
	}

	my $genCnt = @{$subsIdsRef}; # amount of entries

	if( $genCnt ) {
	    print ", $genCnt notifications generated!\n" unless( $silent );
	} elsif( $genCnt == 0 ) {
	    print ", no notifications created!\n" unless( $silent );
	} else {
	    print ", ERROR happened, check logfile!\n" unless( $silent );
	}

	# write records into generated_notifications table. This connects the 
	# notification and a subscription. 
	# Do that only if there are really subscriptions interested in this type.
	if( $genCnt > 0 ) {
	    foreach my $subsId ( @{$subsIdsRef} ) {
		$genSth->execute( $id, $subsId, $received );
	    }
	    $cnt++;
	}
	# Even if there were no subscriber, set the notification to sent.
	if( $genCnt >= 0 ) {
	    $generatedSth->execute( $id );
	}
    }

    my $elapsed = tv_interval ($t0);
    log 'info', "Generated $cnt notifications in $elapsed sec.\n";
    print "Generated $cnt notifications in $elapsed sec.\n" unless( $silent );
    
    if( $gotTermSignal ) {
      log 'info', "Got the term signal, I go outta here...";
      print "## Got the term signal, I go outta here...\n";
      exit 0;
    }
    
    sleep( $delay );
    if( $opt_o ) {
	log('info', "################################### generator exits" );
	exit;
    }

    log( 'info', ">>> Generator sleeping for $delay seconds" );
}


# the end
