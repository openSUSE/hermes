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
package Hermes::MessageSender;

use strict;
use Exporter;

use Data::Dumper;

use Hermes::Config;
use Hermes::DBI;
use Hermes::Log;

use Hermes::Message qw( :DEFAULT getSnippets createMimeMessage markSent );

use vars qw(@ISA @EXPORT @EXPORT_OK $dbh $query );

@ISA	    = qw(Exporter);
@EXPORT	    = qw( sendMessageDigest sendImmediateMessages );




=head1 NAME

sendMessageDigest() - sends a digest of queued messages

=head1 SYNOPSIS

    use Hermes::Message qw(:DEFAULT /^SEND_/);

    my $delay = SEND_HOURLY;	# Send messages queued for hourly distribution.
    my $type = 'test';		# Send messages of the 'test' type.

    my $count = sendMessageDigest($delay, $type);

=head1 DESCRIPTION

sendMessageDigest() sends a digest of similarly-typed messages in the 
system queue.  Each message is marked according to its distribution frequency
(e.g. hourly, daily, weekly, monthly) and its type.  Messages with the same
type will have their message bodies grouped into a single digested mail.

=head1 PARAMETERS

Parameter 1 indicates the frequency of this digest run.

Parameter 2 is an optional parameter that specifies the message type for
this mailing.

Parameter 3 is an optional debug flag.

=head1 RETURN VALUE

Returns the number of messages sent in this digest run.

=cut

sub sendMessageDigest($;$$$)
{
  my ($delay, $type, $debug, $subject) = @_;

  if ( $Hermes::Config::Debug ) {
    log( 'warning', "Mail sending switched off (debug) due to Config-Setting!" );
    $debug = 1;
  }

  # Find all messages of the same type and delay that haven't been sent.
  my $sql = '';
  my $sth;
  my $cnt = 0;
  my $knownType;
  my @markSentIds;
  my @msg;

  log('notice', "Fetching messages of all types with delay $delay");

  $query->execute( $delay, 1000 );

  while ( my ( $msgid, $type, $sender, $subject, $body, $created, $personId, $markSentId,
	       $header, $deliveryId ) = $query->fetchrow_array()) {
    # The query returns a message id multiple times, depending on the amount of 
    # receipients.
    log( 'info', "MessagePeople ID <$markSentId> handling!" );

    $deliveryId = $Hermes::Config::DefaultDelivery unless( $deliveryId );


    log( 'info', "Sending <$msgid> with <$personId> as <$header>" );

    # if a new type starts, we have to combine the messages and form a message
    if( defined $knownType && $type != $knownType ) {
      # The current type is not yet handled.
      my $deliverHashRef = digestList( @msg );
      log( 'info', "sending digest begins ========================================!" );
      sendHash( $deliverHashRef );
      log( 'info', "sending digest end    ========================================!" );
      @msg = ();
    }
    $knownType = $type;

    # Store the message for further processing.
    push @msg, { MsgId => $msgid, Sender => $sender, Subject => $subject, 
		 Body => $body, Created => $created, Person => $personId,
		 Header => $header, Delivery => $deliveryId, markSentId => $markSentId,
	         Type => $type };
  }

  # send whats left over
  if( @msg ) {
    log( 'info', "Sending left over digests =====================================!" );
    my $deliverHashRef = digestList( @msg );
    sendHash( $deliverHashRef );
    log( 'info', "Finished left over digests ====================================!" );
  }
}


sub digestList( @ )
{
  my @msges = @_;

  # go through the incoming list of hash refs with non yet digested messages
  # these messages are all of the same type.
  #
  # The message parts of the new message
  my ( $preMsg, $msgText, $postMsg, $body );
  my $oldMsgId = 0;
  my $subject;
  my $sender;
  my $receipientsRef;

  my %deliveryMatrix;

  foreach my $msgRef ( @msges ) {

    my $deliveryId = $msgRef->{Delivery};

    unless(  $deliveryMatrix{ $deliveryId } ) {
      $deliveryMatrix{$deliveryId} = {};
      $receipientsRef = $deliveryMatrix{$deliveryId};
      $receipientsRef->{type} = $msgRef->{Type};
      $receipientsRef->{to} = ();
      $receipientsRef->{cc} = ();
      $receipientsRef->{bcc} = ();
      $receipientsRef->{sentIds} = ();
      $receipientsRef->{MsgID} = (); # $msgRef->{MsgId};
    }
    $receipientsRef = $deliveryMatrix{$deliveryId};
    push @{$receipientsRef->{sentIds}}, $msgRef->{markSentId};
    push @{$receipientsRef->{ $msgRef->{Header}}}, $msgRef->{Person};
    push @{$receipientsRef->{MsgID}}, $msgRef->{MsgId};

    unless (defined $preMsg && defined $postMsg ) {
      ($preMsg)  = getSnippets('PRE',  $msgRef->{Body}, 1);
      ($postMsg) = getSnippets('POST', $msgRef->{Body}, 1);
    }

    unless( $subject ) {
      $subject = $msgRef->{Subject};
    } else {
      if( $subject ne $msgRef->{Subject} ) {
	log( 'warning', "Subject differs between messages of the same types <$msgRef->{MsgId}>: ".
	   "<$subject> ne <$msgRef->{Subject}" );
      }
    }
    $receipientsRef->{subject} = $subject;

    unless( $sender ) {
      $sender = $msgRef->{Sender};
    } else {
      if( $subject ne $msgRef->{Sender} ) {
	log( 'warning', "Sender differs between messages of the same types!" );
      }
    }
    $receipientsRef->{sender} = $sender;

    if( $msgRef->{MsgId} != $oldMsgId ) {
      my ($bodyCont) = getSnippets('BODY', $msgRef->{Body}, 1);

      $bodyCont = $msgRef->{Body} if (!$bodyCont);
      $body .= $bodyCont . "\n==>\n";
    }

    push @{$receipientsRef->{ $msgRef->{'Header'} } }, $msgRef->{Person};
    $oldMsgId = $msgRef->{MsgId};
  }

  # Set the combined body in all messages in the delivery matrix
  foreach my $msgRef ( values %deliveryMatrix ) {
    $msgRef->{body} = $body;
  }

  return \%deliveryMatrix;
}


#
# This sub does the actual sending according to the method that is specified
# in the parameter delivery.
# The second parameter is a hash ref that contains the message details.
#
sub deliverMessage( $$ )
{
  my ($delivery, $msgRef) = @_;

  log( 'info', "Delivery is <$delivery>, to is <$msgRef->{to}>" );

  my $res = 1;

  return $res;
}


#
# takes a hash that is structured by the delivery id where we loop over.
# Called from the sendImmediateMessage
sub sendHash( $ )
{
  my ( $deliveryMatrixRef ) = @_;

  log( 'info', "Delivering Msg: " . Dumper( $deliveryMatrixRef ) );
  foreach my $delivery ( keys %$deliveryMatrixRef ) {
    if( deliverMessage( $delivery,
			{ from       => $deliveryMatrixRef->{$delivery}->{sender},
			  to         => $deliveryMatrixRef->{$delivery}->{to},
			  cc         => $deliveryMatrixRef->{$delivery}->{cc},
			  bcc        => $deliveryMatrixRef->{$delivery}->{bcc},
			  replyto    => $deliveryMatrixRef->{$delivery}->{sender},
			  subject    => $deliveryMatrixRef->{$delivery}->{subject},
			  body       => $deliveryMatrixRef->{$delivery}->{body},
			  debug      => 1 } ) ) {
      log( 'info', "Successfully delivered message!!" );
      markSent( $deliveryMatrixRef->{$delivery}->{sentIds} );
    }
  }
}

sub sendImmediateMessages(;$)
{
  my ($type) = @_;

  # FIXME: Honour message type parameter

  my $cnt = 0;
  my %deliveryMatrix;
  my $last_id = -1;

  $query->execute( SendNow(), 1000 );

  while ( my ( $msgid, $type, $sender, $subject, $body, $created, $personId, $markSentId,
	       $header, $deliveryId ) = $query->fetchrow_array()) {
    # The query returns a message id multiple times, depending on the amount of 
    # receipients.
    # push @markSentIds, $markSentId; # if of the record in messages_people

    # reasonable default for empty delivery id. That happens if the user does not have
    # a preference, it's the default delivery. FIXME
    $deliveryId = $Hermes::Config::DefaultDelivery unless( $deliveryId );
    log('info', "Last ID: $last_id" );
    if ( $msgid != $last_id ) {
      # we have a new id and do the actual sending. 
      if ( $last_id > -1 ) {
	sendHash( \%deliveryMatrix );
	%deliveryMatrix = ();
	$cnt++;
      }
      $last_id = $msgid;
    }

    my $receipientsRef;
    log( 'info', "Storing MsgID <$msgid> with <$personId> as <$header> in DeliveryID <$deliveryId>" );

    # if we do not yet have a hash for this delivery method, create one. 
    unless( $deliveryMatrix{$deliveryId} ) {
      $deliveryMatrix{$deliveryId} = {};
      $receipientsRef = $deliveryMatrix{$deliveryId};
      $receipientsRef->{to} = ();
      $receipientsRef->{cc} = ();
      $receipientsRef->{bcc} = ();
      $receipientsRef->{sentIds} = ();
      $receipientsRef->{MsgID} = $msgid;
      $receipientsRef->{subject} = $subject;
      $receipientsRef->{sender} = $sender;
      $receipientsRef->{body} = $body;
    }
    $receipientsRef = $deliveryMatrix{$deliveryId};
    push @{$receipientsRef->{sentIds}}, $markSentId;
    push @{$receipientsRef->{ $header }}, $personId
  }
  # don't forget the last hash fill.
  log( 'info', "Sending left overs" );
  if( %deliveryMatrix ) {
    sendHash( \%deliveryMatrix );
    $cnt++; # because of the last hash sending
  }

  return $cnt;
}


$dbh = Hermes::DBI->connect();

#
# This is the general query used by the most sending methods here. It is prepared and 
# stored in a module global variable, which only causes trouble if its used multiple 
# times.
#
my $sql;
$sql = "SELECT msg.*, mp.person_id, mp.id, mp.header, mtp.delivery_id FROM messages msg ";
$sql .= "JOIN messages_people mp ON (msg.id=mp.message_id) ";
$sql .= "LEFT JOIN msg_types_people mtp on (msg.msg_type_id=mtp.msg_type_id AND ";
$sql .= "mp.person_id=mtp.person_id) WHERE mp.sent=0 AND mp.delay=?";
$sql .= " ORDER BY msg.id LIMIT ?";
log( 'info', "MessageSender Base Query: $sql\n" );

$query = $dbh->prepare( $sql );


1;
