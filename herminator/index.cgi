#!/usr/bin/perl -w

use Hermi::Rest;

my $webapp = Hermi::Rest->new(
    TMPL_PATH => 'templates/' 
);

$webapp->run();




