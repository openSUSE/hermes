#!/usr/bin/perl

use Hermes::Buildservice(extractUserFromMeta);

my $xml = <<ENDL
<project name="openSUSE:Factory">
  <title>openSUSE Factory</title>
  <description>Our bleeding edge distribution. This will become the next official openSUSE distribution, Alpha and Beta versions are mastered from this distribution.

Have a look at http://en.opensuse.org/Factory_Distribution for more details.</description>
  <person role="maintainer" userid="darix"/>
  <person role="bugowner" userid="coolo"/>
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
  print "  ##  $user\n";
}

print "If you read oertel and darix above everything is fine.\n";


