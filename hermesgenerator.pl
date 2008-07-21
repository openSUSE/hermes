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

use vars qw ( $opt_h $opt_s $opt_l $opt_w $opt_d $opt_o $opt_m );


sub usage()
{
  print<<END

  hermesgenerator.pl

  Script to generate hermes messages from raw notifications

  -o:  create only a few messages and stop after that
  -h:  help text
  -d:  switch on debug
  -s:  silent, no output is generated.
  -l limit: limit processing to limit notifications
END
;
  exit;
}

# ---------------------------------------------------------------------------

# Process the commandline arguments.
getopts('odhl:');

usage() if ($opt_h );

my $silent = 0;
$silent = 1 if( $opt_s );

my $debug = 0;
$debug = 1 if( $opt_d );
my $limit = $opt_l || 100;

my $dbh = Hermes::DBI->connect();

my $sql = "SELECT n.*, msgt.msgtype FROM notifications n, msg_types msgt WHERE ";
$sql .= "n.msg_type_id=msgt.id order by n.received limit $limit";
my $notiSth = $dbh->prepare( $sql );

$sql = "SELECT np.*, mtp.name FROM notification_parameters np, msg_type_parameters mtp ";
$sql .= "WHERE np.msg_type_parameter_id=mtp.id AND np.notification_id=?";
my $paramSth = $dbh->prepare( $sql );

while( 1 ) {
    # my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
 
    my $t0 = [gettimeofday];
 
    $notiSth->execute();

    my $cnt = 0;
    while( my ($id, $msgTypeId, $received, $sender, $type) = $notiSth->fetchrow_array() ) {
	print "> $msgTypeId [$type]\n";
	$paramSth->execute( $id );
	my %params;
	while( my ($id, $notiId, $paramId, $val, $name) = $paramSth->fetchrow_array()) {
	    print "$name = $val\n";
	    $params{$name} = $val;
	}
	sendNotification( $type, \%params );
    }

    my $elapsed = tv_interval ($t0);
    log 'info', "Sent due messages: $cnt in $elapsed sec.\n";
    print "Sent immediate due messages: $cnt in $elapsed sec.\n";

    exit;
}


# the end
