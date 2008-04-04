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
use MIME::Lite;

use vars qw(@ISA @EXPORT @EXPORT_OK $dbh %delayHash);

@ISA	    = qw(Exporter);
@EXPORT	    = qw( newMessage sendNotification delayStringToValue 
		  SendNow SendMinutely SendHourly SendDaily SendWeekly 
		  SendMonthly HERMES_DEBUG );
@EXPORT_OK  = qw( getSnippets createMimeMessage markSent );



# Message delay constants:
use constant HERMES_DEBUG   => -1;  # Debug mode: message delivery is faked.

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

Parameter 4 is specifies the delay.  The hermes system will wait this
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

    # This call returns the id of the type. If that does not exist, it is created.
    my $typeId = createMsgType( $type );

    # check for a user

    # Add the new message to the database.
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
	$deliveryID = $Config::DefaultDelivery unless( defined $deliveryID );

	log( 'info', "User delay id <$delayID> for type <$typeId> for person <$person_id>" );
	$sth->execute( ($person_id, $addresses{$person}, $delayID ) );
      } else {
	log( 'error', "Unknown or invalid person, can not store message!" );
      }
    }

    # some of the receipients might want the message immediately.
    sendMessage( $id );

    return $id;
}


sub sendNotification( $$ )
{
  my ( $msgType, $params ) = @_;

  my $module = 'Hermes::Buildservice';

  push @INC, "..";

  my $id;
  unless( eval "use $module; 1" ) {
    log( 'warning', "Error with <$module>" );
    log( 'warning', "$@" );
  } else {
    my $msgHash = expandFromMsgType( $msgType, $params );
    if( $msgHash->{error} ) {
      log( 'error', "Could not expand message: $msgHash->{error}\n" );
    } else {
      # FIXME: Delay(SendNow) configurable
      $id = newMessage( $msgHash->{subject},   $msgHash->{body}, $msgHash->{type},
			SendNow(),   @{$msgHash->{to}},  @{$msgHash->{cc}},
			@{$msgHash->{bcc}},    $msgHash->{from}, $msgHash->{replyTo} );
      log( 'info', "Created new message with id $id" );
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
based on the provided message ID. It does not take the user set delays
into account, it sends the message immediately to all receipients.

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

  log('info', "Attempting to send message $msg_id IMMEDIATELY.");

  if ( HERMES_DEBUG ) {
    log( 'warning', "Mail sending switched off (debug) due to Config-Setting!" );
    $debug = 1;
  }

  # Fetch the addresses associated with this message.
  my @to;
  my @cc;
  my @bcc;
  my $replyTo;

  my @sentMarkIds;
  my $address_count = fetchAddresses($msg_id, SendNow(), \@to, \@cc, \@bcc, \@sentMarkIds, \$replyTo);

  # Ensure that we have at least one recipient address.
  unless ($address_count > 0) {
    # thats not neccessarily an error, might be that there is no receipient who
    # wants the message immediately
    log('info', 'No recipient addresses were found.');
    return;
  }

  # Retrieve the message's contents.
  my ($from, $subject, $content) = fetchMessage( $msg_id );

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
      if (markSent( @sentMarkIds )) {
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

######################################################################
# sub userDelaySetting
# -------------------------------------------------------------------
# Returns the user setting of the delay according to the given msg type.
######################################################################

sub userTypeSettings( $$ )
{
  my ( $typeId, $personId ) = @_;

  my $sql = "SELECT delay_id, delivery_id FROM msg_types_people WHERE msg_type_id=? AND person_id=?";
  my ($delayID, $deliveryID) = @{$dbh->selectcol_arrayref( $sql, undef, ($typeId, $personId ) )};

  return $delayID, $deliveryID;
}


######################################################################
# sub fetchAddresses
# -------------------------------------------------------------------
# Retrieves all of the addresses (To:, Cc:, Bcc:) associated with the
# given message ID and adds them to the provided address lists.
######################################################################

sub fetchAddresses($$\@\@\@\@\$)
{
    my ($msg_id, $delay, $to, $cc, $bcc, $sentMarkerIds, $replyTo) = @_;

    unless( $delay =~ /^\d+$/ ) {
      log('error', "Delay is not numeric, can not send message!");
      return 0;
    }

    unless( 0+$msg_id ) {
      log( 'error', "Message id is invalid: <$msg_id>" );
      return 0;
    }

    # Retrieve all of the addresses associated with this message ID.
    my $sql = "SELECT p.email, a.id, a.header FROM messages_people a, persons p ";
    $sql .= "WHERE a.delay=? AND a.person_id=p.id AND a.message_id=?";

    my $sth = $dbh->prepare($sql);
    $sth->execute( $delay, $msg_id );

    # use some hashes to assemble the addresses uniquely
    my %toh;
    my %cch;
    my %bcch;

    # Iterate through the addresses and separate them by header-type.
    while ( my ($mail, $sentMarkId, $header) = $sth->fetchrow_array ) {
      log( 'info', "Adding address $header: $mail" );

      push @$sentMarkerIds, $sentMarkId;

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

sub markSent( @ )
{
  my @msgPeopleIds = @_;

  my $sql = 'UPDATE LOW_PRIORITY messages_people SET sent = NOW() WHERE id = ?';
  my $sth = $dbh->prepare( $sql );

  my $res = 0;

  foreach my $id ( @msgPeopleIds ) {
    log( 'notice', "set messages_people id <$id> to sent!" );
    $res += $sth->execute( $id );
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

my $sth = $dbh->prepare( 'SELECT id, name FROM delays order by seconds asc' );
$sth->execute();
while ( my ($id, $name) = $sth->fetchrow_array ) {
  log( 'info', "Storing delay value $name with id $id" );
  $delayHash{$name} = $id;
}

log( 'info', "Config-Setting: DefaultDelivery: ". $Hermes::Config::DefaultDelivery );
1;

