#! perl

use strict;
use warnings;
use Test::More;
use Try::Tiny;
use lib (-d 't'? 't/lib' : 'lib');
my ($driver, $app);
use SeleniumTestsDriver driver => \$driver, app_url => \$app;
use Selenium::Remote::WDKeys;

$driver->get("http://$app/");
like( $driver->get_title, qr/RapidApp/, 'page title' );

done_testing;