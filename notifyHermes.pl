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
# This is a commandline script to notify hermes which generates Messages
# from it.

use strict;
use Getopt::Std;

use Hermes::Message;

use vars qw ( $opt_o $opt_h );

sub help 
{
    print<<END

NAME
    notifyHermes.pl - schedule a notification to the hermes system.

SYNOPSIS
    
    notifyHermes.pl [option...] type

DESCRIPTION
    
    Calling notifyHermes schedules a notification into the hermes system.
    All people subscribed to the notification type will get a message 
    according to their setting of the delay and delivery type.

    Options:
      -o string: The parameter that gets processed to the message template
                 later on. Multiple parameter can be added comma separated.
      -h: This help

EXAMPLE:
    
    Place a notification:

      notifyHermes -o 'bla=foo, bar=baz' CheckHermes

    fires the notification type CheckHermes with the parameters bla = foo 
    and bar = baz.

END
;

    exit;

}

# ======================================================================

getopts( 'o:h' );

my ($type) = @ARGV;

help() if( $opt_h );

my %params;

if( $opt_o ) {
    my @opts = split( /\s*,\s*/, $opt_o );
    foreach my $opt ( @opts ) {
	my ($key, $val) = split( /\s*=\s*/, $opt );
	$params{$key} = $val;
	print "Parameter: $key = $val\n";
    }
}

die "No notification type specified" unless( defined $type );

my $id = sendNotification( $type, \%params );

if( $id ) {
    print "Message created: $id\n";
} else {
    print "No message created\n";
}

# END

