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
use Hermes::Delivery::Mail;
use Hermes::Delivery::RSS;
use Hermes::Delivery::Jabber;
use Hermes::Person;
use Hermes::Message;

use vars qw(@ISA @EXPORT $dbh $query );

@ISA	    = qw(Exporter);
@EXPORT	    = qw( sendMessageDigest sendImmediateMessages deliveryIdToString );


######################################################################
# sub markSent
# -------------------------------------------------------------------
# Marks the message with the given ID as sent.  Returns true on
# success and false on failure.
######################################################################

sub markSent( @ )
{
  my ($msgPeopleIds) = @_;

  my $sql = 'UPDATE LOW_PRIORITY messages_people SET sent = NOW() WHERE id = ?';
  my $sth = $dbh->prepare( $sql );

  my $res = 0;

  foreach my $id ( @$msgPeopleIds ) {
    log( 'notice', "set messages_people id <$id> to sent!" );
    if( $Hermes::Config::Debug ) {
      log( 'info', "skipping to mark sent for messages_people id <$id>" );
    } else {
      $res += $sth->execute( $id );
    }
  }
  return ($res > 0);
}


######################################################################
# sub getSnippets
# -------------------------------------------------------------------
# Returns the snippets in text which is between the marker tags.
######################################################################

sub getSnippets($$;$) {
    my ($marker, $text, $max_number) = @_;
    $max_number = -1 if (!$max_number);

    my $openMarker = '<' . $marker . '>';
    my $closeMarker = '</' . $marker . ">";

    my @snippets = ();

    # Multiline and case-sensitive
    while ( $max_number && $text =~ /$openMarker(.+?)$closeMarker/gsi ) {
       push(@snippets, $1);
       $max_number = $max_number - 1;
       log('debug', "Found Snippet: '$marker'");
    }

    return @snippets;
}


=head1 NAME

sendMessageDigest() - sends a digest of queued messages

=head1 SYNOPSIS

    use Hermes::MessageSender;

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

  $query->execute( $delay, 1000 ); # FIXME make limit configurable

  my %personSorted;

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
      sendPersonSorted( \%personSorted );
    }
    $knownType = $type;

    $personSorted{$personId} = () unless $personSorted{$personId};

    # Store the message for further processing.
    push @{$personSorted{$personId}}, { MsgId => $msgid, Sender => $sender, Subject => $subject,
					Body => $body, Created => $created, Person => $personId,
					Header => $header, Delivery => $deliveryId, markSentId => $markSentId,
					Type => $type };
  }

  # sending left overs
  sendPersonSorted( \%personSorted );
}

sub sendPersonSorted( $ )
{
  my ($personSorted) = @_;

  # Now send every list of messages sorted by person Ids
  foreach my $personId ( keys %{$personSorted} ) {
    next unless( @{$personSorted->{$personId}} );
    log( 'info', "Sending digests for person <$personId> =====================================!" );
    my $deliverHashRef = digestList( @{$personSorted->{$personId}} );
    sendHash( $deliverHashRef );
    log( 'info', "Finished sending digests ====================================!" );
  }
  $personSorted = {};
}

sub deliveryIdToString( $ )
{
  my ($delivery) = @_;
  my $re;

  if( $delivery =~ /^\s*\d+\s*$/ ) {
    my $sql = "SELECT name FROM deliveries WHERE id=?";
    my $sth = $dbh->prepare( $sql );
    $sth->execute( $delivery );

    ($re) = $sth->fetchrow_array;
  }
  return $re;
}

sub typeIdToString( $ )
{
  my ($typeId) = @_;
  my $re;

  if( $typeId =~ /^\s*\d+\s*$/ ) {
    my $sql = "SELECT msgtype FROM msg_types WHERE id=?";
    my $sth = $dbh->prepare( $sql );
    $sth->execute( $typeId);

    ($re) = $sth->fetchrow_array;
  }
  return $re;
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

    # Search through the list of receipients if the new one is already in there.
    my $gotHim = 0;
    
    if( $receipientsRef->{ $msgRef->{Header} } ) {
      my @existingReceipients = @{$receipientsRef->{$msgRef->{Header}}};
      foreach ( @existingReceipients ) {
	if( $_ == $msgRef->{Person} ) {
	  $gotHim = 1;
	  last;
	}
      }
    }
    push @{$receipientsRef->{ $msgRef->{Header}}}, $msgRef->{Person} unless( $gotHim );
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
      $receipientsRef->{sender} = $sender;
    } else {
      if( $sender ne $msgRef->{Sender} ) {
	log( 'warning', "Sender differs between messages of the same types!" );
      }
    }

    if( $msgRef->{MsgId} != $oldMsgId ) {
      my ($bodyCont) = getSnippets('BODY', $msgRef->{Body}, 1);

      $bodyCont = $msgRef->{Body} if (!$bodyCont);
      $body .= $bodyCont . "\n==>\n";
    }

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
  my $res = 0;

  my $deliveryString = deliveryIdToString( $delivery );

  unless( $deliveryString ) {
    log('warning', "Problem: Delivery <$delivery> seems to be unknown!" );
  } else {
    log( 'info', "Delivery is <$delivery> => $deliveryString" );

    # FIXME: Better detection of the delivery type
    if( $deliveryString =~ /mail/i ) {
      sendMail( $msgRef );
      $res = 1;
    } elsif( $deliveryString =~ /jabber personal/i ) {
      sendJabber( $msgRef );
      $res = 1;
    } elsif( $deliveryString =~ /RSS/i ) {
      sendRSS( $msgRef );
      $res = 1;
    } else {
      log ( 'error', "No idea how to delivery message with delivery <$deliveryString>" );
    }
  }

  return $res;
}


#
# takes a hash that is structured by the delivery id where we loop over.
# Called from the sendImmediateMessage and from the digest list generator
#
# This sub has to set the human readable type from the id
#
sub sendHash( $ )
{
  my ( $deliveryMatrixRef ) = @_;

  log( 'info', "Delivering Msg: " . Dumper( $deliveryMatrixRef ) );
  foreach my $delivery ( keys %$deliveryMatrixRef ) {

    my $type = typeIdToString( $deliveryMatrixRef->{$delivery}->{type} );

    if( deliverMessage( $delivery,
			{ from       => $deliveryMatrixRef->{$delivery}->{sender},
			  to         => $deliveryMatrixRef->{$delivery}->{to},
			  cc         => $deliveryMatrixRef->{$delivery}->{cc},
			  bcc        => $deliveryMatrixRef->{$delivery}->{bcc},
			  type       => $type,
			  replyto    => $deliveryMatrixRef->{$delivery}->{sender},
			  subject    => $deliveryMatrixRef->{$delivery}->{subject},
			  body       => $deliveryMatrixRef->{$delivery}->{body},
			  msgid      => $deliveryMatrixRef->{$delivery}->{MsgID},
			  debug      => $Hermes::Config::Debug } ) ) {
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
      $receipientsRef->{type} = $type;
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
$sql = "SELECT msg.id, msg.msg_type_id, msg.sender, msg.subject, msg.body, msg.created, ";
$sql .= "mp.person_id, mp.id, mp.header, subs.delivery_id FROM messages msg ";
$sql .= "JOIN messages_people mp ON (msg.id=mp.message_id) ";
$sql .= "LEFT JOIN subscriptions subs on (msg.msg_type_id=subs.msg_type_id AND ";
$sql .= "mp.person_id=subs.person_id) WHERE mp.sent=0 AND mp.delay=?";
$sql .= " ORDER BY mp.person_id, msg.id LIMIT ?";
log( 'info', "MessageSender Base Query: $sql\n" );

#  SELECT msg.id, msg.msg_type_id, msg.sender, msg.subject, msg.body, msg.created, 
#  mp.person_id, mp.id, mp.header, subs.delivery_id FROM messages msg
#  JOIN messages_people mp ON (msg.id=mp.message_id)
#  LEFT JOIN subscriptions subs on (msg.msg_type_id=subs.msg_type_id AND 
#  mp.person_id=subs.person_id) WHERE mp.sent=0 AND mp.delay=?
#   ORDER BY msg.id LIMIT ?

$query = $dbh->prepare( $sql );


1;
