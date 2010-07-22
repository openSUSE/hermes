#
# Copyright (c) 2010 Klaas Freitag <freitag@suse.de>, Novell Inc.
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
package Hermes::Customize;

# This package can be changed to customize the behaviour of Hermes and 
# influence its decisions on who will get a message based on the parameters. 
# Currently Hermes calls two interface functions in the Customize.pm module.
# These need to be reimplemented!
#
# 1. generateSubscriberListRef( $msgType, $params );
#    This sub generates a list of users of the system who are subscribed to
#    the given MsgType with the also given set of parameters. This is the 
#    place where Filters need to be implemented on base of MsgType and 
#    the parameters. 
#
#    For example, the Message Type is PRODUCT_CHANGE, but your Hermes has
#    a subscription filter filtering on product = name all subscriptions
#    that do not pass this filter should be dropped out. Check the 
#    example implementation in Buildservice.pm for now. TODO
#
# 2. expandMessageTemplateParams( $templateObject, $msgRef )
#    This gets the message template (which is a HTML:Template object) and 
#    the message parameters. This sub can compute if the template contains
#    keys which need to be added to the values hash. 
#    The default implementation just returns the original parameter hash 
#    because nothing additionally is needed.
#
use strict;
use Exporter;

use Data::Dumper;

use Hermes::Config;
use Hermes::DB;
use Hermes::Log;
use Hermes::Util;

# =================================================================================
sub generateSubscriberListRef( $$ )
{
  my( $msgType, $paramRef ) = @_;

  # query the receivers
  my $sql = "SELECT subs.id subs.person_id, p.stringid ";
  $sql .= "FROM subscriptions subs, msg_types mt, persons p WHERE ";
  $sql .= "subs.msg_type_id = mt.id AND mt.msgtype=? AND subs.person_id=p.id AND enabled=1";

  my $query = dbh()->prepare( $sql );
  $query->execute( $msgType );
  my @subsIds;
  while( my ($subscriptId, $personId, $personString) = $query->fetchrow_array()) {
    # do filtering here if needed.
    push @subsIds, $subscriptId;
  }
  return \@subsIds;
}

# =================================================================================
sub expandMessageTemplateParams( $$ )
{
  my ( $paramHash, $tmpl ) = @_;

  return $paramHash;
}

1;
