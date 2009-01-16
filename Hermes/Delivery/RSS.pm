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
package Hermes::Delivery::RSS;

use strict;
use Exporter;

use vars qw(@ISA @EXPORT $mNewState);

use Hermes::Log;
use Hermes::Person;
use Hermes::Config;
use Hermes::DB;
use Data::Dumper;

@ISA     = qw( Exporter );
@EXPORT  = qw( sendRSS );

sub loadNewState
{
  my $sql = "SELECT id FROM msg_states WHERE state='new'";
  my $sth = dbh()->prepare( $sql );
  $sth->execute();

  ($mNewState) = $sth->fetchrow_array();
  $mNewState =~ /^\d+$/;
}

sub sendRSSRails( $ )
{
  my ($msgRef) = @_;

  # let rails deliver the feed, sorted by the type. All we do here is to fill
  # a table that acts as a base for RSS generation.
  loadNewState unless( $mNewState );

  my $sql = "INSERT INTO starship_messages( notification_id, sender, user, msg_type_id, ";
  $sql .= "subject, replyto, body, msg_state_id, created ) ";
  $sql .= "VALUES( ?,?,?,?,?,?,?, $mNewState, NOW() )";

  my $sth = dbh()->prepare( $sql );

  $sth->execute( $msgRef->{_notiId}, $msgRef->{from}, @{$msgRef->{to}}[0], $msgRef->{_msgTypeId},
		 $msgRef->{subject}, $msgRef->{replyto}, $msgRef->{body} );

  my $id = dbh()->last_insert_id( undef, undef, undef, undef, undef );

  return $id;
}

sub sendRSS( $ )
{
  my ($msgRef) = @_;

  return sendRSSRails( $msgRef );
}

1;

