use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);

