#!/usr/bin/perl -w
#
# Copyright (c) 2010 Klaas Freitag <freitag@suse.de>, Novell Inc.
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
use Hermes::Log;
use Hermes::Util;

use Net::Twitter;

use vars qw ( $opt_h $opt_k $opt_i $opt_s );

sub help 
{
    print<<END

NAME
    twitterInit.pl - do the twitter OAuth initialisation

SYNOPSIS
    
    twitterInit.pl

DESCRIPTION

    This script calls the twitter OAuth API and asks you to enter a PIN
    which is part of the OAuth protocol interactively. The resulting 
    credentials are written into the database, ready for to use with the
    Hermes twitter module.
    
    Note that this only has to be done if the OAuth keys change.
    
    Required Parameters:
      -i: The delivery type name or database id
      -k: The Twitter Consumer Key
      -s: The Twitter Consumer Secret
      
    Options:
      -h: This help
      
END
;

    exit;

}

# ======================================================================

getopts( 'hi:k:s:' );

help() if( $opt_h );
setLogFileName('twitterInit');

unless( $opt_i && $opt_k && $opt_s ) {
  log( 'error', "Invalid parameter set, need ALL Parameters!" );
  print "\n  => Error: Required parameters are not given, see below!\n\n";
  help();
}

my $twittId = $opt_i;
unless( $twittId =~ /^\d+$/ ) {
  log( 'info', "Searching for delivery ID for <$twittId>" );
  $twittId = deliveryStringToId( $opt_i );
}
  
unless( $twittId ) {
  log( 'error', "Have no valid twitter delivery ID in Hermes, check entries in delivery table");
  die;
} else {
  log( 'info', "This is the Hermes Twitter Delivery ID: " . $twittId );
}
my $twittAttribs = deliveryAttribs( $twittId );

my %consumer_tokens = (
    consumer_key    => $opt_k,
    consumer_secret => $opt_s
    );

my $nt = Net::Twitter->new( traits => [qw/API::REST OAuth/], %consumer_tokens );


# Autorisierung
my $auth_url = $nt->get_authorization_url;
print "The Hermes Twitter access needs authorization.\n";
print "Please enter $auth_url into a browser and note the PIN.\n";
print "Please enter the PIN here: ";
my $pin = <STDIN>;    # Auf Eingabe warten
chomp $pin;

# Autorisierung mit PIN#
my ( $access_token, $access_token_secret, $user_id, $screen_name ) =
  $nt->request_access_token( verifier => $pin )
  or die $!;

# write data into data base
setDeliveryAttrib( $twittId, 'access_token',  $access_token );
setDeliveryAttrib( $twittId, 'accesss_token_secret', $access_token_secret );
setDeliveryAttrib( $twittId, 'user_id',              $user_id );
setDeliveryAttrib( $twittId, 'screen_name',          $screen_name );
setDeliveryAttrib( $twittId, 'consumer_key',         $consumer_tokens{consumer_key} );
setDeliveryAttrib( $twittId, 'consumer_secret',      $consumer_tokens{consumer_secret} );

print "wrote oauth tokens to the database!\n";



# END

