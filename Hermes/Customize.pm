#
# Copyright (c) 2010 Klaas Freitag <freitag@suse.de>, Novell Inc.
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
package Hermes::Customize;

# This package can be changed to customize the behaviour of Hermes and 
# influence its decisions on who will get a message based on the parameters. 
# Currently Hermes calls two interface functions in the Customize.pm module.
# These need to be reimplemented!
#
# 1. generateSubscriberListRef( $msgType, $params );
#    This sub generates a list of users of the system who are subscribed to
#    the given MsgType with the also given set of parameters. This is the 
#    place where Filters need to be implemented on base of MsgType and 
#    the parameters. 
#
#    For example, the Message Type is PRODUCT_CHANGE, but your Hermes has
#    a subscription filter filtering on product = name all subscriptions
#    that do not pass this filter should be dropped out. Check the 
#    example implementation in Buildservice.pm for now. TODO
#
# 2. expandMessageTemplateParams( $templateObject, $msgRef )
#    This gets the message template (which is a HTML:Template object) and 
#    the message parameters. This sub can compute if the template contains
#    keys which need to be added to the values hash. 
#    The default implementation just returns an empty hash because nothing
#    additionally is needed. 
# 
use strict;
use Exporter;

use Data::Dumper;

use Hermes::Config;
use Hermes::DB;
use Hermes::Log;
use Hermes::Util;

use Hermes::Buildservice;

use vars qw(@ISA @EXPORT);

@ISA	    = qw(Exporter);
@EXPORT	    = qw( generateSubscriberListRef expandMessageTemplateParams );


sub generateSubscriberListRef( $$ )
{
  my( $msgType, $paramRef ) = @_;
  # Call the filter implementation from Buildservice.pm
  return expandNotification( $msgType, $paramRef );
}

sub expandMessageTemplateParams( $$ )
{
  my ( $paramHash, $tmpl ) = @_;
  
  my @paramNames = $tmpl->param();
  log( 'info', "Parameters: " . join( ", ", @paramNames ) );
  
  if( isInArray( "diff", \@paramNames ) &&
      $paramHash->{project} && $paramHash->{package} && $paramHash->{sourcerevision} ) {
  
    $paramHash->{diff} = packageDiff( $paramHash->{project}, $paramHash->{package}, $paramHash->{sourcerevision} );
    log('info', "Result diff: " . $paramHash->{diff} );
  }
  return $paramHash;
}

1;
