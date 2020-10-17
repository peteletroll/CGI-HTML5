use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('CGI::HTML5') };

#########################

my $Q = CGI::HTML5->new("a=a-val&b=b-val&c=c-val-1&c=c-val-2");
ok($Q);

my $QQ = $Q->clone();
ok($QQ);

foreach ($Q, $QQ) {
	is_deeply([ sort $_->multi_param() ], [ "a", "b", "c" ]);
	is_deeply([ sort $_->multi_param("a") ], [ "a-val" ]);
	is_deeply([ sort $_->multi_param("b") ], [ "b-val" ]);
	is_deeply([ sort $_->multi_param("c") ], [ "c-val-1", "c-val-2" ]);
}

