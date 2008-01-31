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

package Hermes::Log::File;

=head1 NAME

Hermes::Log::File - Log::Dispatch object for logging to a file

=head1 SYNOPSIS

    use Hermes::Log::File;
 
    my $file = Log::Dispatch::File->new(name      => 'file1',
					min_level => 'info',
					filename  => 'Somefile.log',
					mode      => 'append');

    $file->log(level => 'info', message => "Something happened.");

=head1 DESCRIPTION

Hermes::Log::File implements a file-based log for use with the Log::Dispatch
system.

Each entry written to the log file will be prefixed with the current
timestamp, the current process ID, and the entry's log level.

Based on Log::Dispatch::File, by Dave Rolsky <autarch@urth.org>.

=head1 METHODS

=over 4

=item * new(%PARAMS)

This method takes a hash of parameters.  The following options are
valid:

=item -- name ($)

The name of the object (not the filename!).  Required.

=item -- min_level ($)

The minimum logging level this object will accept.  See the
Log::Dispatch documentation for more information.  Required.

=item -- max_level ($)

The maximum logging level this obejct will accept.  See the
Log::Dispatch documentation for more information.  This is not
required.  By default the maximum is the highest possible level (which
means functionally that the object has no maximum).

=item -- filename ($)

The filename to be opened for writing.

=item -- mode ($)

The mode the file should be opened with.  Valid options are 'write',
'>', 'append', '>>', or the relevant constants from Fcntl.  The
default is 'write'.

=item -- callbacks( \& or [ \&, \&, ... ] )

This parameter may be a single subroutine reference or an array
reference of subroutine references.  These callbacks will be called in
the order they are given and passed a hash containing the following keys:

 ( message => $log_message, level => $log_level )

The callbacks are expected to modify the message and then return a
single scalar containing that modified message.  These callbacks will
be called when either the C<log> or C<log_to> methods are called and
will only be applied to a given message once.

=item * log_message( message => $ )

Sends a message to the appropriate output.  Generally this shouldn't
be called directly but should be called through the C<log()> method
(in Log::Dispatch::Output).

=back

=head1 SEE ALSO

Log::Dispatch, Log::Dispatch::File

=cut

use strict;
use IO::File;
use Log::Dispatch::Output;

use base qw(Log::Dispatch::Output);
use fields qw(fh filename);

use vars qw($VERSION);

($VERSION) = ' $Revision: 1.4 $ ' =~ /\$Revision:\s+([^\s]+)/;

# Prevents death later on if IO::File can't export this constant.
BEGIN
{
    my $exists;
    eval { $exists = O_APPEND(); };

    *O_APPEND = \&APPEND unless defined $exists;
}

sub APPEND {;};

1;

sub new(%)
{
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %params = @_;

    my $self = {};

    bless( $self, $class );

    $self->_basic_init(%params);
    $self->_make_handle(%params);

    return $self;
}

sub _make_handle($%)
{
    my $self = shift;
    my %params = @_;

    $self->{'filename'} = $params{'filename'};

    my $mode;
    if (exists $params{'mode'} && ($params{'mode'} =~ /^>>$|^append$|/ || $params{'mode'} == O_APPEND())) {
	$mode = '>>';
    } else {
	$mode = '>';
    }

    $self->{'fh'} = IO::File->new("$mode$self->{'filename'}");

    print STDERR "WARN: Can't write to '$self->{'filename'}': $!\n"  if( ! defined $self->{'fh'} ); 
    # ||  ( print STDERR "Can't write to '$self->{'filename'}': $!" &&
								 #$self->{'fh'} = undef );
}

sub log_message($%)
{
    my $self = shift;
    my %params = @_;
    
    return unless( defined $self->{'fh'} );
    # Timestamp format: day-month hour:minutes:seconds
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
    $mon += 1; # correct month range (0..11)
    my $timestamp .= sprintf("%02d-%02d %02d:%02d:%02d", $mday, $mon, $hour,
        $min, $sec);

    # Prefix format: [timestamp] (pid) level:
    my $prefix = sprintf("[%s] (%d) [%s] ", $timestamp, $$, $params{'level'});

    # Build the log entry.
    my $message = $prefix . $params{'message'} . "\n";

    $self->{'fh'}->print($message);
}
