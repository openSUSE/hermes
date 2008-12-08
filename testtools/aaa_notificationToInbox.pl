#!/usr/bin/perl


use Test::More tests => 7;
use Test::DatabaseRow;

use Hermes::DB;
use Hermes::Message;
use Hermes::Util;

# Connect to test database
connectDB( 'test' );

local $Test::DatabaseRow::dbh = dbh();

print<<END

This test script tests the basic hermes functionality of posting a 
notification to Hermes. That is basically what the herminator
post command and the command line tool notifyHermes.pl does.

It 
* fills the delays table
* creates two message types
* posts a notification with two parameters. 

The parameters must appear automatically and there must be 
entries in the notifications and notification_parameters table.

Check if all tests succeeded.

To create the test database, call in starship:
rake RAILS_ENV=test db:migrate

END
;

# ... and kill it
ok( defined dbh(), "Database handle is defined" );

dbh()->do( "DELETE FROM msg_types" );

row_ok( table => "delays",
	where => { '=' => { name => "NO_DELAY" } },
        label => "NO_DELAY entry in delays table" );
row_ok( table => "delays",
	where => [ name => "PER_MINUTE" ],
        label => "PER_MINUTE entry in delays table" );

# Now create two message types
createMsgType( 'MSGTYPE_1', SendNow );
createMsgType( 'MSGTYPE_2', SendMinutely );

row_ok( table => "msg_types",
	where => [ msgtype => "MSGTYPE_1", defaultdelay => "1" ],
        label => "MsgType named MSGTYPE_1" );

row_ok( table => "msg_types",
	where => [ msgtype => "MSGTYPE_2", defaultdelay => "2" ],
        label => "MsgType named MSGTYPE_2" );

my %params;
$params{ PARAM1 } = "value1";
$params{ PARAM2 } = "value2";

my $id = notificationToInbox( "MSGTYPE_1", \%params );

row_ok( table => "notifications",
	where => [ id => $id ],
        label => "Notification created" );

row_ok( table => "notification_parameters",
	where => [ notification_id => $id ],
        label => "Notification Parameters there" );

print "Thanks.\n\n";
