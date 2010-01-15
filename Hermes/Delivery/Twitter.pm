#
# Copyright (c) 2009 Klaas Freitag <freitag@suse.de>, Novell Inc.
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
package Hermes::Delivery::Twitter;

use strict;
use Exporter;
use Net::Twitter;
use Dumpvalue;

use vars qw(@ISA @EXPORT);

use Hermes::Config;
use Hermes::Log;
use Hermes::Person;

@ISA     = qw( Exporter );
@EXPORT  = qw( tweet );

our $connection;

use Dumpvalue;

sub tweet( $$$ )
{
  my ($user, $pwd, $text) = @_;


  unless( $user && $pwd && $Hermes::Config::DeliverTwitter ) {
    log( 'info', "Hermes-User: $user" );
    log( 'info', "Hermes DeliverTwitter-Switch: " . $Hermes::Config::DeliverTwitter || "not set!" );
  }
  my $twit = Net::Twitter->new( { username => $user,
				  password => $pwd } );

  if( ! $twit ) {
    log( 'info', "Hermes Twitter-Error: $!" );
    return 0;
  }

  if( $twit->verify_credentials() ) {
    log('info', "Twitter login ok" );
  } else {
    log( 'info', "Twitter login failed" );
    $twit->end_session();
    return 0;
  }
  # Set twitter status.
  my $tweet = $twit->update( $text );
  if( !$tweet ){
    log( 'info', "Tweet failed: " . $twit->get_error() );
    $twit->end_session();
    return 0;
  }

  log( 'info', "Tweet-ID: ", $tweet->{id} );
  my $dumper = new Dumpvalue;;
  my $dump = $dumper->stringify(\\$tweet);
  log( 'info', "Tweet-Dump: " . $dump );
  # Logout
  $twit->end_session();

  1;
}

1;

