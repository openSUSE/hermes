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
@EXPORT	    = qw( personInfo personInfoByMail createSubscription removeSubscriptions 
                  emailToPersonID createPerson subscriptions);


sub fetchPersonInfo( $ )
{
  my ($sth) = @_;

  my $personInfoRef = {};
  if ( $sth ) {
    $personInfoRef = $sth->fetchrow_hashref;

    my $feeds = $personInfoRef->{stringid} || "unknown_hero";
    $personInfoRef->{feedPath} = $feeds;
  }
  return $personInfoRef;
}


#
# Note: this sub identifies the persons with their email address - which
# is to fix as soon as we use a common user base throughout all openSUSE
# systems, FIXME
#
sub emailToPersonID( $ )
{
  my ( $email ) = @_;

  my $sth = dbh()->prepare( 'SELECT id FROM persons WHERE email=?' );
  $sth->execute( $email );

  my ($id) = $sth->fetchrow_array();

  unless( $id ) {
    my $sth1 = dbh()->prepare( 'INSERT INTO persons (email) VALUES (?)' );
    $sth1->execute( $email);
    $id = dbh()->last_insert_id( undef, undef, undef, undef, undef );
  }
  log( 'info', "Returning id <$id> for email <$email>" );
  return $id;
}


#
# The following two subs return a hash ref that contains some
# information about a person identified through the id or mail.
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

  if ( $id && $id =~ /^\s*\d+\s*$/ ) {
    $sql = "SELECT * FROM persons WHERE id=?";
  }

  if ( $id ) {
    my $sth = dbh()->prepare( $sql );
    $sth->execute( $id );
    return fetchPersonInfo( $sth );
  }
  return {};
}

sub personInfoByMail( $ )
{
  my ($id) = @_;

  my $personInfoRef;
  my $sql = "SELECT * FROM persons WHERE email= ?";

  if( $id ) {
    my $sth = dbh()->prepare( $sql );
    $sth->execute( $id );
    return fetchPersonInfo( $sth );
  }
  return {};
}

sub createSubscription( $$;$$$ )
{
  my ($msgTypeId, $personId, $filterListRef, $deliveryId, $delayId) = @_;
  # the filterRef is a reference to an array with hash references in it.
  # each hash must contain the keys
  #         parameter => the parameter (or its id)
  #         operator  => one of the strings "special", "oneof", "regexp" or "containsitem"
  #         filterListRef=> a list of hashes containing filter information in the form
  #         { parameter   => a parameter name
  #           operator    => one of the valid operators
  #          filterstring => 'string to filter'
  # Note that filters only get added for new subscriptions. Existing ones are not going
  # to be updated
  # 
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

  # check if the subscription is already there ...
  my $sql = "SELECT id FROM subscriptions WHERE msg_type_id=? AND person_id=? AND delay_id=? AND delivery_id=?";
  my $selSth = dbh()->prepare( $sql );
  $selSth->execute( $notiTypeRef->{_id}, $personInfoRef->{id}, $delay, $deliveryId );
  ($id) = $selSth->fetchrow_array();

  # if we found one, return.
  if( $id ) {
    log( 'info', "Found existing subscription: $id" );
    return $id;
  }

  # and insert if not...
  $sql = "INSERT INTO subscriptions (msg_type_id, person_id, delay_id, delivery_id) VALUES (?, ?, ?, ?)";
  my $sth = dbh()->prepare( $sql );
  # print Dumper $personInfoRef;

  if( $personInfoRef->{id} && $notiTypeRef->{_id} ) {

    $sth->execute( $notiTypeRef->{_id}, $personInfoRef->{id}, $delay, $deliveryId );

    $id = dbh()->last_insert_id( undef, undef, undef, undef, undef );
  } else {
    log( 'info', "Not enough information to add a subscription!" );
  }
  
  if( $id && $filterListRef ) {
    my $sql = "INSERT INTO subscription_filters (subscription_id, parameter_id, operator, filterstring) ";
    $sql .= "VALUES( $id, ?, ?, ? )";
    my $sti = dbh()->prepare( $sql );

    foreach my $filterRef ( @$filterListRef ) {
      if( exists $filterRef->{parameter} && $filterRef->{parameter} &&
          exists $filterRef->{operator} && $filterRef->{operator} &&
	  exists $filterRef->{filterstring} && $filterRef->{filterstring} ) {
	  my $paramId = $filterRef->{parameter};
	  unless( $paramId =~ /^\d+$/ ) {
	    $paramId = parameterId( $paramId );
	  }
	  log( 'info', "Adding filter def. for $id: $paramId, $filterRef->{operator}, $filterRef->{filterstring}" );
	  $sti->execute( $paramId, $filterRef->{operator}, $filterRef->{filterstring} );
      }
    }
  }

  return $id;
}

sub removeSubscriptions
{
  my @subscriptionIds = @_;

  my $sql = "DELETE FROM subscription_filters WHERE subscription_id=?";
  my $sth_filters = dbh()->prepare( $sql );

  my $sth_subscriptions = dbh()->prepare("DELETE FROM subscriptions WHERE id=?");
  my $sth_gennotis = dbh()->prepare("DELETE FROM generated_notifications WHERE subscription_id=?");

  my $cnt = 0;
  foreach my $subsId ( @subscriptionIds ) {
    $cnt += $sth_filters->execute( $subsId );
    $cnt += $sth_subscriptions->execute( $subsId );
    $cnt += $sth_gennotis->execute( $subsId );
  }
  return $cnt;
}

sub subscriptions( $ )
{
  my ( $person ) = @_;
  my $subsinfoRef;

  my $userInfo = personInfo( $person ); # Get the hermes user info
  if( $userInfo->{id} ) {
    log('info', "Querying user subscriptions for id " . $userInfo->{id} );
    my $sql = "SELECT mt.msgtype, s.delay_id, s.delivery_id, s.id FROM subscriptions s,";
    $sql .= "msg_types mt where s.person_id=? AND s.enabled = 1 AND s.msg_type_id = mt.id";
    my $sth = dbh()->prepare( $sql );
    $sth->execute( $userInfo->{id} );

    $subsinfoRef = $sth->fetchall_arrayref({});
  }
  # load the filterstring
  my $sql = "SELECT parameter_id, operator, filterstring FROM subscription_filters WHERE subscription_id=?";
  my $sth = dbh()->prepare( $sql );
  foreach my $subscription ( @$subsinfoRef ) {
    my $id = $subscription->{id};
    $sth->execute( $id );
    $subscription->{filters} = $sth->fetchall_arrayref({});
  }
  
  # FIXME: handle filters
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
