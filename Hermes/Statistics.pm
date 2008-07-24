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

use DBI;

use Hermes::Config;
use Hermes::DBI;
use Hermes::Log;


use vars qw(@ISA @EXPORT @EXPORT_OK $dbh %delayHash);

@ISA	    = qw(Exporter);
@EXPORT	    = qw( latestNMessages countMessages latestNRawNotifications countRawNotificationsInHours);

sub countRawNotificationsInHours( ;$ )
{
  my ($hours) = @_;

  $hours = 1 unless( $hours && 0+$hours >0 && 0+$hours < 128 );
  my $sql = "SELECT count(id) FROM notifications WHERE received > NOW() - INTERVAL $hours HOUR";

  my ($cnt) = $dbh->selectrow_array( $sql );
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

  return $dbh->selectall_arrayref( $sql, { Slice => {} } );
}


sub latestNMessages( ;$ )
{
  my ($cnt) = @_;

  $cnt = 10 unless( $cnt );
  $cnt = 10 unless ( $cnt =~ /^\d+$/ );
  $cnt = $cnt < 100 ? $cnt : 100;

  my $sql = "SELECT m.id as id, LEFT( m.subject, 40) as subject, m.created as created, "
    . "mt.msgtype as msgtype FROM messages m, msg_types mt "
    . "WHERE m.msg_type_id = mt.id order by created desc limit $cnt";

  return $dbh->selectall_arrayref( $sql, { Slice => {} } );
}

sub countMessages() {
  my $sql = "SELECT count(id) as count FROM messages;";
  my ($cnt) =@{ $dbh->selectcol_arrayref( $sql )};
  return $cnt;
}


#
# some initialisations
#
$dbh = Hermes::DBI->connect();

1;

