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

use Data::Dumper;
use MIME::Lite;

use vars qw(@ISA @EXPORT @EXPORT_OK $dbh );

@ISA	    = qw(Exporter);
@EXPORT	    = qw(newMessage sendMessageDigest HERMES_DEBUG);

@EXPORT_OK  = qw(SEND_NOW SEND_HOURLY SEND_DAILY SEND_WEEKLY SEND_MONTHLY);

# Message delay constants:
use constant HERMES_DEBUG   => -1;  # Debug mode: message delivery is faked.
use constant SEND_NOW	    =>  0;  # Message should be sent immediately.
use constant SEND_HOURLY    =>  1;  # Messages should be sent once, on the hour.
use constant SEND_DAILY	    =>  2;  # Messages should be sent once a day.
use constant SEND_WEEKLY    =>  3;  # Messages should be sent once a week.
use constant SEND_MONTHLY   =>  4;  # Messages should be sent once a month.

=head1 NAME

Hermes::Message - a module to post messages to the hermes system

=head1 SYNOPSIS

    use Hermes::Message qw(:DEFAULT /^SEND_/);

=head1 DESCRIPTION

This chapter describes the basic idea behind the Hermes message handling

=head2 The Idea

Hermes abstracts the sending of a message to the user. That means that
a system that wants to send a notification to a user hands the message
to Hermes. Hermes lets the user decide which way the message should
approach him. Both the way of message delivery and the amount of sent
messages is adjustable by the user.

1. Way of Message delivery: Hermes is able to deliver the messages in
several ways: Web access, mail, news but also instant messages like
jabber.

2. Amount of Messages: Hermes is able to create message digests, that
are collected messages to one, i.e. all build-failed messages are
combined to a digest one sent at midnight that contains a list of all
failed packages.

This module provides methods to store messages to the Hermes system
and thus should be used by systems that needs to notify users.


=head2 Current Status

Currenty there are methods to send messages either as digest or immediately
by mail. There is no support for other sending agents for other formats at
the moment.

Furthermore this module contains the  method L<sendMessageDigest> that 
assembles digest mails. It must be called by a script that runs in a cron
environment firing every hour. 

Unfortunately Hermes does not yet honour user input, at the moment messages
are sent the way the sending client suggests. Later the user input will
override the client settings.

Attachments are not yet supported.

=head2 Usage

Messages can be sent by the funciton L<newMessage>.

L<newMessage> stores the message to hermes' database and depending on the
delay settings it sends the message immediately or as a digested message
later together with messages of the same type.

The message text to send is stored in one Perl string which contains
tags.  The tags need a opening tag and a closing tag, which is the
same as the opening tag with a prefixed / (slash).

For example: 

The text of every single mail inside the BODY tags is stored and put to the
collection mail. The text between PRE and POST is assembled around the
collection mail (grammarwise a collection mail is PRE? BODY+ POST? ATTACHMENT*)

An ATTACHMENT needs to contain the tags FILENAME MIMETYPE and DATA. If the
mail contains attachments it will be encoded as mime multipart message. Otherwise
it will be simple text.

=cut


=head1 NAME

newMessage() - queues a new message for sending

=head1 SYNOPSIS

    use Hermes::Message qw(:DEFAULT /^SEND_/);

    my $subject = 'Test Subject';
    my $text = "Hi. <BODY>This is a test.</BODY>";
    my $type = 'test';
    my $delay = SEND_NOW; # send now !
    my @to = ('goof@universe.com', 'freitag@suse.de');
    my @cc = ();
    my @bcc = ('bigbrother@suse.de');

    newMessage($subject, $text, $type, $delay, @to, @cc, @bcc);

=head1 DESCRIPTION

newMessage() queues a new message in hermes.

=head1 PARAMETERS

Parameter 1 specifies the message's Subject: line.

Parameter 2 specifies the message's text, including tags.  Allowed tags are:

    <PRE> : Text to be extracted and put into the digest before the content
    <BODY>: Text to be cut and included in a digest mailing.
    <POST>: Text to be extracted and put into the digest after the content

Parameter 3 is the message type. The type is a free string. Messages of the
same type are grouped together in digest mailings.

Parameter 4 is specifies the delay.  The pdb mail system will wait this
period of time before sending the message.  If this value is negative,
the pdb mail system will enter debug mode and fake the mail delivery by
writing the message to standard error.

Values for the delay are defined as constants (SEND_*):

    HERMES_DEBUG        # Debug mode: message delivery is faked.
    SEND_NOW		# Message should be sent immediately.
    SEND_HOURLY		# Messages should be sent once, on the hour.
    SEND_DAILY		# Messages should be sent once a day.
    SEND_WEEKLY		# Messages should be sent once a week.
    SEND_MONTHLY	# Messages should be sent once a month.

Note that these constants must be explictly imported into the current
namespace.  For example:

    use DB::pdbMail qw(:DEFAULT /^SEND_/);

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

Returns the message's ID on success or -1 on failure.

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

    # XXX: Perhaps this should be configurable on a per-message basis.
    if(!defined($from)){
    	$from = 'hermes@opensuse.org';
    }

    my $typeId = createMsgType( $type );

    # Add the new message to the database.
    my $sql = 'INSERT INTO messages( msg_type_id, sender, subject, ' .
      'body, delay, created, sent) ' .
	'VALUES (?, ?, ?, ?, ?, NOW(), 0)';
    $dbh->do( $sql, undef, ( $typeId, $from, $subject, $text, $delay ) );

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
    my $sth = $dbh->prepare( "INSERT INTO addresses( msg_id, person_id, header) "
                            ."VALUES ($id, ?, ? )");

    # Adds the addresses to the MailAddresses table.
    foreach my $person (keys %addresses) {
      my $person_id = emailToPersonID( $person );
      if( $person_id ) {
	$sth->execute( ($person_id, $addresses{$person}) );
      } else {
	log( 'error', "Unknown or invalid person, can not store message!" );
      }
    }

    # Should we send this message immediately?
    my $cnt = $delay+0;
    log( 'info', "Delay is set to <$delay>" );
    log( 'info', "Delay is set to <$cnt>" );

    if ( $delay == SEND_NOW) {
    	log('info', 'Sending message immediately.');
	unless (sendMessage($id)) {
	    return -1;
	}
    } elsif ( $delay == HERMES_DEBUG) {
    	log('info', 'Debug: Faking message delivery.');
	unless (sendMessage($id, 1)) {
	    return -1;
	}
    }

    return $id;
}



=head1 NAME

sendMessage() - sends a single queued message

=head1 SYNOPSIS

  use Hermes::Message;

  my $msg_id = 24;	# Send message with ID 24.

  sendMessage( $msg_id );

=head1 DESCRIPTION

pdbSendMessage() will send a single message that is queued in the system,
based on the provided message ID.

=head1 PARAMETERS

Parameter 1 specifies the message ID of the message to send.

Parameter 2 is an optional debug flag.

=head1 RETURN VALUE

Returns true on success or false on failure.

=cut

sub sendMessage($;$)
{
  my ($msg_id, $debug) = @_;

  unless ($msg_id =~ /^\d+$/) {
    log('error', "ID ($msg_id) is not numeric.");
    return;
  }

  log('info', "Attempting to send message $msg_id.");

  if ( HERMES_DEBUG ) {
    log( 'warning', "Mail sending switched off (debug) due to Config-Setting!" );
    $debug = 1;
  }

  # Fetch the addresses associated with this message.
  my @to;
  my @cc;
  my @bcc;
  my $replyTo;

  my $address_count = fetchAddresses($msg_id, \@to, \@cc, \@bcc, \$replyTo);

  # Ensure that we have at least one recipient address.
  unless ($address_count > 0) {
    log('error', 'No recipient addresses were found.');
    return;
  }

  # Retrieve the message's contents.
  my ($from, $subject, $content) = fetchMessage($msg_id);

  # retain only the body segment of this message.
  my ($body) = getSnippets('BODY', $content, 1);
  $body = $content if (!$body); # otherwise use whole body

  # my @attachments = getSnippets('ATTACHMENT', $content);

  # Prepare to send the message.
  if (defined $subject || defined $body) {

    # Attachments not supported for the moment  - FIXME
    # if (scalar @attachments) {
    #   $mime_msg = MIME::Lite->new(
    # 				  From	  => formatAddress($from, $sender_name),
    # 				  Subject => $subject,
    # 				  Type    => 'multipart/mixed'
    # 				 );
    #   $mime_msg->attach(Type     => 'TEXT',
    # 			Data     => $body
    # 		       );
    #   foreach my $attachment (@attachments) {
    # 	my ($data)     = getSnippets('DATA', $attachment, 1);
    # 	my ($filename) = getSnippets('FILENAME', $attachment, 1);
    # 	my ($mimetype) = getSnippets('MIMETYPE', $attachment, 1);
    # 	$mime_msg->attach(Type     => $mimetype,
    # 			  Data     => $data,
    # 			  Filename => $filename );
    #   }
    # } else {
    if( createMimeMessage( { from => $from,
			     to      => \@to,
			     cc      => \@cc,
			     bcc     => \@bcc,
			     replyto => $replyTo,
			     subject => $subject,
			     body    => $body,
			     debug   => 1 } ) ) {

      # Mark this message as sent by updating the MsgSent timestamp.
      if (markSent($msg_id)) {
	log('notice', "Message $msg_id was sent successfully!");
      } else {
	log('error', "Failed marking message $msg_id as sent!");
      }
    }
  } else {
    log('error', 'Bad message: no body or subject!');
    return;
  }

  return 1;
}



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

  if ( HERMES_DEBUG ) {
    log( 'warning', "Mail sending switched off (debug) due to Config-Setting!" );
    $debug = 1;
  }

  # Find all messages of the same type and delay that haven't been sent.
  my $sql = '';
  my $sth;

  if ( $type ) {
    log('notice', "Fetching messages with type '$type'.");
    $sql = "SELECT msg.id, types.msgtype FROM messages msg, msg_types types WHERE ";
    $sql .= "msg.sent=0 AND types.msgtype=? AND msg.delay=?";

    $sth = $dbh->prepare( $sql );
    $sth->execute( $type, $delay );
  } else {
    $sql = "SELECT msg.id, types.msgtype FROM messages msg, msg_types types WHERE ";
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

    # Iterate through the messages, adding a new MIME part for each one.
    foreach my $msg_id (@msg_ids) {

      log('info', "Adding message $msg_id to digest.");

      # Fetch and store this message's address lists.
      fetchAddresses( $msg_id, \@{$addresses{'to'}}, \@{$addresses{'cc'}},
		     \@{$addresses{'bcc'}}, \$addresses{'replyTo'} );

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
      markSent( \@msg_ids );
    }
  }

  # Return the number of digests sent.
  return (0 + scalar(@types));
}



######################################################################
# sub fetchAddresses
# -------------------------------------------------------------------
# Retrieves all of the addresses (To:, Cc:, Bcc:) associated with the
# given message ID and adds them to the provided address lists.
######################################################################

sub fetchAddresses($\@\@\@\$)
{
    my ($msg_id, $to, $cc, $bcc, $replyTo) = @_;

    return 0 unless( 0+$msg_id );

    # Retrieve all of the addresses associated with this message ID.
    my $sql = "SELECT p.email, a.header FROM addresses a, persons p WHERE a.person_id=p.id AND a.msg_id=?";
    my $sth = $dbh->prepare($sql);
    $sth->execute( $msg_id );

    # use some hashes to assemble the addresses uniquely
    my %toh;
    my %cch;
    my %bcch;

    # Iterate through the addresses and separate them by header-type.
    while ( my ($mail, $header) = $sth->fetchrow_array ) {
      log( 'info', "Adding address $header: $mail" );

      if ($header eq 'to' ) {
	$toh{$mail} = 1;
      } elsif ($header eq 'cc' ) {
	$cch{$mail} = 1;
      } elsif ($header eq 'bcc') {
	$bcch{$mail} = 1;
      } elsif ($header eq 'reply-to' ) {
	$$replyTo = $mail;
      } else {
	log('warning', "Unknown header: <$header> - skipping");
	next;
      }
    }

    @$to =  keys %toh;
    @$cc =  keys %cch;
    @$bcc = keys %bcch;

    my $cnt = (scalar keys %toh) + (scalar keys %cch) +  (scalar keys %bcch);
    # Return the number of addresses added to the lists.
    # Does _not_ add the ones for replyTo, because they are not usefull in decision,
    # if there are people to receive the mail.
    return $cnt;
}


######################################################################
# sub fetchMessage
# -------------------------------------------------------------------
# Retrieves the requested message from the database based on the
# given message ID.
# Returns the message's from, subject, and body values.
######################################################################

sub fetchMessage($)
{
  my ($msg_id) = @_;

  # Retrieve the message's contents.
  log('info', "Retrieving message $msg_id.");
  my $sql = "SELECT sender, subject, body FROM messages where id= ?";
  my $sth = $dbh->prepare( $sql );
  $sth->execute( $msg_id );
  return $sth->fetchrow_array;
}

######################################################################
# sub createMimeMessage
# -------------------------------------------------------------------
# Creates a new mail message with MIME::Lite and sends it
#
# The function accepts a hash ref as incoming parameter that contains
# the following data:
# subject -> the mail subject (string)
# body    -> the text
# from    -> the sender, formatted (string)
# replyto -> the reply to  (string)
# to      -> a list of receipients (arrayref)
# cc      -> a list of cc'ed receipients (arrayref)
# bcc     -> a list of bcc'ed receipients (arrayref)
#
######################################################################
sub createMimeMessage( $ ) 
{
  my ($msg) = @_;

  my $mime_msg = MIME::Lite->new( From	  => $msg->{from},
				  Subject => $msg->{subject},
				  Data    => $msg->{body} );

  # FIXME: Parametercheck.

  my $t = join( ', ', @{$msg->{to} } );
  log( 'info', "To-line: $t" );
  $mime_msg->add('To' => $t );

  $t = join( ', ', @{$msg->{cc} } );
  $mime_msg->add('Cc' => $t );

  $t = join( ', ', @{$msg->{bcc} } );
  $mime_msg->add('Bcc' => $t );

  $mime_msg->add('reply-to' => $msg->{replyto} ) if( defined $msg->{replyto} );

  $mime_msg->replace('X-Mailer' => 'openSUSE Notification System');

    # Send the message.
  if (defined $msg->{debug} && $msg->{debug} ) {
    print STDERR "[ Debug: Start of MIME-encoded message ]\n";
    print STDERR $mime_msg->as_string;
    print STDERR "\n[ Debug: End of MIME-encoded message ]\n";
  } else {
    $mime_msg->send();
  }

  1;
}

######################################################################
# sub formatAddress
# -------------------------------------------------------------------
# Creates a pretty mail address from an email address and a fullname.
######################################################################

sub formatAddress($$)
{
    my ($login, $fullname) = @_;

    if( defined $fullname && $fullname =~ /\w+/ )
    {
	return sprintf("\"%s\" <%s>", $fullname, $login);
    } 
    else
    {
	return $login;
    }
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

######################################################################
# sub markSent
# -------------------------------------------------------------------
# Marks the message with the given ID as sent.  Returns true on
# success and false on failure.
######################################################################

sub markSent($)
{
    my ($msg_id) = @_;
    log( 'info', "SCALAR: " . ref( $msg_id ));
    my $sth = $dbh->prepare( 'UPDATE LOW_PRIORITY messages SET sent = NOW() WHERE id = ?' );

    my $res = 0;

    if( ref $msg_id ne 'ARRAY') {
      log('notice', "Marking message $msg_id as sent.");
      $res = $sth->execute( $msg_id );
    } else {
      foreach my $id ( @$msg_id ) {
	log( 'notice', "Bulk message sent <$id>" );
	$res += $sth->execute( $id );
      }
    }
 
    return ($res > 0);
}

sub createMsgType( $ ) 
{
  my ($msgType) = @_;

  my $sth = $dbh->prepare( 'SELECT id FROM msg_types WHERE msgtype=?' );
  $sth->execute( $msgType );

  my ($id) = $sth->fetchrow_array();

  unless( $id ) {
    my $sth1 = $dbh->prepare( 'INSERT INTO msg_types (msgtype) VALUES (?)' );
    $sth1->execute( $msgType );
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
  log( 'info', "Returning id <$id> for msg_type <$email>" );
  return $id;
}


$dbh = Hermes::DBI->connect();

1;

