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
package Hermes::DB;

use strict;
use Exporter;

use Hermes::Config;
use Hermes::Log;
use Hermes::DBI;

use vars qw(@ISA @EXPORT $myDbh $dbName );

@ISA	    = qw(Exporter);
@EXPORT	    = qw(dbh connectDB);


sub connectDB( ;$ )
{
  my ($db) = @_;
  unless( $dbName ) {
    $dbName = $db || 'default';
  }
  log( 'info', "** Connecting to database <$dbName>" );
  $myDbh = Hermes::DBI->connect( $dbName );

  return $myDbh;
}

sub dbh()
{
  connectDB unless( defined $myDbh );

  return $myDbh;
}

1;

