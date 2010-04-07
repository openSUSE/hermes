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
package Hermes::Client;

use strict;
use Exporter;

use vars qw(@ISA @EXPORT);

use LWP::UserAgent;

@ISA     = qw( Exporter );
@EXPORT  = qw( notifyHermes );

sub dolog( $$ )
{
  my ($level, $msg) = @_;
  print STDERR "[$level] $msg\n";
}

sub notifyHermes( $;$$ )
{
  my ($type, $params, $url) = @_;

  $url = "https://notify.opensuse.org" unless $url;

  return 0 unless( $type );

  # Make sure the runmode param is in the there
  $params = { rm => 'notify' } unless $params;
  $params->{rm} = 'notify' unless $params->{rm};
  $params->{_type} = $type;

  my $browser = LWP::UserAgent->new( 'agent' => 'Hermes_HTTP' );

  my $response = $browser->post( $url, $params );

  if( $response->is_success ) {
    dolog( 'success', "Hermes successfully notified!" );
    return 1;
  }
  dolog( 'error', $response->status_line );

  if($response->content =~ m/is unavailable/) {
    dolog( 'info', "$url is not available" );
  } elsif($response->content =~ m/and available/) {
    dolog( 'info', "$url is AVAILABLE!" );
  } else {
    dolog( 'info', "$url... Can't make sense of response " );
  }
  return 0;
}

1;

