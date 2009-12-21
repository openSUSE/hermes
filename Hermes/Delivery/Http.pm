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
package Hermes::Delivery::Http;

use strict;
use Exporter;

use vars qw(@ISA @EXPORT);

use LWP::UserAgent;

use Hermes::Log;

@ISA     = qw( Exporter );
@EXPORT  = qw( sendHTTP );

our $connection;

sub initCommunication()
{
}

sub quitCommunication()
{
}

#  from       => Sender Address as String
#  to         => Array ref of person ids
#  cc         => Array ref of person ids
#  bcc        => Array ref of person ids
#  replyto    => same as sender FIXME !
#  subject    => string
#  body       => string
#  debug      => debug flag, true if debug.
# 
sub sendHTTP( $$ )
{
  my ($msg, $url) = @_;

  return 0 unless( $url );
  log('info', "Delivering something to URL <$url>" );
  my $browser = LWP::UserAgent->new( 'agent' => 'Hermes_HTTP' );

  my $response = $browser->post( $url, $msg );

  if( $response->is_success ) {
    log( 'info', "POST to <$url> was successful" );
    return 1;
  }
  log('info', "Error: " . $response->status_line ) unless $response->is_success;

  if($response->content =~ m/is unavailable/) {
    log( 'info', "$url is not available" );
  } elsif($response->content =~ m/and available/) {
    log( 'info', "$url is AVAILABLE!" );
  } else {
    log( 'info', "$url... Can't make sense of response " );
  }
  return 0;
}

1;

