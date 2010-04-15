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

use Hermes::Person;
use Hermes::DB;
use Hermes::Util;
use Hermes::Log;

use vars qw ( $opt_h $opt_f $opt_t);

sub usage()
{
  print<<END

  removeUserSubscriptions.pl email email email

  Script to remove all subscriptions of a user specified by the 
  email, including all associated data.

  -h:  help text
  -f:  force. Needs to be given to really do it.
  -t:  database name as of the Config.pm file


END
;
  exit;
}

# ---------------------------------------------------------------------------

# Process the commandline arguments.
getopts('hft:');
setLogFileName('removeusersubscriptions');

usage() if ($opt_h );

connectDB( $opt_t );

log( 'info', "**** Force switch is given - will really delete stuff!" ) if( $opt_f );

foreach my $email ( @ARGV ) {
  my $personInfo = personInfoByMail( $email );
  if ( $personInfo->{email} ) {
    my @subsIds;
    print " User $personInfo->{email} (Id: $personInfo->{id})\n";
    my $subscriptionsRef = subscriptions( $personInfo->{id} );
    foreach my $subsHashRef ( @$subscriptionsRef ) {
      if ( $subsHashRef->{id} ) {
	log( 'info', "Removing subscription id " . $subsHashRef->{id} . " on type " . $subsHashRef->{msgtype} );
	push @subsIds, $subsHashRef->{id};
	print "    Subscription: $subsHashRef->{msgtype}\n";
      }
    }
    if ( $opt_f ) {
      my $cnt = removeSubscriptions( @subsIds );
      log( 'info', "Removed $cnt subscription database rows for email <$email>" );
      print "Removed $cnt subscription database rows for email <$email>\n";
    } else {
      print "\nCall this script with option -f to really delete " . scalar @subsIds . " subscriptions for $email!\n";
    }
  }
}
print "\nDone.\n\n";

