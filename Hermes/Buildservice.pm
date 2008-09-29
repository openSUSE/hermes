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
#  Andreas Bauer <abauer@suse.de>
#
package Hermes::Buildservice;

use strict;
use Exporter;

use HTML::Template;
use LWP::UserAgent;
use URI::Escape;

use Hermes::Config;
use Hermes::DBI;
use Hermes::Log;
use Hermes::Person;
use Hermes::Util;

use Data::Dumper;

use vars qw(@ISA @EXPORT @EXPORT_OK $dbh );

@ISA	    = qw(Exporter);
@EXPORT	    = qw( expandFromMsgType );

our($hermesUserInfoRef, $cachedProject, $cachedPackage, $cachedWatchlist);

#
# expand the message, that means
# generate the @to, @cc and @bcc list
# set text and subject
#
# The returned hash must contain the following tags:
# subject   - the message subject
# body      - the message body
# type      - the message type, as coming into the method
# delay     - the default delay, might be overridden by user setting later
# to        - array ref to a list of to receivers
# cc        - array ref to a list of cc receivers
# bcc       - array ref to a list of bcc receivers.
# from      - sender string
# replyTo   - reply to string
#
sub expandFromMsgType( $$ )
{
  my ($type, $paramHash) = @_;

  my $re;
  $re->{type}    = $type;
  $re->{delay}   = 0; # replace by system default
  $re->{subject} = "Subject for message type <$type>";

  $re->{cc}      = [];
  $re->{bcc} = undef;

  $re->{replyTo} = undef;
  $re->{from} = $paramHash->{from} || "hermes\@opensuse.org";

  my $text;
  my $filename = templateFileName( $type );
  log( 'info', "template filename: <$filename>" );

  if( -r "$filename" ) {
    my $tmpl = HTML::Template->new(filename => "$filename",
				   die_on_bad_params => 0,
				   cache => 1 );
    # Fill the template
    $tmpl->param( $paramHash );
    $text = $tmpl->output;

    if( $text =~ /^\s*\@subject: ?(.+)$/im ) {
      $re->{subject} = $1;
      log( 'info', "Extracted subject <$re->{subject}> from template!" );
      $text =~ s/^\s*\@subject:.*$//im;
    }
    # log('info', "Template body: <$text>" );

  } else {
    log( 'warning', "Can not find <$filename>, using default" );
    $text = "Hermes received the notification <$type>\n\n";
    if( keys %$paramHash ) {
      $text .= "These parameters were added to the notification:\n";
      foreach my $key( keys %$paramHash ) {
	$text .= "   $key = " . $paramHash->{$key} . "\n";
      }
    }
  }

  $re->{body} = $text;

  # query the receivers
  my $sql = "SELECT mtp.id, mtp.person_id, p.stringid FROM ";
  $sql .= "msg_types_people mtp, msg_types mt, persons p WHERE ";
  $sql .= "mtp.msg_type_id = mt.id AND mt.msgtype=? AND mtp.person_id=p.id AND enabled=1";

  my $query = $dbh->prepare( $sql );
  $query->execute( $type );
  my $userListRef = undef;

  invalidateCache();

  while( my ($subscriptId, $personId, $personString) = $query->fetchrow_array()) {
    # do that only if not private or if the project param is there 
    # and the personId is user in the project.
    my @filters = getFilters( $subscriptId );
    $paramHash->{_userId} = $personString;

    # loop over all filters. Since these filter are implicit AND connected, all
    # filters have to apply.
    my $filterOk = 1;
    foreach my $filterRef ( @filters ) {
      $filterOk = applyFilter( $paramHash, $filterRef );
      if( ! $filterOk ) {
	log( 'info', "Filter $filterRef->{filterlog} failed!" );
	last;
      }
      log( 'info', $filterRef->{filterlog} . " adds user to to-line: " . $personId );
    }
    if( $filterOk ) {
      push @{$re->{to}}, $personId;
    }
  }

  # Take the hermes user into bcc 
  my $hermesid = $hermesUserInfoRef ? $hermesUserInfoRef->{id} : undef;
  if( $hermesUserInfoRef && $hermesUserInfoRef->{id} ) {
    $re->{bcc} = [ $hermesUserInfoRef->{id} ];
  }

  my $receiverCnt = 0;
  foreach my $header( ('to', 'cc', 'bcc') ) {
    if( $re->{$header} ) {
      my $cnt = @{$re->{$header}};
      $receiverCnt += $cnt;
      log( 'info', "These $header-receiver were found: " . join( ", ", @{$re->{$header}} ) ) if( $cnt );
    }
  }
  $re->{receiverCnt} = $receiverCnt;
  return $re;
}

sub getFilters( $ ) 
{
  my( $subscriptId ) = @_;

  my $sql = "SELECT p.name, filter.operator, filter.filterstring FROM ";
  $sql   .= "subscription_filters filter, parameters p WHERE "; 
  $sql   .= "filter.parameter_id=p.id AND filter.subscription_id=?";

  my $query = $dbh->prepare( $sql );
  $query->execute( $subscriptId );

  my @re;
  while( my ($param, $operator, $string) = $query->fetchrow_array()) {
    push @re, { param => $param, operator => $operator, string => $string,
	        filterlog => "Filter: param <$param>, operator <$operator>, value <$string>" };
  }
  return @re;
}

sub applyFilter( $$ ) 
{
  my( $paramHash, $filterRef ) = @_;
  my $res = 1;

  if( $filterRef->{operator} eq "special" ) {

    if( $filterRef->{string} eq "_myprojects" ) {
      # user must be involved in the project.
      my $user = $paramHash->{_userId};
      my $prj = $paramHash->{project};
      my $prjStr = $prj || 'unknown';

      log( 'info', "Checking for user <$user> involved in prj <$prjStr>" );
      my $userHashRef = usersOfProject( $prj );
      if( ! $userHashRef->{$user} ) {
	log( 'info', "User <$user> is NOT in the maintainer group for <$prjStr>" );
	$res = 0;
      } else {
	log( 'info', "User <$user> is in the maintainer group for <$prjStr>" );
      }

    } elsif( $filterRef->{string} eq "_mypackages" ) {
      # user must be involved in the package.
      my $user = $paramHash->{_userId};
      my $pkg = $paramHash->{package};
      my $prj = $paramHash->{project};
      my $pkgStr = $pkg || 'unknown';

      log( 'info', "Checking for user <$user> involved in pkg <$pkgStr>" );
      my $userHashRef = usersOfPackage( $prj, $pkg );
      if( ! $userHashRef->{$user} ) {
	log( 'info', "User <$user> is NOT in the maintainer group for <$pkgStr>" );
	$res = 0;
      } else {
	log( 'info', "User <$user> is in the maintainer group for <$pkgStr>" );
      }

    } elsif( $filterRef->{string} eq "_mywatchlist" ) {
      #user mast have $project in his watchlist
      my $user = $paramHash->{_userId};
      my $prj = $paramHash->{project};
      
      log( 'info', "Checking for project <$prj> in watchlist of user <$user>" );
      my $watchlistHash = userWatchList( $user );

      if ( ! $watchlistHash->{$prj} ) {
        log( 'info', "User <$user> has project <$prj> NOT in his watchlist" );
        $res = 0;
      } else {
        log( 'info', "User <$user> has project <$prj> in his watchlist" );
      }

    } elsif( $filterRef->{string} eq "_myrequests" ) {
      # user is maintainer of source or target project
      my $user = $paramHash->{_userId};
      my $sPrj = $paramHash->{sourceproject};
      my $tPrj = $paramHash->{targetproject};

      if( $sPrj and $tPrj ) {
        log( 'info', "Checking if <$user> is interested in request <$paramHash->{id}> ".
                     "with source project <$sPrj>, target project <$tPrj>");
        # check source project
        my $sPrjUsers = usersOfProject( $sPrj );
        if( ! $sPrjUsers->{$user} ) {
	  log( 'info', "User <$user> is NOT in the maintainer group for <$sPrj>" );
          # check target project only if source check failed
          my $tPrjUsers = usersOfProject( $tPrj );
          if( ! $tPrjUsers->{$user} ) {
	    log( 'info', "User <$user> is NOT in the maintainer group for <$tPrj>" );
            $res = 0;
          } else {
	    log( 'info', "User <$user> is in the maintainer group for <$tPrj>" );
          }
        } else {
	  log( 'info', "User <$user> is in the maintainer group for <$sPrj>" );
        }
      }

    } else {
      log( 'error', "Unknown special filter type " . $filterRef->{string} );
    }

  } elsif( $filterRef->{operator} eq "oneof" ) {
    # the parameter value must be contained in the filter string
    if( $paramHash->{ $filterRef->{param} } ) {
      # the parameter named in the filter exists
      my $searchStr = $paramHash->{ $filterRef->{param} };
      $searchStr =~ s/^\s*//; # wipe whitespaces
      $searchStr =~ s/\s*$//;
      $searchStr = quotemeta( $searchStr );

      my $str = $filterRef->{string};

      my @possibleValues = split( /\s*,\s*/, $str );
      my $success = grep( /$searchStr/, @possibleValues );
      log( 'info', "Filtering oneof <$searchStr> in [" . join( "|", @possibleValues ) . "]: " . $success );
      
      if( $success ) {
	$res = 1;
      } else {
	$res = 0;
      }
    } else {
      log( 'warning', "Filter references on non existing param <$filterRef->{param}>" );
      $res = 0;
    }
  } elsif( $filterRef->{operator} eq "regexp" ) {
    # the parameter value must match the regexp in the filter
    if( $paramHash->{ $filterRef->{param} } ) {
      my $searchStr = $paramHash->{ $filterRef->{param} };
      $searchStr =~ s/^\s*//; # wipe whitespaces
      $searchStr =~ s/\s*$//;
      $searchStr = quotemeta( $searchStr );

      my $regexp = $filterRef->{string};

      log( 'info', "Filtering regexp <$regexp> on <$searchStr>?" );

      unless( $searchStr && $regexp && $searchStr =~ /$regexp/ ) {
	$res = 0;
      }
    } else {
      $res = 0;
    }
  } else {
    log( 'error', "Invalid operator string: <$filterRef->{operator}" );
    $res = 0;
  }

  return $res;
}

sub usersOfProject( $ )
{
  my ($project) = @_;
  if( defined $cachedProject->{$project} ) {
    log( 'info', "Using userdata for $project from cache" );
    return $cachedProject->{$project}; 
  }

  my $userHashRef;

  if( $project ) {
    my $meta = callOBSAPI( 'prjMetaRef', ($project) );
    $userHashRef = extractUserFromMeta( $meta );
    $cachedProject->{$project} = $userHashRef;
    log( 'info', "These users are in project <$project>: " . join( ', ', keys %{$userHashRef} ) );
  } else {
    # unfortunately no project param, but privacy is requested.
    # -> problem
    log( 'warning', "Problem: Privacy is requested, but no param project" );
  }

  return $userHashRef;
}

sub usersOfPackage( $$ )
{
  my ($project, $package) = @_;
  if( defined $cachedPackage->{"$project/$package"} ) {
    log( 'info', "Using userdata for package $project/$package from cache" );
    return $cachedPackage->{"$project/$package"}; 
  }

  my $userHashRef;

  if($project and $package) {
    my $meta = callOBSAPI( 'pkgMetaRef', ( $project,$package ) );
    $userHashRef = extractUserFromMeta( $meta );
    $cachedPackage->{"$project/$package"} = $userHashRef;
    log( 'info', "These users are in package <$project/$package>: " . join( ', ', keys %{$userHashRef} ) );
  } else {
    log( 'warning', "Problem: usersOfPackage was called with project <$project>, package <$package>" );
  }

  return $userHashRef;
}

sub userWatchList( $$ )
{
  my ($user) = @_;
  if( defined $cachedWatchlist->{$user} ) {
    log( 'info', "Using userdata for $user from cache" );
    return $cachedWatchlist->{$user};
  }
  my $watchlistHashRef;

  if( $user ) {
    my $meta = callOBSAPI( 'personMetaRef', ($user) );
    $watchlistHashRef = extractProjectsFromPersonMeta( $meta );
    $cachedWatchlist->{$user} = $watchlistHashRef;
    log( 'info', "These Projects are watched by <$user>: " . join( ', ', keys %{$watchlistHashRef} ) );
  } else {
    # unfortunately no user param, but privacy is requested.
    # -> problem
    log( 'warning', "Problem: Privacy is requested, but no param user" );
  }

  return $watchlistHashRef;
}

sub invalidateCache()
{
    $cachedPackage = {};
    $cachedProject = {};
    $cachedWatchlist = {};
}

#
# calls the OBS API, uses credentials aus conf/hermes.conf
# returns the result as plain text or undef, if an error happened
# FIXME: report errors back to calling functions
#
sub callOBSAPI( $$;$ )
{
  my ( $function, @urlparams ) = @_;
  my $urlstr = "";
# my $auth = 0;
  foreach (@urlparams){
    if ( $urlstr != "" ){
      $urlstr .= '/';
    }
    $urlstr .= uri_escape( $_ );
  }
# return {} unless( $project );

  my %results;
  my $OBSAPIUrl = $Hermes::Config::OBSAPIBase ||  "http://api.opensuse.org/";
  $OBSAPIUrl =~ s/\s*$//; # Wipe whitespace at end.
  $OBSAPIUrl .= '/' unless( $OBSAPIUrl =~ /\/$/ );

  my $ua = LWP::UserAgent->new;
  $ua->agent( "Hermes Buildservice Processor" );
  my $uri = $OBSAPIUrl . "public/";

  if( $function eq 'prjMetaRef' || $function eq 'pkgMetaRef') {
    $uri .= "source/$urlstr/_meta";
  } elsif($function eq 'personMetaRef') {
    $uri .= "person/$urlstr/_watchlist";
#   $auth = 1;
  }

  log( 'info', "Asking $uri with GET" );

  my $req = HTTP::Request->new( GET => $uri );
  $req->header( 'Accept' => 'text/xml' );
# $req->authorization_basic( $Hermes::Config::OBSAPIUser,
#     			      $Hermes::Config::OBSAPIPasswd ) if($auth);

  my $res = $ua->request( $req );

  if( $res->is_success ) {
    return $res->decoded_content;
  } else {
    log( 'error', "API Call Error: " . $res->status_line . "\n" );
    return undef;
  }
}

#
# returns a list of users from the projects meta file
#
sub extractUserFromMeta( $ )
{
  my ($meta) = @_;
  my %retuser;

  if( $meta ) {
    my @xml = split(/\n/, $meta );
    my @people = grep ( /<person .+?\/>/, @xml );
    foreach my $pl (@people) {
      if( $pl =~ /userid=\"(.+?)\"/ ) {
	$retuser{$1} = 1 if( $1 );
      }
    }
  }
  return \%retuser;
}

#
# returns a list of watched projects of a user
#
sub extractProjectsFromPersonMeta( $ )
{
  my ($meta) = @_;
  my %retwatchlist;

  if ( $meta ) {
    $meta =~ s/.*?<watchlist>\s*(.*?)\s*<\/watchlist>.*/$1/gs;

    foreach ( split(/\n/,$meta) ) {
      $_ =~ s/.*?<project\sname\=\"(.+?)\"\/>.*?/$1/;
      $retwatchlist{$_} = 1 if( $1 );
    }
  }
  return \%retwatchlist;
}

$dbh = Hermes::DBI->connect();

$hermesUserInfoRef = personInfo( 'hermes2' ); # Get the hermes user info
if( $hermesUserInfoRef->{id} ) {
  log( 'info', "The hermes user id is " . $hermesUserInfoRef->{id} );
}

1;
