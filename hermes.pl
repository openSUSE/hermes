#!/usr/bin/perl
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
# This is a test script for the hermes library.


use Hermes::Message qw(:DEFAULT /^SEND_/);

my $subject = 'Test subject';
my $text = "Hi. <BODY>This is a test.</BODY>";
my $type = 'test';
my $delay = HERMES_DEBUG; # send now !
my @to = ('klaas@freisturz.de', 'freitag@suse.de');
my @cc = ( 'goof@universe.com' );
my @bcc = ('cwh@suse.de');

newMessage($subject, $text, $type, $delay, @to, @cc, @bcc);
    
$subject = "Digested Stuff";
$text = "<PRE>We are sending something interesting: </PRE>";
$text .= "<BODY>The monkeys look left</BODY>";
$text .= "<POST>Have fun with it :)</POST>";
$type = "TestDigest";
$delay = SEND_WEEKLY;
newMessage($subject, $text, $type, $delay, @to, @cc, @bcc);

$text = "<PRE>We are sending something interesting: </PRE>";
$text .= "<BODY>The monkeys look right</BODY>";
$text .= "<POST>Have fun with it :)</POST>";

newMessage($subject, $text, $type, $delay, @to, @cc, @bcc);

sendMessageDigest( SEND_WEEKLY, "testdigest", 1 );
