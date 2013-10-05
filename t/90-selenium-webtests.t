#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Try::Tiny;
use lib (-d 't'? 't/lib' : 'lib');
use Selenium::TestUtil qw( &&skipcheck driver $app KEYS );

driver->get("http://$app/");
like( driver->get_title, qr/RapidApp/, 'page title' );
print KEYS->{enter}."\n";

done_testing;