#!/usr/bin/perl


use Test::More tests => 14;
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

my $deliveryId = deliveryStringToId( 'MAIL' );

ok( $deliveryId > 0, "Delivery id for Mail valid: $deliveryId" );

print "MessageTypeID: $msgTypeId\n";

my $subscriptId = createSubscription( $msgTypeId, $personId, (), $deliveryId );
row_ok( table => "subscriptions",
        where => [ msg_type_id => $msgTypeId, person_id => $personId, delivery_id => $deliveryId ],
	label => "Subcription table entry exists." );

$msgTypeId = createMsgType( 'MSGTYPE_2', SendMinutely );
$subscriptId = createSubscription( $msgTypeId, $personId, (), $deliveryId, SendMinutely );

row_ok( table => "subscriptions",
        where => [ msg_type_id => $msgTypeId, person_id => $personId, delivery_id => $deliveryId, 
		   delay_id => SendMinutely ],
	label => "Subcription table entry exists." );


$msgTypeId = createMsgType( 'MSGTYPE_3', SendHourly );

notificationToInbox( 'MSGTYPE_3', { 'testparam_3' => 'foobar' } );

my @filters;
push @filters, { parameter => 'testparam_3', operator => 'oneof', filterstring => 'filterstring' };
$subscriptId = createSubscription( $msgTypeId, $personId, \@filters, $deliveryId, SendMinutely );

row_ok( table => "subscriptions",
        where => [ msg_type_id => $msgTypeId, person_id => $personId, delivery_id => $deliveryId, 
		   delay_id => SendMinutely ],
	label => "Subcription table entry exists." );

my $msgTypeInfo = notificationTemplateDetails( 'MSGTYPE_3' );
my $msgTypeParams = $msgTypeInfo->{_parameterList};

my $paramId;
foreach my $param ( @$msgTypeParams ) {
  if( $param->{name} eq 'testparam_3' ) {
    $paramId = $param->{testparam_3};
    last;
  }
}


ok( $subscriptId > 0, "Subscription id is $subscriptId" );
ok( $paramId > 0, "Parameter id is $paramId" );

row_ok( table => "subscription_filters",
        where => [ subscription_id => $subscriptId, parameter_id => $paramId, operator => 'oneof', 
                   filterstring => 'filterstring' ],
        label => "Filter string correct." );
        
print "Thanks.\n\n";
