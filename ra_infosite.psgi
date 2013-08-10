use strict;
use warnings;

use RA::InfoSite;

my $app = RA::InfoSite->apply_default_middlewares(RA::InfoSite->psgi_app);
$app;

