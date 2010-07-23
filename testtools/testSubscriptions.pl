#!/usr/bin/perl

use Hermes::Log;
use Hermes::Person;
use Hermes::Message;
use Data::Dumper;

my $person = 'termite';

my $msgTypeId = createMsgType( 'test_subscriptions' );

my $subsId = createSubscription( $msgTypeId, $person, 1  );
push @subsIds, $subsId;

my @filters;
push @filters, {parameter => 1, operator => 'regexp', filterstring => 'foobar'} ;
$msgTypeId = createMsgType( 'test_subscription2' );
$subsId = createSubscription( $msgTypeId, $person, 2, \@filters );
push @subsIds, $subsId;

my $subRef = subscriptions( $person );
print Dumper( $subRef );

removeSubscriptions( @subsIds );
print "*** Now everything is removed:\n";
my $subRef = subscriptions( $person );
print Dumper( $subRef );

print "Ok\n\n";

