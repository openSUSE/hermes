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
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );

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

  my $t0 = [gettimeofday];

  unless( $user && $pwd && $Hermes::Config::DeliverTwitter ) {
    log( 'info', "Hermes-User: $pwd" );
    log( 'info', "Hermes DeliverTwitter-Switch: " . $Hermes::Config::DeliverTwitter || "not set!" );
  }
  my $twit = Net::Twitter->new( { username => $user,
				  password => $pwd,
				  useragent => 'Hermes Twitter Agent' } );
  my $elapsed = tv_interval ($t0);
  log 'info', "Time to create Twitter-Object: $elapsed sec.\n";
  
  if( ! $twit ) {
    log( 'info', "Hermes Twitter-Error: $!" );
    return 0;
  }

  # Set twitter status.
  my $tweet = $twit->update( $text );
  if( !$tweet ){
    log( 'info', "Tweet failed: " . $twit->get_error() );
    $twit->end_session();
    return 0;
  }
  $elapsed = tv_interval ($t0);
  log 'info', "Time to update: $elapsed sec.\n";

  log( 'info', "Tweet-ID: ". $tweet->{id} );

  # log('info', Dumper( $tweet ) );

  # Logout
  $twit->end_session();
  $elapsed = tv_interval ($t0);
  log 'info', "Time to end the session: $elapsed sec.\n";

  1;
}

1;

