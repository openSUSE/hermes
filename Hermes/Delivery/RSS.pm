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
package Hermes::Delivery::RSS;

use strict;
use Exporter;
use XML::RSS;

use vars qw(@ISA @EXPORT);

use Hermes::Log;
use Hermes::Person;
use Hermes::Config;
use Data::Dumper;

@ISA     = qw( Exporter );
@EXPORT  = qw( sendRSS );

#
# Configuration needed: 
#  * Hermes::Config::StarshipBase .- the webapp dir
#  * Hermes::Config::rdfBasePath - the directory where to store the RDFs


sub sendRSS( $ )
{
  my ($msgRef) = @_;

  # Parametercheck
  my @receiver;
  push @receiver, @{$msgRef->{to}} if( $msgRef->{to} );
  push @receiver, @{$msgRef->{cc}} if( $msgRef->{cc} );
  push @receiver, @{$msgRef->{bcc}} if( $msgRef->{bcc} );


  foreach my $p ( @receiver ) {
    log( 'info', "RSS-Feed for person $p" );
    my $rss;

    # Loop over the to-list and write RSS feeds for everybody.
    my $personInfoRef = personInfo( $p );

    my $rdfPath = $Hermes::Config::RdfBasePath . "/$personInfoRef->{feedPath}";
    mkdir( $rdfPath, 0777 ) unless( -e $rdfPath );

    my $rdfFile = "$rdfPath/personal.rdf";
    if( -w $rdfFile ) {
      $rss = new XML::RSS( version => '1.0');
      $rss->parsefile( $rdfFile );
    } else {
      $rss = new XML::RSS( version => '1.0');
    }

    # FIXME: Make maximum item count configurable
    pop(@{$rss->{'items'}}) if (@{$rss->{'items'}} == 150); # only allow 150 entries.

    my $desc = "Personal Hermes RSS Feed";
    $desc .= " for $personInfoRef->{name}" if( $personInfoRef && $personInfoRef->{name} );

    $rss->channel( title        => "openSUSE Hermes",
		   link         => $Hermes::Config::StarshipBaseUrl . "/messages/",
		   description  => "Personal Hermes RSS Feed" );


    if( -e $rdfPath ) {

      log( 'info', "Writing RDF feed for user $personInfoRef->{email} to <$rdfFile>" );

      log( 'info', Dumper( $msgRef ));

      $rss->add_item( title => $msgRef->{subject},
		      link => $Hermes::Config::StarshipBaseUrl . "/messages/" . $msgRef->{msgid} ,
		      description => ($msgRef->{body} || '') );

      $rss->save( $rdfFile );
    }
  }
}
