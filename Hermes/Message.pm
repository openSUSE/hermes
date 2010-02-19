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
package Hermes::Message;

use strict;
use Exporter;

use Hermes::Config;
use Hermes::DB;
use Hermes::Log;
use Hermes::Util;

use Cwd;

use vars qw(@ISA @EXPORT);

@ISA	    = qw(Exporter);
@EXPORT	    = qw( generateNotification notificationToInbox createMsgType );

=head1 NAME

Hermes::Message - a module to post messages to the hermes system

=head1 SYNOPSIS

    use Hermes::Message;

=head1 DESCRIPTION

This chapter describes the basic idea behind the Hermes message handling

=head2 The Idea

Hermes abstracts the sending of a message to the user. That means that
any software system that wants to send a notification to a user hands
the message over to Hermes. Hermes gives the power back to the user lets
him or her decide which way the message should approach him.

Both the way of message delivery and the time when the messages is
adjustable by the user.

=over

=item 1. Way of Message delivery

Hermes is able to deliver the messages in several ways: Web access,
mail, news but also instant messages like jabber.

=item 2. Amount of Messages

Hermes is able to create message digests, that are collected messages
to one, i.e. all build-failed messages are combined to a digest one
sent at midnight that contains a list of all failed packages.

=back

For systems that want to hand over their messages to Hermes, there are
two different concepts of message inputs:

=over

=item 1. Messages

These are classical messages that consist of subject, body and lists
of receivers, just like emails. Hermes processes these messages only
to the user in the receiver lists as expected. (Not yet implemented!)

=item 2. Notifications

Client systems also can send only Notifications which indicate that a
certain event has happend togehter with some parameters which specify
details. Hermes generates a message for all users who have subscribed
to the certain notification.

=back 

This module provides methods to store messages to the Hermes system
and thus should be used by systems that needs to notify users. The 
sending of messages is done by a special process running on the
hermes server.

=head2 Current Status

Currenty there are methods to send messages either as digest or immediately
by several output options such as mail, rss or jabber.

Message Attachments are not yet supported.

=head2 Usage

Messages are currently not supported.

Notifications can be sent to Hermes with L<sendNotification> and
a hash reference with attached parameters.

Notifications let Hermes create the message according to the notification and
store it to the database to picked up by the sender process.

=cut


=head1 NAME

generateNotification() - notify the hermes system to generate messages

=head1 SYNOPSIS

    use Hermes::Message;

    my $type = 'testnotification';
    my $paramRef = { foo => 'bar', name => 'goof' };

    my $id = generateNotification( $type, $paramRef );

=head1 DESCRIPTION

generateNotifcation() notifies Hermes to generate a message for all people
who are subscribed to the message type given in the parameters.

=head1 PARAMETERS

The first parameter is a string that contains the message type that is
notified.
If the message type is not yet known to Hermes, it is automatically created
and people can subscribe to it from now on.

The second parameter is a hash reference that contains additional specific 
information for the message such as Ids, etc. All the contents of the
hash is transfered to the message generator in Hermes that builds the
actual message. 

=head1 RETURN VALUE

Returns a list with subscriber ids

=cut

sub generateNotification( $$ )
{
  my ( $msgType, $params ) = @_;

  my $module = 'Hermes::Buildservice'; # FIXME - better plugin handling

  push @INC, "..";
  push @INC, ".";

  my $subscriberListRef;

  unless( eval "use $module; 1" ) {
    log( 'warning', "Error with <$module>" );
    log( 'warning', "$@" );
  } else {
    # Get a list of subscription ids based on msgtype and parameters.
    $subscriberListRef = expandNotification( $msgType, $params );
  }

  return $subscriberListRef;
}

sub notificationToInbox( $$ )
{
  my ( $msgType, $params ) = @_;

  my $id;
  my $msgTypeId = createMsgType( $msgType );

  if( $msgTypeId ) {
    my $sender = $params->{sender} || undef;
    
    my $sql = "INSERT into notifications (msg_type_id, received, sender) VALUES (?, NOW(), ?)";
    my $sth = dbh()->prepare( $sql );
    $sth->execute( $msgTypeId, $sender );
    $id = dbh()->last_insert_id( undef, undef, undef, undef, undef );

    my $cnt = 0;
    if( $id ) {
      $cnt = storeNotificationParameters( $id, $msgTypeId, $params );
    } else {
      log('error', "Could not create notification - no result of last_insert_id" );
    }
   
    log( 'info', "Notification of type <$msgType> added with $cnt parameters" );
  }
  return $id;
}

#
# create the notification parameters and fill the table msg_types_parameters
# if needed.
#
sub storeNotificationParameters($$$ ) 
{
  my ($notiId, $typeId, $params) = @_;

  my $cnt = 0;

  return unless( $typeId =~ /^\d+$/ );

  my $paramSth = dbh()->prepare( "SELECT id FROM parameters WHERE name=?" );
  my $inssth = dbh()->prepare( "INSERT INTO msg_types_parameters (msg_type_id, parameter_id) VALUES ($typeId, ?)" );
  my $insparamSth = dbh()->prepare( 'INSERT INTO notification_parameters(notification_id, parameter_id, value ) VALUES (?,?,?)' );

  my $msgTypeSql = "SELECT parameter_id FROM msg_types_parameters WHERE msg_type_id=$typeId";

  # this call returns a ref to an array containing all parameter-ids for that msg_type
  my $msgTypesRef = dbh()->selectcol_arrayref( $msgTypeSql );

  foreach my $param  ( keys %{$params} ) {
    # check for the parameter and create if not yet known.
    $paramSth->execute( $param );
    my ($param_id) = $paramSth->fetchrow_array();

    unless( $param_id ) {
      # Create the parameter in the parameters table
      my $isth = dbh()->prepare( "INSERT INTO parameters (name) VALUES (?)");
      $isth->execute( $param );
      $param_id = dbh()->last_insert_id( undef, undef, undef, undef, undef );
    }

    # Check if the parameter is known for 
    unless( grep( /\b$param_id\b/, @{$msgTypesRef} ) ) {
      log( 'info', "Creating msg_types_parameters-Entry for type <$typeId>, param <$param>" );
      $inssth->execute( $param_id );
    }

    # now set the actual parameter value
    if( $param_id ) {
      $insparamSth->execute( $notiId, $param_id, $params->{$param} || 'undefined' );
      $cnt++;
    }
  }
  return $cnt;
}

######################################################################
# sub userTypeSettings
# -------------------------------------------------------------------
# Returns the user setting of the delay according to the given msg type.
######################################################################

sub userTypeSettings( $$ )
{
  my ( $typeId, $personId ) = @_;

  my $sql = "SELECT delay_id, delivery_id FROM subscriptions WHERE msg_type_id=? AND person_id=?";
  my ($delayID, $deliveryID) = @{dbh()->selectcol_arrayref( $sql, undef, ($typeId, $personId ) )};

  return $delayID, $deliveryID;
}

#
# Creates an entry in the msg_types table if it does not yet exist.
#
sub createMsgType( $;$ )
{
  my ($msgType, $delay ) = @_;

  $msgType = "straycat" unless( $msgType );

  my $sth = dbh()->prepare( 'SELECT id FROM msg_types WHERE msgtype=?' );
  $sth->execute( $msgType );

  my ($id) = $sth->fetchrow_array();

  unless( $id ) {
    my $defaultDelay = $delay || $Hermes::Config::NotifyDefaultDelay;
    my $sth1 = dbh()->prepare( 'INSERT INTO msg_types (msgtype, defaultdelay, added) VALUES (?, ?, now())' );
    $sth1->execute( $msgType, $defaultDelay );
    $id = dbh()->last_insert_id( undef, undef, undef, undef, undef );
  }

  log( 'info', "Returning id <$id> for msg_type <$msgType>" );
  return $id;
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
1;

