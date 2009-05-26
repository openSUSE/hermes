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
package Hermes::Proxy;

use strict;
use Exporter;

use Hermes::Config;
use Hermes::DB;
use Hermes::Log;
use Hermes::Util;

use LWP::UserAgent;

use Cwd;

use vars qw(@ISA @EXPORT $hasError $ua);

@ISA	    = qw(Exporter);
@EXPORT	    = qw(sendToHermes);

sub sendToHermes( $$$ )
{
  my( $host, $type, $paramHashRef) = @_;

  # return if( $hasError );

  unless( $ua ) {
    $ua = LWP::UserAgent->new();
  }

  $paramHashRef->{_type} = $type;
  $paramHashRef->{rm} = "notify";

  my $url = "$host/index.cgi";

  log( 'info', "URL: $url" );
  my $resp = $ua->post( $url, $paramHashRef );

  my $answer = $resp->content;

  log( 'info', "Answer of the Hermes Proxy: $answer" );
}

1;

