#!/usr/bin/perl

use Hermes::Log;
use Hermes::Buildservice(extractUserFromMeta, usersOfPackage, usersOfProject, applyFilter);
use Data::Dumper;
use Hermes::Statistics;

my $msgRef = unsentMessages();

print Dumper( $msgRef );


