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
package Hermes::Util;

use strict;
use Exporter;

use Hermes::Config;
use Hermes::DBI;
use Hermes::Log;

use Data::Dumper;

use vars qw(@ISA @EXPORT @EXPORT_OK $dbh );

@ISA	    = qw(Exporter);
@EXPORT	    = qw( notificationTemplateDetails notificationDetails);


=head1 NAME

notificationDetails() - get details about a notification 

=head1 SYNOPSIS

    use Hermes::Util;

    my $detailRef = notificationDetails( "checkhermes" );

=head1 DESCRIPTION

notificationDetail returns a hashref that contains all parameters belonging
to a type. The name of the type is in parameter _type.

=cut

sub notificationTemplateDetails($)
{
  my ($type) = @_;
  my %re;

  my $sql = "SELECT * FROM msg_types mt WHERE mt.msgtype=?";
  my $sth = $dbh->prepare( $sql );

  $sth->execute( $type );
  my ($id, $msgtype, $added, $defaultdelay) = $sth->fetchrow_array();

  $sql = "SELECT p.id, p.name FROM msg_types_parameters mtp, parameters p WHERE mtp.parameter_id = p.id ";
  $sql .= "AND mtp.msg_type_id=?";

  my $paramSth = $dbh->prepare( $sql );
  $paramSth->execute( $id );
  my @paramList;
  while( my( $id, $name) = $paramSth->fetchrow_array() ) {
     $re{$name} = $id;
     $re{$id} = $name;
     push @paramList, $name;
  }

  $re{_parameterList} = \@paramList;
  $re{_id} = $id;
  $re{_type} = $msgtype;
  $re{_added} = $added;
  $re{_defaultdelay} = $defaultdelay;

  return \%re;
}

sub notificationDetails($;$)
{
  my ($type, $id) = @_;

  my $infoRef = notificationTemplateDetails( $type );

  if( $infoRef && $infoRef->{_id} ) {
    my $msgTypeId = $infoRef->{_id};

    unless( $id ) {
      my $sql = "SELECT * FROM notifications WHERE msg_type_id=? ORDER BY received DESC LIMIT 1";
      my ($notiId, $msg_type_id, $received, $sender, $generated) = $dbh->selectrow_array( $sql, undef, $msgTypeId );
      $id = $notiId;
    }
    log('debug', "Getting values for id <$id>" );
    
    my $pSql = "SELECT id, parameter_id, value FROM notification_parameters WHERE notification_id=?";
    my $pSth = $dbh->prepare( $pSql );
    $pSth->execute( $id );

    while( my($npId, $paramId, $value ) = $pSth->fetchrow_array() ) {
      my $paramName = $infoRef->{$paramId};
      log( 'debug', "Setting parameter <$paramName> to value <nix>");

      if( $infoRef->{$paramName} ) {
	log( 'debug', "Setting parameter <$paramName> to value <$value>");
	# the parameter actually exists.
	$infoRef->{$paramName} = $value;
      }
    }
  } else {
    log( 'error', "Could not find msg_type <$type>" );
  }
  return $infoRef;
}


#
# some initialisations
#
$dbh = Hermes::DBI->connect();

1;
