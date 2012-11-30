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

sub tweet( $$ )
{
  my ($attribRef, $text) = @_;

  my $t0 = [gettimeofday];

  log('debug', "tweet it");

  unless( $attribRef && $attribRef->{access_token} ) {
    log( 'info', "Error: No valid attribute basket for Twitter" );
    return 0;
  }
  if( $Hermes::Config::DebugTwitter ) {
    log( 'info', "DeliverTwitter-Debug-Switch set, returning id 14 but do not send!" );
    return 14;
  }

  my $access_token        = $attribRef->{access_token};
  my $access_token_secret = $attribRef->{accesss_token_secret};
  my $user_id             = $attribRef->{user_id};
  my $screen_name         = $attribRef->{screen_name};
  my $consumer_key        = $attribRef->{consumer_key};
  my $consumer_secret     = $attribRef->{consumer_secret};

  my $twit = Net::Twitter->new(
    traits => [qw/API::REST OAuth WrapError/],
    ( consumer_key => $consumer_key, consumer_secret => $consumer_secret,
      useragent => 'Hermes Twitter Agent' )
  );
  if( ! $twit ) {
    log( 'info', "Hermes Twitter-Error: $!" );
    return 0;
  }
  $twit->access_token( $access_token );
  $twit->access_token_secret( $access_token_secret );

  # set twitter status.
  $text = substr( $text, 0, 139 ) if( length( $text ) > 139 );
  my $tweet = $twit->update( $text );
  
  if( !$tweet ){
    my $errMessages = $twit->get_error();
    my $errmsg = "";
    while( my ($key, $val) = each( %$errMessages ) ) {
      $errmsg .= "$key: $val|";
    }
    log( 'info', "Tweet failed: " . $errmsg );
    $twit->end_session();
    return 0;
  }
  my $elapsed = tv_interval ($t0);
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

