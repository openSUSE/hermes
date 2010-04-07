#!/usr/bin/perl

use Hermes::Log;
use Hermes::Client;
use Data::Dumper;

my $res = notifyHermes( 'testhermes', { foo => bar, baz => bubu } );

print "Result: $res\n";


