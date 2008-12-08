#!/usr/bin/perl

use strict;
use Test::More tests => 17;
use Test::DatabaseRow;

use Hermes::DB;
use Hermes::Message;

# Connect to test database, which needs to be configured in Hermes/Config.pm
connectDB( 'test' );

local $Test::DatabaseRow::dbh = dbh();

print<<END

This test script tests the basic hermes functionality of generating
a message for a user from a formerly received notification. 

It 
* does generates a few notifications
* calls the Hermesgenerator script afterwards

Check if all tests succeeded.

END
;

# ... and kill it
ok( defined dbh(), "Database handle is defined" );

my $type = 'MSGTYPE_1';
my %params;

$params{ PARAM1 } = "value1";
$params{ PARAM2 } = "value2";

my $mt1_id1 = notificationToInbox( $type, { PARAM1 => "value1", PARAM2 => "value2" } );
row_ok( table => "notifications",
	where => [ id => $mt1_id1 ],
        label => "1. Notification to $type created" );

my $mt1_id2 = notificationToInbox( $type, { PARAM1 => "value3", PARAM2 => "value4" } );
row_ok( table => "notifications",
	where => [ id => $mt1_id2 ],
        label => "2. Notification to $type created" );

my $mt1_id3 = notificationToInbox( $type, { PARAM1 => "value5", PARAM2 => "value6" } );
row_ok( table => "notifications",
	where => [ id => $mt1_id3 ],
        label => "3. Notification to $type created" );

# 
# Now there are three notification for msg_type = MSGTYPE_1
# 
# There is a subscription for termite for SendNow per mail.

my @syscmd = ("../hermesgenerator.pl", "-o", "-t", "test");
system( @syscmd );

ok( $? == 0, "First generator exited successfully: $?" );

row_ok( table => 'generated_notifications',
	where => [ notification_id => $mt1_id1 ],
	label => "1. Notification Generated" );

row_ok( table => 'generated_notifications',
	where => [ notification_id => $mt1_id2 ],
	label => "2. Notification Generated" );

row_ok( table => 'generated_notifications',
	where => [ notification_id => $mt1_id3 ],
	label => "3. Notification Generated" );

# Now some notifications to type 2
$type = "MSGTYPE_2";

my $mt2_id1 = notificationToInbox( $type, { PARAM1 => "value21" } );
row_ok( table => "notifications",
	where => [ id => $mt2_id1 ],
        label => "1. Notification to $type created: $mt2_id1" );

my $mt2_id2 = notificationToInbox( $type, { PARAM1 => "value22" } );
row_ok( table => "notifications",
	where => [ id => $mt2_id2 ],
        label => "2. Notification to $type created: $mt2_id2" );

my $mt2_id3 = notificationToInbox( $type, { PARAM1 => "value23" } );
row_ok( table => "notifications",
	where => [ id => $mt2_id3 ],
        label => "3. Notification to $type created: $mt2_id3" );

# let run the generator again.
system( @syscmd );
ok( $? == 0, "Second generator command exited successfully" );

# call the hermesworker to actually send the messages
# option -o means only the immediate due messages
@syscmd = ( '../hermesworker.pl', '-o', '-t', 'test' );

system( @syscmd );
ok( $? == 0, "Worker exited successfully" );

# now we should have the sent column of the message type 1 set 
# to a timestamp, the ones for message type 2 should still be null
# because they are not immediately.

# check if the debug mail files are there
print "Checking mail for id $mt1_id1\n";
ok( -e "debugmails/termite_suse.de_$mt1_id1", "MSG_TYPE1 message 1 test message exists" );
print "Checking mail for id $mt1_id2\n";
ok( -e "debugmails/termite_suse.de_$mt1_id2", "MSG_TYPE1 message 2 test message exists" );
print "Checking mail for id $mt1_id3\n";
ok( -e "debugmails/termite_suse.de_$mt1_id3", "MSG_TYPE1 message 3 test message exists" );

# redo the same for minute digests.
@syscmd = ( '../hermesworker.pl', '-m', '-t', 'test' );

system( @syscmd );
ok( $? == 0, "Worker exited successfully" );


print "Thanks.\n\n";


