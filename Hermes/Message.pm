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
use Hermes::DBI;
use Hermes::Log;

use Cwd;

use vars qw(@ISA @EXPORT $dbh %delayHash);

@ISA	    = qw(Exporter);
@EXPORT	    = qw( newMessage sendNotification notificationToInbox delayStringToValue
		  SendNow SendMinutely SendHourly SendDaily SendWeekly
		  SendMonthly );

=head1 NAME

Hermes::Message - a module to post messages to the hermes system

=head1 SYNOPSIS

    use Hermes::Message;

=head1 DESCRIPTION

This chapter describes the basic idea behind the Hermes message handling

=head2 The Idea

Hermes abstracts the sending of a message to the user. That means that
any software system that wants to send a notification to a user hands
the message to Hermes. Hermes gives the power back to the user lets
him decide which way the message should approach him.

Both the way of message delivery and the amount of sent messages is
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
to the user in the receiver lists as expected.

=item 2. Notifications

Client systems also can send only Notifications which indicate that a
cerain event has happend togehter with some parameters which specify
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

Messages can be sent by the funciton L<newMessage>.

L<newMessage> stores the message to hermes' database. Depending on the
delay settings it sends the message immediately or as a digested message
later together with messages of the same type.

The message text to send is stored in one Perl string which can contain
tags.  The tags need a opening tag and a closing tag, which is the
same as the opening tag with a prefixed / (slash).

For example:

The text of every single mail inside the BODY tags is stored and put to the
collection mail. The text between PRE and POST is assembled around the
collection mail only once.

Notifications can be sent to Hermes with L<sendNotification>. 

Notifications let Hermes create the message according to the notification and
store it to the database to picked up by the sender process.

=cut


=head1 NAME

newMessage() - queues a new message for sending

=head1 SYNOPSIS

    use Hermes::Message;

    my $subject = 'Test Subject';
    my $text = "Hi. <BODY>This is a test.</BODY>";
    my $type = 'test';
    my $delay = SendNow(); # send now !
    my @to = ('goof@universe.com', 'thefreitag@suse.de');
    my @cc = ();
    my @bcc = ('bigbrother@suse.de');

    my $id = newMessage($subject, $text, $type, $delay, @to, @cc, @bcc);

=head1 DESCRIPTION

newMessage() queues a new message in hermes.

=head1 PARAMETERS

Parameter 1 specifies the message's Subject: line.

Parameter 2 specifies the message's text, including tags.  Allowed tags are:

    <PRE> : Text to be extracted and put into the digest before the content
    <BODY>: Text to be cut and included in a digest mailing.
    <POST>: Text to be extracted and put into the digest after the content

Parameter 3 is the message type. The type is a free string. Messages of the
same type can be grouped together in digest mailings.

Parameter 4 is specifies the delay. Use the methods L<SendNow>, L<SendHourly>,
L<SendDaily> etc to specify the delay.

Note that the delay parameter is automatically overwritten by the user
setting if there is one for the message type.

Parameter 5 is an array of recipients.  Each recipient may be specified as
either an email addressm, a numberic user ID, or as a function.

Parameter 6 is an array of recipients who will be carbon-copied (Cc:'ed).
It takes the same format as parameter 5.

Parameter 7 is an array of recipients who will be blind-carbon-copied (Bcc:'ed).
It takes the same format as parameter 5.

Parameter 8 is a string wiht the recipients mail who will be put into the headers's
reply to field.
It takes the same format as parameter 5.

=head1 RETURN VALUE

Returns the message's ID

=cut

sub newMessage($$$$\@;\@\@$$)
{
    my ($subject, $text, $type, $delay, $to, $cc, $bcc, $from, $replyTo ) = @_;

    # Convert the type string to lowercase.
    $type = lc($type);

    log('notice', "Adding new message (type: '$type').");

    if (!defined $subject || $subject eq '') {
    	log('warning', 'Empty message subject.');
    }

    if(!defined($from)){
    	$from = 'hermes@opensuse.org';
    }

    # This call returns the id of the type. If that does not exist, it is created.
    my $typeId = createMsgType( $type, $delay ); # use delay as default for new types.

    # check for a user

    # Add the new message to the database.
    $dbh->do( 'LOCK TABLES messages WRITE, messages_people WRITE, subscriptions READ' );
    my $sql = 'INSERT INTO messages( msg_type_id, sender, subject, body, created) ' .
	'VALUES (?, ?, ?, ?, NOW())';
    $dbh->do( $sql, undef, ( $typeId, $from, $subject, $text ) );

    # Grab the message's ID.
    my $id = $dbh->last_insert_id( undef, undef, undef, undef, undef );
    log( 'info', "Last inserted id: $id" );

    # Resolve the address lists.  All we want are the numeric PersonID's.
    # We build a hash here so that we don't get duplicate entries in the
    # MailAddresses table.
    my %addresses;

    foreach my $address (@$bcc) {
      unless (defined $addresses{$address}) {
	$addresses{$address} = 'bcc';
      }
    }

    foreach my $address (@$cc) {
      unless (defined $addresses{$address}) {
	$addresses{$address} = 'cc';
      }
    }

    foreach my $address (@$to) {
      $addresses{$address} = 'to';
    }

    if( $replyTo ) {
      $addresses{ $replyTo } = 'reply-to';
    }

    # Set up the SQL insertion template for the mail addresses.
    my $sth = $dbh->prepare( "INSERT INTO messages_people( message_id, person_id, header, delay ) "
                            ."VALUES ($id, ?, ?, ?)");

    # Adds the addresses to the MailAddresses table.
    foreach my $person (keys %addresses) {
      my $person_id = $person; # assume the person id is numeric
      next unless( $person_id );
      if( $person_id =~ /^\S+@\S+\.\S{2,}?$/ ) {
	$person_id = emailToPersonID( $person );
      }
      if( $person_id =~ /^\d+$/ ) {
	my ($delayID, $deliveryID) = userTypeSettings( $typeId, $person_id );

 	unless( defined $delayID ) {
	  if( $delay =~ /^\d+$/ ) {
	    $delayID = $delay;
	  } else {
	    log( 'error', "Delay needs to be numeric value!" );
	  }
	}
	$deliveryID = $Hermes::Config::DefaultDelivery unless( defined $deliveryID );

	log( 'info', "User delay id <$delayID> for type <$typeId> for person <$person_id>" );
	$sth->execute( ($person_id, $addresses{$person}, $delayID ) );
      } else {
	log( 'error', "Unknown or invalid person, can not store message!" );
      }
    }
    $dbh->do( 'UNLOCK TABLES' );
    # some of the receipients might want the message immediately.
    # sendMessage( $id );

    return $id;
}

=head1 NAME

sendNotification() - notify the hermes system to generate messages

=head1 SYNOPSIS

    use Hermes::Message;

    my $type = 'testnotification';
    my $paramRef = { foo => 'bar', name => 'goof' };

    my $id = sendNotification( $type, $paramRef );

=head1 DESCRIPTION

sendNotifcation() notifies Hermes to generate a message for all people
who are subscribed to the message type given in the parameters.

=head1 PARAMETERS

The first parameter is a string that contains the message type that is 
notified.

The second parameter is a hash reference that contains additional specific 
information for the message such as Ids, etc. All the contents of the
hash is transfered to the message generator in Hermes that builds the
actual message. 

If the message type is not yet known to Hermes, it is automatically created
and people can subscribe to it from now on.

=head1 RETURN VALUE

Returns the message's ID

=cut

sub sendNotification( $$ )
{
  my ( $msgType, $params ) = @_;

  my $module = 'Hermes::Buildservice'; # FIXME - better plugin handling

  push @INC, "..";
  push @INC, ".";

  my $id;
  unless( eval "use $module; 1" ) {
    log( 'warning', "Error with <$module>" );
    log( 'warning', "$@" );
  } else {
    my $msgHash = expandFromMsgType( $msgType, $params );
    return undef unless( $msgHash );

    if( $msgHash->{error} ) {
      log( 'error', "Could not expand message: $msgHash->{error}\n" );
    } else {
      if( $msgHash->{receiverCnt} ) {
	$msgHash->{delay} = SendNow() if( $msgHash->{delay} == 0 );

	$id = newMessage( $msgHash->{subject},   $msgHash->{body}, $msgHash->{type},
			  SendNow(),   @{$msgHash->{to}},  @{$msgHash->{cc}},
			  @{$msgHash->{bcc}},    $msgHash->{from}, $msgHash->{replyTo} );
	log( 'info', "Created new message with id $id" );
      } else {
	log( 'info', "No receiver for this message, did not create one." );
	$id = 0;
      }
    }
  }
  return $id;
}

sub notificationToInbox( $$ )
{
  my ( $msgType, $params ) = @_;

  my $id;
  my $msgTypeId = createMsgType( $msgType );

  if( $msgTypeId ) {
    my $sender = $params->{sender} || "unknown";
    $dbh->do( 'LOCK TABLES notifications WRITE, parameters WRITE, notification_parameters WRITE, msg_types_parameters WRITE' );
    my $sql = "INSERT into notifications (msg_type_id, received, sender) VALUES (?, NOW(), ?)";
    my $sth = $dbh->prepare( $sql );
    $sth->execute( $msgTypeId, $sender );
    $id = $dbh->last_insert_id( undef, undef, undef, undef, undef );

    my $cnt = storeNotificationParameters( $id, $msgTypeId, $params );
    $dbh->do( 'UNLOCK TABLES' );
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

  my $paramSth = $dbh->prepare( "SELECT id FROM parameters WHERE name=?" );
  my $inssth = $dbh->prepare( "INSERT INTO msg_types_parameters (msg_type_id, parameter_id) VALUES ($typeId, ?)" );
  my $insparamSth = $dbh->prepare( 'INSERT INTO notification_parameters(notification_id, parameter_id, value ) VALUES (?,?,?)' );

  my $msgTypeSql = "SELECT parameter_id FROM msg_types_parameters WHERE msg_type_id=$typeId";

  # this call returns a ref to an array containing all parameter-ids for that msg_type
  my $msgTypesRef = $dbh->selectcol_arrayref( $msgTypeSql );

  foreach my $param  ( keys %{$params} ) {
    # check for the parameter and create if not yet known.
    $paramSth->execute( $param );
    my ($param_id) = $paramSth->fetchrow_array();

    unless( $param_id ) {
      # Create the parameter in the parameters table
      my $isth = $dbh->prepare( "INSERT INTO parameters (name) VALUES (?)");
      $isth->execute( $param );
      $param_id = $dbh->last_insert_id( undef, undef, undef, undef, undef );
    }

    # Check if the parameter is known for 
    unless( grep( /$param_id/, @{$msgTypesRef} ) ) {
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
  my ($delayID, $deliveryID) = @{$dbh->selectcol_arrayref( $sql, undef, ($typeId, $personId ) )};

  return $delayID, $deliveryID;
}

sub SendNow
{
  return $delayHash{'NO_DELAY'};
}

sub SendMinutely
{
  return $delayHash{'PER_MINUTE'};
}

sub SendHourly
{
  return $delayHash{'PER_HOUR'};
}

sub SendDaily
{
  return $delayHash{'PER_DAY'};
}

sub SendWeekly
{
  return $delayHash{'PER_WEEK'};
}

sub SendMonthly
{
  return $delayHash{'PER_MONTH'};
}

#
# Creates an entry in the msg_types table if it does not yet exist.
#
sub createMsgType( $;$ )
{
  my ($msgType, $delay ) = @_;

  $msgType = "straycat" unless( $msgType );

  my $sth = $dbh->prepare( 'SELECT id FROM msg_types WHERE msgtype=?' );
  $sth->execute( $msgType );

  my ($id) = $sth->fetchrow_array();

  unless( $id ) {
    my $defaultDelay = $delay || $Hermes::Config::NotifyDefaultDelay;
    my $sth1 = $dbh->prepare( 'INSERT INTO msg_types (msgtype, defaultdelay, added) VALUES (?, ?, now())' );
    $sth1->execute( $msgType, $defaultDelay );
    $id = $dbh->last_insert_id( undef, undef, undef, undef, undef );
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

  my $sth = $dbh->prepare( 'SELECT id FROM persons WHERE email=?' );
  $sth->execute( $email );

  my ($id) = $sth->fetchrow_array();

  unless( $id ) {
    my $sth1 = $dbh->prepare( 'INSERT INTO persons (email) VALUES (?)' );
    $sth1->execute( $email);
    $id = $dbh->last_insert_id( undef, undef, undef, undef, undef );
  }
  log( 'info', "Returning id <$id> for email <$email>" );
  return $id;
}

sub delayStringToValue( $ )
{
  my ($str) = @_;

  return SendNow() unless( $str );

  if( $str =~ /NOW|IMMEDIATELY/i ) {
    return SendNow();
  } elsif( $str =~ /HOUR/i ) {
    return SendHourly();
  } elsif( $str =~ /DAILY/i ) {
    return SendDaily();
  } elsif( $str =~ /WEEK/i ) {
    return SendWeekly();
  } elsif( $str =~ /MONTH/i ) {
    return SendMonthly();
  }
  return SendNow(); # Default
}

#
# some initialisations
#
$dbh = Hermes::DBI->connect();


#
# Load the existing delay values
my $sth = $dbh->prepare( 'SELECT id, name FROM delays order by seconds asc' );
$sth->execute();
while ( my ($id, $name) = $sth->fetchrow_array ) {
  # log( 'info', "Storing delay value $name with id $id" );
  $delayHash{$name} = $id;
}


log( 'info', "Config-Setting: DefaultDelivery: ". $Hermes::Config::DefaultDelivery );
1;

