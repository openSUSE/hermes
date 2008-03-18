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
use Hermes::Log;
use Hermes::Message;
use Hermes::Statistics;



# sub do_stuff : Path('do/stuff') { ... }
# sub do_more_stuff : Regex('^/do/more/stuff\/?$') { ... }
# sub do_something_else : Regex('do/something/else/(\w+)/(\d+)$') { ... }
use vars qw( $htmlTmpl );

sub setup {
  my $self = shift;
  $self->start_mode('hello');
  $self->run_modes(
		   'post'   => 'postMessage',
		   'notify' => 'postNotification',
		   'hello'  => 'sayHello',
		   'doc'    => 'showDoc'
		  );
  $self->mode_param( 'rm' );

  $htmlTmpl = $self->load_tmpl( 'hermes.tmpl',
				die_on_bad_params => 1,
				cache => 0 );

}

sub sayHello
{
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();
  $htmlTmpl->param( Header => "Welcome to Hermes" );

  my $detailTmpl = $self->load_tmpl( 'info.tmpl', die_on_bad_params => 1, cache => 0 );

  my $msgList = latestNMessages(10);
  $detailTmpl->param( LatestMessages => $msgList );
  $detailTmpl->param( countMessages => countMessages() );

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
  $htmlTmpl->param( Header => "Hermes Documentation" );
  $htmlTmpl->param( Content => $docTmpl->output );

  return $htmlTmpl->output;
}

sub postNotification {
  my $self = shift;

  my $q = $self->query();

  my $type = $q->param( 'type' );
  my $params = $q->Vars;

  my $id = sendNotification( $type, $params );

  return "<html><body>$id</body></html>";
}

sub postMessage {
  my $self = shift;

  # Get CGI query object
  my $q = $self->query();

  my $type    = $q->param( 'type' );
  my $subject = $q->param( 'subject' );
  my $body    = $q->param( 'body' );
  my @to      = $q->param( 'to' );
  my @cc      = $q->param( 'cc' );
  my @bcc     = $q->param( 'bcc' );
  my $from    = $q->param( 'from' );
  my $delayStr= uc $q->param( 'delay' );
  # FIXME: Security, perfect spammer!

  log( 'info', "This is delayStr: <$delayStr>" );
  # Required: subject, body, from, one entry in to
  unless( defined $subject && defined $body && defined $from && scalar @to > 0 ) {
    log( 'error', "Message incomplete, required are subject, from body and a to entry." );
    return "<h1>Error: Incomplete Message!</h1>";
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

  return "<html><body>$id</body></html>";
}

1;
