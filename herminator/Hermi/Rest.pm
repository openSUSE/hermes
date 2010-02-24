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
package Hermi::Rest;

use Data::Dumper;

use strict;

use base 'CGI::Application';
# use CGI::Application::Plugin::ActionDispatch;

use Hermes::Config;
use Hermes::Log;
use Hermes::Message;
use Hermes::Statistics;
use Hermes::Person;
use Hermes::Util;
use Hermes::DB;

# sub do_stuff : Path('do/stuff') { ... }
# sub do_more_stuff : Regex('^/do/more/stuff\/?$') { ... }
# sub do_something_else : Regex('do/something/else/(\w+)/(\d+)$') { ... }
use vars qw( $htmlTmpl %isAdmin $user );

sub setup {
  my $self = shift;
  $self->start_mode('hello');
  $self->run_modes(
		   'ajaxupdate'   => 'ajaxUpdate',
		   'post'         => 'postMessage',
		   'notify'       => 'postNotification',
		   'hello'        => 'sayHello',
		   'doc'          => 'showDoc',
		   'type'         => 'editType',
		   'httptest'     => 'httpTest',
		   'posthttptest' => 'httpTestInput',
		   'subscribe'    => 'subscribePerson',
		   'subscriptions'=> 'userSubscriptions'
		  );
  $self->mode_param( 'rm' );

  $htmlTmpl = $self->load_tmpl( 'hermes.tmpl',
				die_on_bad_params => 0,
				cache => 1 );
}

# prerun is needed to handle POST calls that have some of the
# parameters still set as url parameters. prerun analyses the
# rm parameter to call the correct runmode.
sub cgiapp_prerun
{
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();
  my $mode = lc $q->url_param('rm');
  if( $mode eq 'post' ) {
    $self->prerun_mode( 'post' );
  } elsif( $mode eq "notify" ) {
    $self->prerun_mode( 'notify' );
  } elsif( $mode eq "ajaxupdate" ) {
    $self->prerun_mode( 'ajaxupdate' );
  } elsif( $mode eq "posthttptest" ) {
    $self->prerun_mode( 'posthttptest' );
  } elsif( $mode eq "subscribe" ) {
    $self->prerun_mode( 'subscribe' );
  }
  log('info', "Current Runmode: " . $self->get_current_runmode() );

  # Check for the users admin flag
  $user = "anonymous";
  my $loggedInUser;
  if( lc $Hermes::Config::authentication eq "ichain" ) {
    # with iChain authentification, the HTTP request contains trustable header
    # values like the username. Since iChain works like a proxy these can be
    # taken for real and no further dealing with passwords etc. is needed.

    # my @httpHeader = $q->http();
    # log('info', "HTTP-Header: " . join(", ", @httpHeader ) );

    $loggedInUser = $q->http('X_USERNAME');
  }elsif( $Hermes::Config::authentication =~ /^ichaintest-(.+)$/) {
    $loggedInUser = $1;
  }

  log('info', "User Name: " . ($loggedInUser ? $loggedInUser : "anonymous") );

  if( $loggedInUser ) {
    my $sql = "SELECT admin FROM persons WHERE stringid=?";
    my $sth = dbh()->prepare( $sql );
    $sth->execute( $loggedInUser );
    my ($admin) = $sth->fetchrow_array();
    $admin = 0 unless ( $admin );
    log( 'info', "Admin flag for user <$loggedInUser>: $admin" );
    $isAdmin{ $loggedInUser } = $admin > 0;
    $user = $loggedInUser;
  }

  my $post = $q->param( 'POSTDATA' );
  log( 'info', "POST data in prerun: <$post>" ) if( $post );
}

sub cgiapp_postrun
{
  my $self = shift();

  $self->header_type( 'header' );
  # $self->header_props( -expires => 'now' );
  $self->header_props( '-Cache-Control' => 'no-cache' );
}

#
# This sub creates a CGI query object for the CGI::Application framework. It needs to
# be overwritten because we need the pragma -oldstyle_urls which is not default for CGI.
# Not setting oldstyle-uri makes the CGI parser to split up parameters at semicolons.
# That's wrong because for us and creates strange additional parameters in the DB
# because for example comments with semicolons are split up.
#
sub cgiapp_get_query
{
  my $self = shift();

  use CGI qw /-oldstyle_urls/;

  return CGI->new();
}

#
# initialise the frame html template that is around all detail pages.
#
sub initFrame( $ )
{
  my ($header) = @_;

  $htmlTmpl->param( Header => $header );
  $htmlTmpl->param( isAdmin => $isAdmin{ $user } || 0 );
  $htmlTmpl->param( User => $user );

  my ($list, $firstType) = templateTypeList();
  $htmlTmpl->param( NotiTypeLinks => $list );

}

sub sayHello
{
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();
  initFrame( "Welcome to Hermes" );

  my $detailTmpl = $self->load_tmpl( 'info.tmpl', die_on_bad_params => 0, cache => 0 );

  my $msgList = latestNMessages(10);
  my $notiList = latestNRawNotifications( 25 );
  my $cnt = @{$notiList};

  $detailTmpl->param( CntRawNotifications => $cnt );
  $detailTmpl->param( RawNotiLastHour => countRawNotificationsInHours( 1 ) );
  $detailTmpl->param( LatestMessages => $msgList );
  $detailTmpl->param( countMessages => countMessages() );
  $detailTmpl->param( RawNotifications => $notiList );
  # print STDERR $detailTmpl->output;
  $htmlTmpl->param( Content => $detailTmpl->output );

  return $htmlTmpl->output;
}

sub showDoc
{
  my $self = shift;

  my $q = $self->query();
  my $docTmpl = $self->load_tmpl( 'doc.tmpl',
				  die_on_bad_params => 0,
				  cache => 1 );
  $docTmpl->param( urlbase => "subbotin.suse.de/hermes" );
  initFrame( "Hermes Documentation" );
  $htmlTmpl->param( Content => $docTmpl->output );

  return $htmlTmpl->output;
}

sub postNotification {
  my $self = shift;

  my $q = $self->query();

  my $type = $q->param( '_type' );
  my $params = $q->Vars;

  my $id = notificationToInbox( $type, $params );

  return "$id";
}

sub postMessage {
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();

  # read either the normal param or the url_param in case it is a post 
  # in mixed mode with url parameters 
  my $type    = $q->param( 'type')     || $q->url_param( 'type' );
  my $subject = $q->param( 'subject' ) || $q->url_param( 'subject' );
  my $body    = $q->param( 'body' )    || $q->url_param( 'body' );
  my @to      = $q->param( 'to' )      || $q->url_param( 'to' );
  my @cc      = $q->param( 'cc' )      || $q->url_param( 'cc' );
  my @bcc     = $q->param( 'bcc' )     || $q->url_param( 'bcc' );
  my $from    = $q->param( 'from' )    || $q->url_param( 'from' );

  # my $replyTo = $q->param( 'replyto' ); # Can be more than one! FIXME
  my $delayStr= uc ( $q->url_param( 'delay' ) || $q->url_param( 'delay' ) );
  # FIXME: Security, perfect spammer!

  log( 'info', "This is delayStr: <$delayStr>" );
  # Required: subject, body, from, one entry in to
  unless( defined $subject && defined $body && defined $from && scalar @to > 0 ) {
    log( 'error', "Message incomplete, required are subject, from body and a to entry." );

    log( 'info', "Subject: " . ( $subject || "<empty>" ) );
    log( 'info', "Body: " . ( $body || "<empty>" ) );
    log( 'info', "from: " . ( $from || "<empty>" ) );
    log( 'info', "to: " . join( ', ', @to ) );

    my $err = "ERROR: Message incomplete, ";
    $err .= "Subject empty" unless $subject;
    $err .= " Body empty" unless $body;
    $err .= " from empty" unless $from;
    $err .= " to empty" unless @to;

    return $err;
  }

  # Check the delay
  my $delay = SendNow;
  if( $delayStr eq "HOURLY" ) {
    $delay = SendHourly;
  } elsif( $delayStr eq "DAILY" ) {
    $delay = SendDaily;
  } elsif( $delayStr eq "WEEKLY" ) {
    $delay = SendWeekly;
  } elsif( $delayStr eq "MONTHLY" ) {
    $delay = SendMonthly;
  }

  my $id = newMessage( $subject, $body, $type, $delay, @to, @cc, @bcc, $from );

  return "$id";
}

sub subscribePerson()
{
  my $self = shift;

  my $q = $self->query();
  my $type = $q->param('person');

  log( 'info', "subscribePerson: Not yet implemented!" );
}

sub userSubscriptions()
{
  my $self = shift;

  my $q = $self->query();
  my $person = $q->param('person');
  my @msg_types = $q->param('types');

  my @subsList;
  if( $person ) {
    my $subsList = subscriptions( $person );
    foreach my $subsHashRef ( @$subsList ) {
      my %resHash;
      $resHash{delivery} = deliveryIdToString( $subsHashRef->{delivery_id} );
      $resHash{delay}    = delayIdToString( $subsHashRef->{delay_id} );
      $resHash{msgtype}  = $subsHashRef->{msgtype};
      push @subsList, \%resHash;
    }
  }

  my $subsTmpl = $self->load_tmpl( 'subscriptions.tmpl',
				   die_on_bad_params => 0,
				   cache => 1 );
  initFrame( "Hermes User Subscriptions" );
  $subsTmpl->param( person => $person || "<no person>" );
  $subsTmpl->param( subscriptions => \@subsList );

  $htmlTmpl->param( Content => $subsTmpl->output );

  # print STDERR $self->dump();

  return $htmlTmpl->output;
}

sub httpTestInput()
{
  my $self = shift;
  
  # Set debug in the config file to enable
  unless( $Hermes::Config::Debug ) {
    log( 'info', "httpTest disabled, enable Debug switch in Hermes config!" );
    return;
  }
  
  my $q = $self->query();
  my $type = $q->param('type') || "unknown type";
  log( 'info', "Incoming httptesttype: $type" );
  
  my $timeStr = localtime;

  my @httpTestQueue;
  if( -r "/tmp/httpTestQueue.txt" && open FILE, "</tmp/httpTestQueue.txt" ) {
    @httpTestQueue = <FILE>;
    close FILE;
  }
  my $cnt = unshift( @httpTestQueue, "$type\t$timeStr\n" );
  pop @httpTestQueue if( $cnt > 100 );

  if( open FILE, ">/tmp/httpTestQueue.txt" ) {
    print FILE @httpTestQueue;
    close FILE;
  } else {
    log( 'info', "Could not write log file: $!") ;
  }
}

sub httpTest()
{
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();
  my $tmpl = $self->load_tmpl( 'httptest.tmpl',
			       die_on_bad_params => 0,
			       cache => 1 );
  $tmpl->param( urlbase => "subbotin.suse.de/hermes" );
  
  initFrame( "Hermes HTTP Delivery Test Page" );

  if( $Hermes::Config::Debug ) {
    my @httpTestQueue;
    if( -r "/tmp/httpTestQueue.txt" && open FILE, "</tmp/httpTestQueue.txt" ) {
      @httpTestQueue = <FILE>;
      close FILE;
    }
    my $cnt = @httpTestQueue;
    log( 'info', "http Test Queue: $cnt" );

    my @hashList;
    foreach my $testLine ( @httpTestQueue ) {
      my ($type, $timeStr) = split( /\t/, $testLine );
      push @hashList, { type => $type, time => $timeStr };
    }
    $tmpl->param( TestQueueLoop => \@hashList );
  } else {
    log( 'info', "No debugging because debug switch off" );
    $tmpl->param( ErrorMsg => "Please enable debug to start the debug output" );
  }
  $htmlTmpl->param( Content => $tmpl->output );

  return $htmlTmpl->output;
}

sub editType()
{
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();
  my $type = $q->param( 'type' );

  my $tmpl = $self->load_tmpl( 'edittype.tmpl',
			       die_on_bad_params => 0,
			       cache => 1 );
  my ($list, $firstType) = templateTypeList( $type );
  $type = $firstType unless( $type );

  my $status;
  my $previewTmpl;
  my $detailsRef = notificationDetails( $type );
  my $tmplFile = templateFileName( $detailsRef->{_type} );

  if ( $q->param( 'tmplEdit' ) && $isAdmin{$user} ) {
    log( 'debug', "template was edited!" );
    $previewTmpl = $q->param('tmplEdit');

    log( 'debug', "Dosave: " . ($q->param('dosave' ) || "false") );

    if ( $q->param( 'dosave' ) && $q->param('dosave') eq ' Save ' ) {
      log('debug', "SAVING the template" );
      # save the template
      if ( ! -e $tmplFile || -w $tmplFile ) {
	if ( open F, ">$tmplFile" ) {
	  print F $previewTmpl;
	  close F;
	  $previewTmpl = undef;
	  $status = "Template saved!";
	} else {
	  $status = "ERROR: open failed for file $tmplFile!";
	}
      } else {
	$status = "ERROR: No write access on $tmplFile";
      }
    } else {
      $status = "Preview Rendering";
    }
  }

  my $admin = $isAdmin{$user} || 0;
  log( 'debug', "User $user is admin: $admin" );
  $tmpl->param( user  => $user || "unknown" );
  $tmpl->param( isAdmin => $admin );
  $tmpl->param( type  => $detailsRef->{_type} );
  $tmpl->param( NotiTypeDesc => $detailsRef->{_description} || "not yet defined" );
  $tmpl->param( NotiTypeId => $detailsRef->{_id} );
  $tmpl->param( added => $detailsRef->{_added} );
  $tmpl->param( delay => $detailsRef->{_defaultdelay} );

  my @names;

  foreach my $paraRef( @{$detailsRef->{_parameterList}} ) {
    log( 'debug', "Parameter : $paraRef->{name}" );
    my $name = $paraRef->{name};
    next if( $name eq "rm" || $name eq "_type" );

    push @names, { 'name'   => $name,
		   'hrName' => $paraRef->{_hrName} || "undefined",
		   'value'  => $detailsRef->{$name},
		   'desc'   => $paraRef->{_desc} || "still empty",
		   'nameSpanId' => "pd_name_$name",
		   'descSpanId' => "pd_desc_$name",
		   'descEditJs' => parameterInplaceEdit( $name, 'desc', $detailsRef->{_id} ),
		   'nameEditJs' => parameterInplaceEdit( $name, 'name', $detailsRef->{_id}, 15 ),
		   'isAdmin' => $admin
		 };
  }
  $tmpl->param( parameters => \@names );

  $tmpl->param( testrender => testRender( $detailsRef, $tmplFile, $previewTmpl ) );

  if ( $previewTmpl ) {
    $tmpl->param( templateFile => "from editfield, not yet SAVED!" );
    $tmpl->param( template => $previewTmpl );
  } else {
    $tmpl->param( templateFile => $tmplFile );

    if ( -r $tmplFile ) {
      if ( open F, "$tmplFile" ) {
	my @t = <F>;
	$tmpl->param( template => join("", @t ) );
	close F;
      }
    }
  }
  $tmpl->param( status => $status );
  initFrame( "Hermes Notification Type <i>$type</i>" );

  $htmlTmpl->param( NotiTypeLinks => $list );

  $htmlTmpl->param( Content => $tmpl->output );

  return $htmlTmpl->output;
}

#
# Create a in place editor for both the human readable name and the description
# of notification parameters
# Paramter:
# 1. The name of the parameter
# 2. The destinquischer between name and desc, string 
# 3. The notification type id
# 4. The length of the edit line (optional)
#
sub parameterInplaceEdit( $$$;$ ) 
{
  my ($name, $var, $id, $cols) = @_;
  my $columns = $cols || 40;

  my $domId = "pd_" . $var . "_" . $name;

  my $re = "new Ajax.InPlaceEditor( \'$domId\', \'index.cgi\', \{ cols: $columns, rows: 1,";
  $re .= " callback: function(form, value) { ";
  $re .= "return 'rm=ajaxupdate&paraname=$name&id=$id&value='+escape(value) } } ) ";

  return $re;
}

# this sub returns a test rendering of a freshly edited template
sub testRender( $$;$ )
{
  my ($noti, $tmplFile, $previewTmpl ) = @_;

  return unless $noti;

  log('debug', "The template file: <$tmplFile>" );
  my $tmpl;

  if( $previewTmpl ) {
    $tmpl = HTML::Template->new( scalarref => \$previewTmpl,
				 die_on_bad_params => 0 );
  } elsif( -r "$tmplFile" ) {
    $tmpl = HTML::Template->new(filename => "$tmplFile",
				die_on_bad_params => 0,
				cache => 1 );
  }

  if( $tmpl ) {
    my @params = @{$noti->{_parameterList}};

    my %paramHash;
    foreach my $param ( @params ) {
      my $paraName = $param->{name};
      if( $paraName ) {
	log('debug', "Adding parameter: <$paraName> = <" . $noti->{$paraName} . ">" );
	$paramHash{ $paraName } = $noti->{$paraName};
      }
    }
    $tmpl->param( \%paramHash );

    return $tmpl->output;
  }
  return "no template available!";
}

sub ajaxUpdate
{
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();
  my $value = $q->param( 'value' );
  my $editId  = $q->param( 'editorId' );
  my $id = $q->param( 'id' ) || "go away";

  log('debug', "Ajax-Update: $editId = $id" );
  if( $editId eq "noti_type_desc" && $id =~ /^\d+$/ ) {
    my $sql = "UPDATE msg_types SET description=? WHERE id=?";

    my $sth = dbh()->prepare( $sql );
    $sth->execute( $value, $id );
  } elsif( $editId =~ /pd_desc_(.+)$/ ) {
    # editing parameter description
    my $paraId = parameterId( $1 );
    if( $paraId && $id ) {
      my $sql = "UPDATE msg_types_parameters SET description=? WHERE msg_type_id=? AND parameter_id=?";
      my $sth = dbh()->prepare( $sql );
      $sth->execute( $value, $id, $paraId );
    }
  } elsif( $editId =~ /pd_name_(.+)$/ ) {
    # editing parameter human readable name
    my $paraId = parameterId( $1 );
    if( $paraId && $id ) {
      my $sql = "UPDATE parameters SET hr_name=? WHERE id=?";
      my $sth = dbh()->prepare( $sql );
      $sth->execute( $value, $paraId );
    }
  }

  return "$value";
}

sub templateTypeList(;$)
{
  my ($selected) = @_;

  my @types;
  my $sql = "SELECT msgtype FROM msg_types ORDER by msgtype";
  my $typesRef = dbh()->selectcol_arrayref( $sql );

  my $res = ""; #  = "<p>Message Types:</p><ul>\n";
  unless( $selected ) {
    $res = "<option selected value=\"index.cgi\"> -- Pick a Notification Type --</option>";
  }
  my $firstType = @$typesRef[0];

  foreach my $t ( @$typesRef ) {
    my $dipType = $t;

    my $oneEntry = "<option";
    
    $oneEntry .= " selected" if( $selected && $selected eq $dipType );
    $oneEntry .= " value=\"index.cgi?rm=type&type=$t\">$dipType</option>";

    $res .= $oneEntry;
  }
  return ($res, $firstType) ;
}

1;
