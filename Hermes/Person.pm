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
package Hermes::Person;

use strict;
use Exporter;

use Hermes::Config;
use Hermes::DB;
use Hermes::Log;
use Hermes::Util;

use Data::Dumper;

use vars qw( @ISA @EXPORT @EXPORT_OK );

@ISA	    = qw(Exporter);
@EXPORT	    = qw( personInfo createSubscription createPerson subscriptions);

#
# This sub returns a hash ref that contains some information about
# a person identified through the id
#
# The following keys are set in the person desc hash:
# - all columns from the database table persons
# - feedPath: a relative path name which is user specific.
# 
sub personInfo( $ )
{
  my ($id) = @_;

  my $personInfoRef;
  my $sql = "SELECT * FROM persons WHERE stringid = ?";

  if( $id && $id =~ /^\s*\d+\s*$/ ) {
    $sql = "SELECT * FROM persons WHERE id=?";
  }

  if( $id ) {
    my $sth = dbh()->prepare( $sql );
    $sth->execute( $id );

    $personInfoRef = $sth->fetchrow_hashref;

    my $feeds = $personInfoRef->{stringid} || "unknown_hero";
    # $feeds =~ s/[\.@]/_/g;
    $personInfoRef->{feedPath} = $feeds;
  }
  return $personInfoRef;
}

sub createSubscription( $$$;$ )
{
  my ($msgTypeId, $personId, $deliveryId, $delayId) = @_;

  my $notiTypeRef = notificationTemplateDetails( $msgTypeId );

  # get the person
  my $personInfoRef = personInfo( $personId );

  log( 'info', "Creating a subscription for <$personInfoRef->{stringid}> on <$msgTypeId/$notiTypeRef->{_hrName}>" );

  unless( $deliveryId ) {
    log( 'warning', "No valid delivery id given!" );
    return undef;
  }

  my $delay = $delayId || $notiTypeRef->{_defaultdelay};

  my $id;

  my $sql = "SELECT id FROM subscriptions WHERE msg_type_id=? AND person_id=? AND delay_id=? AND delivery_id=?";
  my $selSth = dbh()->prepare( $sql );
  $selSth->execute( $notiTypeRef->{_id}, $personInfoRef->{id}, $delay, $deliveryId );
  ($id) = $selSth->fetchrow_array();

  # if we found one, return.
  if( $id ) {
    log( 'info', "Found existing subscription: $id" );
    return $id;
  }

  $sql = "INSERT INTO subscriptions (msg_type_id, person_id, delay_id, delivery_id) VALUES (?, ?, ?, ?)";
  my $sth = dbh()->prepare( $sql );
  # print Dumper $personInfoRef;

  if( $personInfoRef->{id} && $notiTypeRef->{_id} ) {

    $sth->execute( $notiTypeRef->{_id}, $personInfoRef->{id}, $delay, $deliveryId );

    $id = dbh()->last_insert_id( undef, undef, undef, undef, undef );
  } else {
    log( 'info', "Not enough information here!" );
  }
  return $id;
}

sub subscriptions( $ )
{
  my ( $person ) = @_;
  my $subsinfoRef;

  my $userInfo = personInfo( $person ); # Get the hermes user info
  if( $userInfo->{id} ) {
    my $sql = "select mt.msgtype, s.delay_id, s.delivery_id from subscriptions s,";
    $sql .= "msg_types mt where s.person_id=? AND s.enabled = 1 AND s.msg_type_id = mt.id";
    my $sth = dbh()->prepare( $sql );
    $sth->execute( $userInfo->{id} );

    $subsinfoRef = $sth->fetchall_arrayref({});
    print Dumper $subsinfoRef;
  }
  return $subsinfoRef;
}

sub createPerson( $$$ )
{
  my ($email, $name, $stringid) = @_;

  # stringid must be unique
  my $sql = "SELECT id FROM persons WHERE stringid=?";
  my $sth = dbh()->prepare( $sql );
  $sth->execute( $stringid );

  my ($id) = $sth->fetchrow_array();

  unless( $id ) {
    $sql = "INSERT INTO persons (email, name, stringid) VALUES (?, ?, ? )";
    $sth = dbh()->prepare( $sql );
    $sth->execute( $email, $name, $stringid );
    $id = dbh()->last_insert_id( undef, undef, undef, undef, undef );
  }
  return $id;
}

1;
