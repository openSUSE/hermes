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
package Hermes::Person;

use strict;
use Exporter;

use Hermes::Config;
use Hermes::DBI;
use Hermes::Log;


use vars qw( @ISA @EXPORT @EXPORT_OK $dbh);

@ISA	    = qw(Exporter);
@EXPORT	    = qw( personInfo );

#
# This sub returns a hash ref that contains some information about
# a person identified through the id
#
# The following keys are set in the person desc hash:
# - all columns from the database table persons
# - feedPath: a relative path name which is user specific.
# 
sub personInfo( $ )
{
  my ($id) = @_;

  my $personInfoRef;
  my $sql = "SELECT * FROM persons WHERE stringid = ?";

  if( $id && $id =~ /^\s*\d+\s*$/ ) {
    $sql = "SELECT * FROM persons WHERE id=?";
  }

  if( $id ) {
    my $sth = $dbh->prepare( $sql );
    $sth->execute( $id );

    $personInfoRef = $sth->fetchrow_hashref;

    my $feeds = $personInfoRef->{stringid} || "unknown_hero";
    # $feeds =~ s/[\.@]/_/g;
    $personInfoRef->{feedPath} = $feeds;
  }
  return $personInfoRef;
}

$dbh = Hermes::DBI->connect();

1;
