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

use Hermes::Log;
use Time::HiRes qw( gettimeofday tv_interval );
use Hermes::Message;

use vars qw ( $opt_h $opt_s $opt_l $opt_w $opt_o );


sub usage()
{
  print<<END

  hermesgenerator.pl

  Script to generate hermes messages from raw notifications.

  This script runs forever, make sure it is started as weak user in an 
  environment that makes sure that this script is running.

  -o:  create only l messages and stop after that
  -h:  help text
  -s:  silent, no output is generated.
  -l limit: limit processing to limit notifications
  -w delay: sleeping time in seconds, default 10

END
;
  exit;
}

# ---------------------------------------------------------------------------

# Process the commandline arguments.
getopts('odhl:w:');

usage() if ($opt_h );

my $silent = 0;
$silent = 1 if( $opt_s );

my $limit = $opt_l || 100;

my $delay = $opt_w || 10; # ten seconds default delay

my $dbh = Hermes::DBI->connect();

log( 'info', "#################################### generator rocks the show" );

my $sql = "SELECT n.*, msgt.msgtype FROM notifications n, msg_types msgt WHERE ";
$sql   .= "n.generated IS NULL AND n.msg_type_id=msgt.id order by n.received limit $limit";
log( 'info', "SQL: $sql " );
my $notiSth = $dbh->prepare( $sql );

$sql = "SELECT np.*, mtp.name FROM notification_parameters np, parameters mtp ";
$sql .= "WHERE np.msg_type_parameter_id=mtp.id AND np.notification_id=?";
my $paramSth = $dbh->prepare( $sql );

$sql = "UPDATE notifications SET generated=NOW() WHERE id=?";
my $updateSth = $dbh->prepare( $sql );

while( 1 ) {
    # my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
 
    my $t0 = [gettimeofday];
 
    $notiSth->execute();

    my $cnt = 0;
    while( my ($id, $msgTypeId, $received, $sender, $gen, $type ) = $notiSth->fetchrow_array() ) {
	print " Type [$type]" unless( $silent );
	$paramSth->execute( $id );
	my %params;
	my $pCount = 0;
	while( my ($id, $notiId, $paramId, $val, $name) = $paramSth->fetchrow_array()) {
	    # print "$name = $val\n" unless( $silent );
	    $params{$name} = $val;
	    $pCount++;
	}
	my $msgId = sendNotification( $type, \%params );
	print " with $pCount Arguments <$msgId>";
	if( $msgId ) {
	    print ", message $id created!\n";
	} elsif( $msgId == 0 ) {
	    print ", no message created!\n";
	} else {
	    print ", ERROR happened, check logfile!\n";
	}

	if( defined $msgId && $msgId =~ /^\d+$/ ) {
	    $dbh->do( 'LOCK TABLES notifications WRITE' );
	    $updateSth->execute( $id );
	    $dbh->do( 'UNLOCK TABLES' );
	}
    }

    my $elapsed = tv_interval ($t0);
    log 'info', "Created $cnt messages in $elapsed sec.\n";
    print "Created $cnt messages in $elapsed sec.\n" unless( $silent );
    
    exit if( $opt_o );

    sleep( $delay );
}


# the end
