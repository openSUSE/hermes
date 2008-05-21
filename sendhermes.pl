#!/usr/bin/perl -w
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
# This a command line tool to schedule messages in hermes
#

use strict qw 'vars';
use Getopt::Std;
use Hermes::MessageSender;
use Hermes::Message;

use vars qw ($opt_t $opt_h $opt_d);

# -d : delay-string
# -t : message type

# SendMail Interface to hermes.

my $subject;
my $text;
my %receiver;


sub help()
{
  print<<END

NAME
    sendhermes.pl - commandline tool to hand over a message to hermes.
    
SYNOPSIS

    sendhermes [option...] < message

DESCRIPTION

    Handing over messages that look like ordinary mail messages to the 
    hermes system. The messages that are fed in have to follow a simplified 
    rfc 822 format which describes internet email. 
    
    The message contains a header and a body, separated by two empty lines.
    The header has some header fields. These header fields are recognised by 
    hermes:
    
          to: Receivers mail address
          cc: Carbon copy receivers
         bcc: blind carbon copy receivers
     subject: A descriptive one line subject
        from: the sender address
     replyto: a reply to address
        type: a hermes message type
    
    The message body is simply the text.
    
    Options:
     -d: The delay string, like SEND_NOW, SEND_HOURLY, SEND_DAILY, SEND_WEEKLY
         or SEND_MONTHLY
     -t: the message type, overwrites a type set in the incoming message
     -h: this help message

EXAMPLE:

    Send a message stored in /tmp/foo.mail:

      sendhermes.pl -d SEND_NOW < /tmp/foo.mail

END
;

exit;

}

sub error(;$) 
{
    my ($msg) = @_;

    print "ERROR: $msg\n";
    exit(1);
}

getopts('d:t:h' );

help() if( $opt_h );

my $mail = join( '', <> );
my ($header, $body);

if( $mail =~ /(.+?)(\n{3})(.+)/s ) {
  $header = $1;
  $body = $3;
} else {
  error( "Could not parse message" );
}

my @headerLines = split( /\n/, $header  );

my @headertags = ( 'to', 'cc', 'bcc', 'from', 'replyto' );
my $hregexp = join( '|', @headertags );
my $type;

foreach my $l ( @headerLines ) {
  if( $l =~ /^\s*($hregexp)\s*:\s*(\S+)\s*/i ) {
    print "###<$l>\n";
    my $tag = lc $1;
    my $addressee = $2;
    $receiver{$tag} = () unless( $receiver{$tag} );
    push @{$receiver{$tag} }, $addressee;
  } elsif( $l =~ /^\s*subject\s*:\s*(.+)\s*$/i ) {
    $subject = $1;
  } elsif( $l =~ /^\s*type\s*:\s*(\w+)\s*$/i ) {
    $type = $1;
  } else {
    print "Unrecognised header line <$l>\n";
  }
}

print "==============================================================================\n$body\n";

$type = $opt_t if( $opt_t );

error( "No type given, use either command option or in text!" ) unless( $type );

my $delayID = delayStringToValue( $opt_d );

print "Type: <$type> and delay <$delayID>\n";
error( "No message type specified, use -t to do so!" ) unless( $type );

my $id = newMessage( $subject, $body, $type, $delayID, @{$receiver{'to'}}, @{$receiver{'cc'}}, 
		     @{$receiver{'bcc'}}, 
		     shift @{$receiver{'from'}}, shift @{$receiver{'replyto'}} ); 
print "Message added with id=<$id>\n";


