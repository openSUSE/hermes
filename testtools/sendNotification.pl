#!/usr/bin/perl
use strict;

use Hermes::Message;

my ($type) = @ARGV;

$type="TestType" unless( defined $type );

print "Notifying type <$type>\n";
my $id = sendNotification( $type, {} );

print "Message created: $id\n";

# END

