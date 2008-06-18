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

package Hermes::Log;

=head1 NAME

Hermes::Log - Common logging functions for Hermes

=head1 SYNOPSIS

    use Hermes::Log;

=head1 DESCRIPTION

Hermes::Log presents a standard logging interface for use throughout the Hermes
messaging system.

Configuration parameters are read from the %Hermes::Config::LOG hash.

=cut

use strict;
use Exporter;

use Hermes::Config;
use IO::Handle;

use vars qw($VERSION @ISA @EXPORT $name);

($VERSION) = ' $Revision: 1.3 $ ' =~ /\$Revision:\s+([^\s]+)/;

@ISA	= qw(Exporter);
@EXPORT	= qw(log _init);


sub _init()
{
  my %params = %{$Hermes::Config::LOG{'params'}};
  my $f = $params{'filename'};
  $name = $params{'name' };

  if( $f && open HANDLE, ">>$f" ) {
    HANDLE->autoflush(1);
  }
}


=head1 NAME

log - adds a new log entry

=head1 SYNOPSIS

    use Hermes::Log;

    log('info', 'Something interesting happened.');

=head1 DESCRIPTION

Adds a new log entry.

=head1 PARAMETERS

The first parameter is the log level of this entry.  The possible values are:

    debug
    info
    notice
    warning
    error
    critical
    alert
    emergency

The second parameter is the text of the log message.

The third, optional, parameter turns on "minimal" logging.  This will prevent
the name of the calling function from being prepended to the log entry.

=cut

sub log($$;$)
{
    my ($level, $message, $minimal) = @_;

    # Make sure we've been given a valid log level string.
    unless ( 1 ) { # We log every log level atm.
	print STDERR "Invalid log level: '$level'\n";
	return;
    }

    # Initialize the dispatcher if it hasn't already been done.
    _init() unless ( HANDLE->opened() );

    # Get the current function context.
    unless (defined $minimal && $minimal) {
      my ($package, $filename, $line, $subroutine) = caller(1);
      if (defined $subroutine) {
	# Trim off the 'Package::Module::' prefix.
	# Do that by substr which is much faster than the damned regexps
	my $idx = rindex( $subroutine, "::");
	$subroutine = substr( $subroutine, $idx+2) if( $idx > 0 );
	#$subroutine =~ s/^(\w+::)*//;
	$message = "$subroutine: $message";
      }
    }
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

    if( length($sec) == 1 ) {
      $sec = "0" . $sec;
    }
    if( length($min ) == 1 ) {
      $min = "0" . $min;
    }
    if( length($hour) == 1 ) {
      $hour = "0" . $hour;
    }
    my $n = $name || "";

    print HANDLE "$n\[$level $$ $hour:$min:$sec] $message\n"; 
}

1;
