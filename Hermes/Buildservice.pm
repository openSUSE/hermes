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

use Hermes::Config;
use Hermes::DBI;
use Hermes::Log;

use Data::Dumper;

use vars qw(@ISA @EXPORT @EXPORT_OK $dbh );

@ISA	    = qw(Exporter);
@EXPORT	    = qw( expandFromMsgType );


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
  $re->{delay}   = 'default'; # replace by system default
  $re->{subject} = "Subject for message type <$type>";

  $re->{cc}      = undef;
  $re->{bcc}     = undef;
  $re->{replyTo} = undef;
  $re->{from} = $paramHash->{from} || "hermes\@opensuse.org";

  my $text;
  if( -r "messages/$type" ) {
    if( open F, "messages/$type" ) {
      $text = <F>;
      close F;
    }
  } else {
    log( 'warning', "Can not find message/$type text, using default" );
    $text = "Could not find the text for message type $type, this is the default "
      . "which is probably wrong.";
  }
  $re->{body} = $text;

  # query the receivers
  my $sql = "SELECT mtp.person_id FROM msg_types_people mtp, msg_types mt WHERE " 
    . "mtp.msg_type_id = mt.id AND mt.msgtype=?";
  $re->{to} = $dbh->selectcol_arrayref( $sql, undef, $type );

  log( 'info', "These receiver were found: " . join( ", ", @{$re->{to}} ) );

  return $re;
}

$dbh = Hermes::DBI->connect();

1;
