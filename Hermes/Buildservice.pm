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
package Hermes::Buildservice;

use strict;
use Exporter;

use HTML::Template;

use Hermes::Config;
use Hermes::DBI;
use Hermes::Log;
use Hermes::Person;

use Data::Dumper;

use vars qw(@ISA @EXPORT @EXPORT_OK $dbh );

@ISA	    = qw(Exporter);
@EXPORT	    = qw( expandFromMsgType );

our $hermesUserInfoRef;

#
# expand the message, that means
# generate the @to, @cc and @bcc list
# set text and subject
#
# The returned hash must contain the following tags:
# subject   - the message subject
# body      - the message body
# type      - the message type, as coming into the method
# delay     - the default delay, might be overridden by user setting later
# to        - array ref to a list of to receivers
# cc        - array ref to a list of cc receivers
# bcc       - array ref to a list of bcc receivers.
# from      - sender string
# replyTo   - reply to string
#
sub expandFromMsgType( $$ )
{
  my ($type, $paramHash) = @_;

  my $re;
  $re->{type}    = $type;
  $re->{delay}   = 0; # replace by system default
  $re->{subject} = "Subject for message type <$type>";

  $re->{cc}      = [];
  $re->{bcc} = undef;

  $re->{replyTo} = undef;
  $re->{from} = $paramHash->{from} || "hermes\@opensuse.org";

  my $text;
  my $filename = $Hermes::Config::HerminatorDir . "/notifications/" . lc $type . ".tmpl";
  log( 'info', "template filename: <$filename>" );

  if( -r "$filename" ) {
    my $tmpl = HTML::Template->new(filename => "$filename",
				   die_on_bad_params => 0 );
    # Fill the template
    $tmpl->param( $paramHash );
    $text = $tmpl->output;

    if( $text =~ /^\s*\@subject: ?(.+)$/im ) {
      $re->{subject} = $1;
      log( 'info', "Extracted subject <$re->{subject}> from template!" );
      $text =~ s/^\s*\@subject:.*$//im;
    }
    log('info', "Template body: <$text>" );

  } else {
    log( 'warning', "Can not find <$filename>, using default" );
    $text = "Hermes received the notification <$type>\n\n";
    if( keys %$paramHash ) {
      $text .= "These parameters were added to the notification:\n";
      foreach my $key( keys %$paramHash ) {
	$text .= "   $key = " . $paramHash->{$key} . "\n";
      }
    }
  }

  $re->{body} = $text;

  # query the receivers
  my $sql = "SELECT mtp.person_id FROM msg_types_people mtp, msg_types mt WHERE " 
    . "mtp.msg_type_id = mt.id AND mt.msgtype=?";
  $re->{to} = $dbh->selectcol_arrayref( $sql, undef, $type );

  my $hermesid = $hermesUserInfoRef ? $hermesUserInfoRef->{id} : undef;
  if( $hermesUserInfoRef ) {
    $re->{bcc}     = [ $hermesUserInfoRef->{id} ];
  }

  log( 'info', "These receiver were found: " . join( ", ", @{$re->{bcc}} ) );

  return $re;
}

$dbh = Hermes::DBI->connect();

$hermesUserInfoRef = personInfo( 'hermes2' ); # Get the hermes user info
log( 'info', "The hermes user id is " . $hermesUserInfoRef->{id} );

1;
