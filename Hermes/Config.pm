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
################################################################
# Check the syntax of this file with 'perl -cw Config.pm'. 
#
package Hermes::Config;

use strict;
use vars qw( %LOG %DB );

#--[ Logging Configuration ]---------------------------------------------------

%LOG = (
    'module'	=> 'Hermes::Log::File',
    'params'    => {'name'	=> 'PDB',
		    'filename'	=> '/tmp/inttools.log',
		    'min_level'	=> 'info',
		    'mode'	=> 'append'}
);

#--[ Default DB Configuration ]---------------------------------------------------

$DB{ 'default' } = { 'type'	=>  'mysql',
		     'host'	=>  'localhost',
		     'port'	=>  3306,
		     'name'	=>  'hermes',
		     'user'	=>  'root',
		     'pass'	=>  undef };

#--[ Local Configuration ]--------------------------------------------------
# Read local configuration file, if this exists. This is meant to be used to
# override configuration values with specific values.

my $cfg = "/etc/inttools.conf";

my $return = do $cfg;

unless( $return )
{
    if( $@ )
    {
	warn( "Cannot compile $cfg: $@" );
    }
    elsif( $! )
    {
	warn( "Cannot read $cfg: $!" );
    }
    else
    {
	warn( "Cannot find $cfg" );
    }
}

#---------------------------------------------------------------------------
1;
