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

use Hermes::Message;
use Hermes::Config;
use Hermes::DBI;
use Hermes::Log;

use vars qw(@ISA @EXPORT @EXPORT_OK $dbh );

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

  if ( $type ) {
    log('notice', "Fetching messages with type '$type' and delay $delay");
    $sql = "SELECT msg.id, types.msgtype FROM messages msg, msg_types types WHERE ";
    $sql .= "msg.msg_type_id = types.id AND ";
    $sql .= "msg.sent=0 AND types.msgtype=? AND msg.delay=?";

    $sth = $dbh->prepare( $sql );
    $sth->execute( $type, $delay );
  } else {
    log('notice', "Fetching messages without type and delay $delay");

    $sql = "SELECT msg.id, types.msgtype FROM messages msg, msg_types types WHERE ";
    $sql .= "msg.msg_type_id = types.id AND ";
    $sql .= "msg.sent=0 AND msg.delay=?";

    $sth = $dbh->prepare( $sql );
    $sth->execute( $delay );
  }

  # Store all of the message ID's in a hash by type.
  my %messages;
  while ( my ($msg_id, $msg_type) = $sth->fetchrow_array ) {
    if (!defined $messages{$msg_type}) {
      $messages{$msg_type} = [];
    }
    push @{$messages{$msg_type}}, $msg_id;
  }
  my @types = keys %messages;

  # Iterate through the hash and assemble the digested mailings.
  foreach my $msg_type (keys %messages) {
    log('info', "Creating new '$msg_type' message digest.");

    # Build the MIME single-part message.
    my $msg_subject;
    if ( defined $subject ) {
      $msg_subject = $subject;
    } else {
      $msg_subject = "openSUSE: '$msg_type' message digest";
    }

    # Initialize the message body strings.
    my $body = '';
    my ($pre_body, $post_body);

    # Prepare a hash to hold the recipient address lists.
    my %addresses;
    $addresses{'to'} = ();
    $addresses{'cc'} = ();
    $addresses{'bcc'} = ();
    $addresses{'replyTo'} = '';
    my $from;

    # Sort the message ID's in ascending numeric order.
    my @msg_ids = sort {$a <=> $b} @{$messages{$msg_type}};
    my @markSentIds;

    # Iterate through the messages, adding a new MIME part for each one.
    foreach my $msg_id (@msg_ids) {

      log('info', "Adding message $msg_id to digest.");

      # Fetch and store this message's address lists.
      fetchAddresses( $msg_id, Delay(), \@{$addresses{'to'}}, \@{$addresses{'cc'}},
		     \@{$addresses{'bcc'}}, \@markSentIds, \$addresses{'replyTo'} );

      # Fetch the message.
      my ($singlefrom, $subject, $content) = fetchMessage($msg_id);
      log( 'warning', "digest messages with different from settings" ) if( $singlefrom ne $from );
      $from = $singlefrom;

      # Extract the "pre-body" and "post-body" text segments.
      unless (defined $pre_body && defined $post_body) {
	($pre_body)  = getSnippets('PRE',  $content, 1);
	($post_body) = getSnippets('POST', $content, 1);
      }

      # Append the <body> snippet to the message body.
      my ($body_cont) = getSnippets('BODY', $content, 1);
      $body_cont = $content if (!$body_cont);
      $body .= $body_cont . "\n";
    }

    # Add the message contents (data) to the MIME message.
    $body = ($pre_body||'') . ($body||'') . ($post_body||'');

    if ( createMimeMessage( { from => $from,
			      to      => \@{$addresses{'to'}},
			      cc      => \@{$addresses{'cc'}},
			      bcc     => \@{$addresses{'bcc'}},
			      replyto => $addresses{'replyto'},
			      subject => $subject,
			      body    => $body,
			      debug   => 1 } ) ) {

      # Now mark all digested messages sent
      markSent( @markSentIds );
    }
  }

  # Return the number of digests sent.
  return (0 + scalar(@types));
}

sub sendImmediateMessages(;$)
{
  my ($type) = @_;

  # FIXME: Honour message type parameter

  my $sql;
  $sql = "SELECT msg.*, mp.person_id, mp.id, mp.header, mtp.delivery_id FROM messages msg ";
  $sql .= "JOIN messages_people mp ON (msg.id=mp.message_id) ";
  $sql .= "LEFT JOIN msg_types_people mtp on (msg.msg_type_id=mtp.msg_type_id AND ";
  $sql .= "mp.person_id=mtp.person_id) WHERE mp.sent=0 AND mp.delay=" . SendNow;
  $sql .= " ORDER BY msg.id LIMIT 1000";

  print "SQL: $sql\n";

  my $cnt = 0;
  my %receipients;
  my $last_id = -1;
  my @markSentIds;

  while ( my ( $msgid, $type, $sender, $subject, $body, $created, $personId, $markSentId,
	       $header, $deliveryId ) = $dbh->selectrow_array( $sql )) {
    # The query returns a message id multiple times, depending on the amount of 
    # receipients.
    push @markSentIds, $markSentId;

    log( 'info', "Sending <$msgid> with <$personId> as <$header>" );
    if ( $msgid != $last_id ) {
      # we have a new id and do the actual sending. 
      if ( $last_id > -1 ) {
	# we're not in the start of the processing
	if ( createMimeMessage( { from       => 'hermes\@suse.de',
				  to         => $receipients{'to'},
				  cc         => $receipients{'cc'},
				  bcc        => $receipients{'bcc'},
				  replyto    => $sender,
				  subject    => $subject,
				  body       => $body,
				  debug      => 1 } ) ) {
	  markSent( @markSentIds );
	  @markSentIds = ();
	}
      }
      $last_id = $msgid;
      $receipients{to}  = ();
      $receipients{cc}  = ();
      $receipients{bcc} = ();
    }
    push @{$receipients{ $header }}, $personId
  }


  return $cnt;
}


$dbh = Hermes::DBI->connect();

1;
