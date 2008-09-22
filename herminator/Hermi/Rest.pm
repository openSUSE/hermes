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

use strict;
use base 'CGI::Application';
# use CGI::Application::Plugin::ActionDispatch;
use Hermes::Config;
use Hermes::Log;
use Hermes::Message;
use Hermes::Statistics;
use Hermes::Util;
use Hermes::DBI;

# sub do_stuff : Path('do/stuff') { ... }
# sub do_more_stuff : Regex('^/do/more/stuff\/?$') { ... }
# sub do_something_else : Regex('do/something/else/(\w+)/(\d+)$') { ... }
use vars qw( $dbh $htmlTmpl %isAdmin $user );

sub setup {
  my $self = shift;
  $self->start_mode('hello');
  $self->run_modes(
		   'post'   => 'postMessage',
		   'notify' => 'postNotification',
		   'hello'  => 'sayHello',
		   'doc'    => 'showDoc',
		   'type'   => 'editType'
		  );
  $self->mode_param( 'rm' );

  $htmlTmpl = $self->load_tmpl( 'hermes.tmpl',
				die_on_bad_params => 1,
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
  if( lc $q->url_param( 'rm' ) eq 'post' ) {
    $self->prerun_mode( 'post' );
  }

  # Check for the users admin flag
  $user = "anonymous";
  if( lc $Hermes::Config::authentication eq "ichain" ) {
    # with iChain authentification, the HTTP request contains trustable header
    # values like the username. Since iChain works like a proxy these can be
    # taken for real and no further dealing with passwords etc. is needed.

    my @httpHeader = $q->http();
    # log('info', "HTTP-Header: " . join(", ", @httpHeader ) );
    log('info', "User Name: " . $q->http('HTTP_USER_NAME'));

    my $loggedInUser = $q->http('HTTP_X_USERNAME');
    # $loggedInUser = 'termite'; # DEBUG !! REMOVE ME !!
    if( $loggedInUser ) {
      my $sql = "SELECT admin FROM persons WHERE stringid=?";
      my $sth = $dbh->prepare( $sql );
      $sth->execute( $loggedInUser );
      my ($admin) = $sth->fetchrow_array();
      log( 'info', "Admin flag for user <$loggedInUser>: $admin" );
      $isAdmin{ $loggedInUser } = $admin > 0;
      $user = $loggedInUser;
    }
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
# initialise the frame html template that is around all detail pages.
#
sub initFrame( $ )
{
  my ($header) = @_;

  $htmlTmpl->param( Header => $header );
  $htmlTmpl->param( isAdmin => $isAdmin{ $user } || 0 );
  $htmlTmpl->param( User => $user );
}

sub sayHello
{
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();
  initFrame( "Welcome to Hermes" );

  my $detailTmpl = $self->load_tmpl( 'info.tmpl', die_on_bad_params => 1, cache => 0 );

  my $msgList = latestNMessages(10);
  my $notiList = latestNRawNotifications( 25 );
  my $cnt = @{$notiList};

  $detailTmpl->param( CntRawNotifications => $cnt );
  $detailTmpl->param( RawNotiLastHour => countRawNotificationsInHours( 1 ) );
  $detailTmpl->param( LatestMessages => $msgList );
  $detailTmpl->param( countMessages => countMessages() );
  $detailTmpl->param( RawNotifications => $notiList );

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

sub editType()
{
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();
  my $type = $q->param( 'type' );
  return "" unless( $type );

  my $tmpl = $self->load_tmpl( 'edittype.tmpl',
			       die_on_bad_params => 0,
			       cache => 1 );

  my $status;
  my $previewTmpl;
  my $detailsRef = notificationDetails( $type );
  my $tmplFile = templateFileName( $detailsRef->{_type} );

  if ( $q->param( 'tmplEdit' ) && $isAdmin{$user} ) {
    log( 'debug', "template was edited!" );
    $previewTmpl = $q->param('tmplEdit');

    log( 'debug', "Dosave: " . $q->param('dosave' ));

    if ( $q->param( 'dosave' ) && $q->param('dosave') eq ' Save ' ) {
      log('debug', "SAVING the template" );
      # save the template
      if ( -w $tmplFile ) {
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

  $tmpl->param( type  => $detailsRef->{_type} );
  $tmpl->param( added => $detailsRef->{_added} );
  $tmpl->param( delay => $detailsRef->{_defaultdelay} );

  my @names;

  foreach ( @{$detailsRef->{_parameterList}} ) {
    log( 'debug', "Parameter : $_" );
    push @names, { 'name' => $_, 
		   'value' => $detailsRef->{$_} };
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
  $tmpl->param( admin => $isAdmin{$user} || 0 );
  $tmpl->param( user  => $user || "unknown" );
  initFrame( "Hermes Notification Type Details" );
  $htmlTmpl->param( Content => $tmpl->output );

  return $htmlTmpl->output;

}

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
      log('debug', "Adding parameter: <$param> = <" . $noti->{$param} . ">" );
      $paramHash{$param} = $noti->{$param};
    }
    $tmpl->param( \%paramHash );

    return $tmpl->output;
  }
  return "no template available!";
}

$dbh = Hermes::DBI->connect();

1;
