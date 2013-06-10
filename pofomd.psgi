use strict;
use warnings;
use lib 'lib';

use POFOMD;

my $app = POFOMD->apply_default_middlewares(POFOMD->psgi_app);
$app;

