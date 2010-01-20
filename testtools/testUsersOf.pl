#!/usr/bin/perl

use Hermes::Log;
use Hermes::Buildservice(extractUserFromMeta, usersOfPackage, usersOfProject, applyFilter);
use Data::Dumper;

my $xml = <<ENDL
<project name="openSUSE:Factory">
  <title>openSUSE Factory</title>
  <description>Our bleeding edge distribution. This will become the next official openSUSE distribution, Alpha and Beta versions are mastered from this distribution.

Have a look at http://en.opensuse.org/Factory_Distribution for more details.</description>
  <person role="maintainer" userid="darix"/>
  <person role="bugowner" userid="coolo"/>
  <person role="maintainer" userid="coolo"/>
  <person role="bugowner" userid="freitag"/>
  <person role="maintainer" userid="oertel"/>
  <build>
    <disable repository='snapshot'/>
    <disable repository='staging'/>
  </build>
  <publish>
    <enable repository='images' arch='local'/>
    <disable/>
  </publish>
  <debuginfo>
    <enable/>
  </debuginfo>
  <repository name="images">
    <arch>local</arch>
    <arch>i586</arch>
    <arch>x86_64</arch>
    <arch>ppc</arch>
    <arch>ppc64</arch>
  </repository>
  <repository name="snapshot">
    <arch>x86_64</arch>
    <arch>i586</arch>
  </repository>
  <repository name="staging">
    <arch>ppc</arch>
    <arch>i586</arch>
  </repository>
  <repository name="standard">
    <arch>i586</arch>
    <arch>x86_64</arch>
    <arch>ppc</arch>
    <arch>ppc64</arch>
  </repository>
</project>

ENDL
;
my $userHashRef = extractUserFromMeta( $xml );

foreach my $user( keys %$userHashRef ) {
  print "  ##  $user -> $userHashRef->{$user}\n";
}

my $href = usersOfProject( "home:kfreitag:Kraft" );
print Dumper( $href );

my $res = applyFilter( { _userId => 'kfreitag', package => 'Kraft', project => 'home:kfreitag:Kraft' },
		       { string => '_packagebugowner', operator =>  'special'} );
print "1. Result of apply-Filter: $res\n";

$res = applyFilter( { _userId => 'markojung', package => 'Kraft', project => 'home:kfreitag:Kraft' },
		       { string => '_packagebugowner', operator =>  'special'} );
print "2. Result of apply-Filter: $res\n";

$res = applyFilter( { _userId => 'coolo', package => 'Kraft', project => 'home:kfreitag:Kraft' },
		       { string => '_packagebugowner', operator =>  'special'} );
print "3. Result of apply-Filter: $res\n";


