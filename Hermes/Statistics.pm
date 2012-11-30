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
package Hermes::Statistics;

use strict;
use Exporter;

use Hermes::Config;
use Hermes::DB;
use Hermes::Log;


use vars qw(@ISA @EXPORT @EXPORT_OK %delayHash);

@ISA	    = qw(Exporter);
@EXPORT	    = qw( latestNMessages countMessages latestNRawNotifications countRawNotificationsInHours
                  unsentMessages );

sub countRawNotificationsInHours( ;$ )
{
  my ($hours) = @_;

  $hours = 1 unless( $hours && 0+$hours >0 && 0+$hours < 128 );
  my $sql = "SELECT count(id) FROM notifications WHERE received > NOW() - INTERVAL $hours HOUR";

  my ($cnt) = dbh()->selectrow_array( $sql );
  return $cnt;
}

sub latestNRawNotifications( ;$ )
{
  my ($cnt) = @_;
  $cnt = 20 unless( $cnt );
  $cnt = 20 unless( $cnt =~ /^\d+$/ );

  my $sql = "SELECT n.id as id, msgtypes.msgtype as type, n.received AS received ";
  $sql .= "FROM notifications n, msg_types msgtypes ";
  $sql .= "WHERE n.msg_type_id=msgtypes.id AND generated IS NULL limit $cnt";

  return dbh()->selectall_arrayref( $sql, { Slice => {} } );
}

sub unsentMessages()
{
  my $sql = "select d.name as delayString, s.delay_id as delayId, count(gn.id) as count ";
  $sql .= "FROM generated_notifications gn, delays d, subscriptions s ";
  $sql .= "WHERE gn.sent=0 AND gn.subscription_id = s.id AND s.delay_id=d.id ";
  $sql .= "GROUP BY s.delay_id";

  return dbh()->selectall_arrayref( $sql, { Slice => {} });
}

sub unsentMessagesDetail()
{
  my $sql = "SELECT delays.name as delayString, s.delay_id as delayId, \
  d.name as deliveryName, count(gn.id) as count \
  FROM generated_notifications gn \
  JOIN subscriptions subs ON subs.id = gn.subscription_id \
  JOIN deliveries d on(d.id = subs.delivery_id ) \
  JOIN delays ON(subs.delay_id = delays.id) \
  WHERE gn.sent = 0 AND subs.enabled=1 \
  GROUP BY subs.delay_id, delivery_id;"

  return dbh()->selectall_arrayref( $sql, { Slice => {} });
}

sub latestNMessages( ;$ )
{
  my ($cnt) = @_;

  $cnt = 10 unless( $cnt );
  $cnt = 10 unless ( $cnt =~ /^\d+$/ );
  $cnt = $cnt < 100 ? $cnt : 100;

  # my $sql = "SELECT m.id as id, LEFT( m.subject, 40) as subject, m.created as created, "
  #   . "mt.msgtype as msgtype FROM messages m, msg_types mt "
  #   . "WHERE m.msg_type_id = mt.id order by created desc limit $cnt";

  my $sql = "SELECT n.id as id, mt.msgtype as msgtype, n.received as created ";
  $sql .= "FROM notifications n, msg_types mt ";
  $sql .= "WHERE n.msg_type_id = mt.id ORDER BY n.received DESC LIMIT $cnt";

  return dbh()->selectall_arrayref( $sql, { Slice => {} } );
}

sub countMessages() {
  my $sql = "SELECT count(id) as count FROM notifications;";
  my ($cnt) =@{ dbh()->selectcol_arrayref( $sql )};
  return $cnt;
}


#
# some initialisations
#

1;

