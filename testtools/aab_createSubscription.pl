#!/usr/bin/perl


use Test::More tests => 10;
use Test::DatabaseRow;

use Hermes::DB;
use Hermes::Message;
use Hermes::Util;
use Hermes::Person;

# Connect to test database, which needs to be configured in Hermes/Config.pm
connectDB( 'test' );

local $Test::DatabaseRow::dbh = dbh();

print<<END

This test script tests the basic hermes functionality of generating
a message for a user from a formerly received notification. 

It 
* checks if there is a notification which is not yet sent.
* creates a user 
* creates a subscription on the message type MSGTYPE_1

The parameters must appear automatically and there must be 
entries in the notifications and notification_parameters table.

Check if all tests succeeded.

END
;

# ... and kill it
ok( defined dbh(), "Database handle is defined" );

row_ok( table => "notifications",
	where => [ generated => undef ],
        label => "unsent notification present" );

# now create a user in the database.
my $personId = createPerson( 'termite@suse.de', 'Termite', 'termite' );

row_ok( table => "persons",
	where => [ stringid => "termite" ],
        label => "User creation successfull" );

# check if the person Id is ok
ok( $personId > 0, "PersonID termite valid" );

# now create the default sender in the database
my $hermes2 = createPerson( 'hermes@suse.de', 'Hermes Admin', 'hermes2' );

row_ok( table => "persons",
	where => [ stringid => "hermes2" ],
        label => "Hermes admin creation successfull" );

# check if the person Id is ok
ok( $personId > 0, "PersonID termite valid" );

# create a subscription
my $msgTypeId = createMsgType( 'MSGTYPE_1', SendNow );
ok( $msgTypeId > 0, "MsgType MSGTYPE_1 exists" );

my $deliveryId = deliveryStringToId( 'Mail' );

ok( $deliveryId > 0, "Delivery id for Mail valid: $deliveryId" );

print "MessageTypeID: $msgTypeId\n";

my $subscriptId = createSubscription( $msgTypeId, $personId, $deliveryId );
row_ok( table => "subscriptions",
        where => [ msg_type_id => $msgTypeId, person_id => $personId, delivery_id => $deliveryId ],
	label => "Subcription table entry exists." );

$msgTypeId = createMsgType( 'MSGTYPE_2', SendMinutely );
$subscriptId = createSubscription( $msgTypeId, $personId, $deliveryId, SendMinutely );

row_ok( table => "subscriptions",
        where => [ msg_type_id => $msgTypeId, person_id => $personId, delivery_id => $deliveryId, 
		   delay_id => SendMinutely ],
	label => "Subcription table entry exists." );

print "Thanks.\n\n";
