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
package Hermes::Delivery::Mail;

use strict;
use Exporter;

use Data::Dumper;
use MIME::Lite;

use Hermes::Config;
use Hermes::Log;
use Hermes::Person;

use vars qw( @ISA @EXPORT @EXPORT_OK );

@ISA	    = qw(Exporter);
@EXPORT	    = qw( sendMail );

#
# Send a message by mail.
#  from       => Sender Address as String
#  to         => Array ref of person ids
#  cc         => Array ref of person ids
#  bcc        => Array ref of person ids
#  replyto    => same as sender FIXME !
#  subject    => string
#  body       => string
#  _debug      => debug flag, true if debug.
# 
sub sendMail( $ )
{
  my ($msg) = @_;

  my $pSenderRef = personInfo( $msg->{from} );
  # get the emails out of the person module
  
  my $invalidMails = 0;
  my @t;
  foreach my $p ( @{$msg->{to} } ) {
    my $pInfoRef = personInfo( $p );
    if( $pInfoRef->{email} eq 'notset@opensuse.org' ) {
      $invalidMails++;
    } else {
      push @t, $pInfoRef->{email} if( $pInfoRef->{email} );
    }
  }
  
  my $toCnt = @t;
  if( $toCnt == 0 ) { # No valid receivers found
    if( $invalidMails > 0 ) {
      # We do not have valid to receivers of the email, but we claim success
      # to the caller. That makes the notification marked as sent.
      return 1;
    }
    return 0;
  }


  my $mime_msg = MIME::Lite->new( From    => ($pSenderRef->{email} || $Hermes::Config::DefaultSender),
				  Subject => $msg->{subject},
				  Data    => $msg->{body},
				  Type    => 'TEXT'
				);

  # FIXME: Parametercheck.

  my $toLine = join( ', ', @t );
  log( 'info', "To-line: $toLine" );
  $mime_msg->add('To' => $toLine );

  @t = ();
  foreach my $p ( @{$msg->{cc} } ) {
    my $pInfoRef = personInfo( $p );
    push @t, $pInfoRef->{email};
  }
  $mime_msg->add('Cc' => join( ', ', @t ) );

  @t = ();
  foreach my $p ( @{$msg->{bcc} } ) {
    my $pInfoRef = personInfo( $p );
    push @t, $pInfoRef->{email};
  }
  $mime_msg->add('Bcc' => join( ', ', @t ) );

  if( $msg->{replyto} ) {
    my $pReplyToRef = personInfo( $msg->{replyto} );

    $mime_msg->add('reply-to' => $pReplyToRef->{email} || "unknown" ) ;
  }

  $mime_msg->add('X-hermes-msg-type' => $msg->{type} ) if( $msg->{type} );
  $mime_msg->replace('Precedence' => 'bulk');
  $mime_msg->replace('X-Mailer' => 'openSUSE Notification System');

  # set the date manually because MIME:Lite does it with UT instead of UTC
  my ($u_wdy, $u_mon, $u_mdy, $u_time, $u_y4) = split /\s+/, gmtime()."";
  # Maybe alternatively use POSIX::strftime to format in local time.
  my $date = "$u_wdy, $u_mdy $u_mon $u_y4 $u_time +0000";
  $mime_msg->replace("date", $date);


  # Send the message.
  my $res = 1;
  if ($msg->{_debug} ) {
    log('info', "Saving debug mail for noti Id " . $msg->{_notiId} );
    saveDebugMail( $msg->{_notiId}, $toLine, $mime_msg );
    # print STDERR "[ Hermes Mail Module Debug: Start of MIME-encoded message ]\n";
    # print STDERR $mime_msg->as_string;
    # print STDERR "\n[ Hermes Mail Module Debug: End of MIME-encoded message ]\n";
  } else {
    $res = 0 unless $mime_msg->send();
  }

  return $res;
}


sub saveDebugMail( $$$ )
{
  my ($id, $rec, $msg) = @_;

  my $path = "./debugmails/";
  return unless( $rec );

  mkdir( $path, 0777 ) unless( -e $path );
  my $file = $rec . "_$id";
  $file =~ s/\@/_/;

  if( open F, ">$path/$file" ) {
    $msg->print( \*F );
    close F;
  }
}


1;
