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
package Hermes::DBI;

use strict;
use base qw( DBI );
use Hermes::Log;
use Hermes::Config;

use Data::Dumper;

sub connect
{
    my $class = shift;

    die "Constructor has to be used as instance method!" if ref($class);

    my $connectTo = shift || 'default';

    my $db_type = $Hermes::Config::DB{$connectTo}->{'type'};
    my $db_name = $Hermes::Config::DB{$connectTo}->{'name'};
    my $db_host = $Hermes::Config::DB{$connectTo}->{'host'} || '';
    my $db_port = $Hermes::Config::DB{$connectTo}->{'port'} || '';
    my $db_user = $Hermes::Config::DB{$connectTo}->{'user'};
    my $db_pass = $Hermes::Config::DB{$connectTo}->{'pass'};

    unless( defined $db_name )
    {
	die( "Can not connect to database <$connectTo>, no DB name configured.\n" .
	     "Check AddDB-Parameter in Config.pm\n" );
    }
    
    my $data_source = "dbi:$db_type:$db_name;host=$db_host;port=$db_port";

    $db_pass = undef if( !defined $db_pass || $db_pass =~ /^\s*$/ );
    my $self = $class->SUPER::connect( $data_source,
				       $db_user,
				       $db_pass,
				       { RaiseError => 1, AutoCommit => 1,
					 dbi_connect_method => 'connect_cached' } ) or die $DBI::errstr;
    # log( 'notice', "DBI Handle: $self" );
    # print STDERR Dumper( $self );

    return $self;
}

sub connect_cached()
{
    my $class = shift;
    return  $class->connect( @_ );
}

# ===============================================================================

package Hermes::DBI::db;
use base qw( DBI::db );

# ===============================================================================

package Hermes::DBI::st;
use base qw( DBI::st );

1;
