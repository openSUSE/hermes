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
package Hermes::Delivery::Jabber;

use strict;
use Exporter;
use Net::Jabber qw {Client};

use vars qw(@ISA @EXPORT);

use Hermes::Log;
use Hermes::Person;

@ISA     = qw( Exporter );
@EXPORT  = qw( sendJabber );

our $connection;

sub initCommunication()
{
  $connection = Net::Jabber::Client->new( debuglevel => 0 );
  $connection->Connect( "hostname" => 'subbotin.suse.de', "port"=> 5222 )
    or die "Cannot connect ($!)\n";

  my @result = $connection->AuthIQAuth( "username" => 'dragotin@subbotin',
                                    "password" => '123456',
                                    "resource" => "hermes" );
  print "JABBER: " . join( " - ", @result ) . "\n";
  $connection->RosterGet();
  $connection->PresenceSend();
}

sub quitCommunication()
{
  $connection->Disconnect();
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
sub sendJabber( $ )
{
  my ($msg) = @_;

  my $jabber = Net::Jabber::Message->new();
  
  # only the first to receiver is served. Limitation of jabber.
  my $personInfoRef = personInfo( shift @{$msg->{to}} );

  if( $personInfoRef->{jid} ) {
    log( 'info', "Sending jabber message to <$personInfoRef->{jid}" );
    $jabber->SetMessage( "from"   => 'hermes@openSUSE.org',
			 "to"     => $personInfoRef->{jid},
			 "type"   => 'chat',
			 "subject"=> $msg->{subject},
			 "body"   => $msg->{body} );
  $connection->Send( $jabber );
  } else {
    log( 'error', "Could not find jid for receiver." );
  }
}

1;

