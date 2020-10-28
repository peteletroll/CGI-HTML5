use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('CGI::HTML5') };

#########################

local $CGI::LIST_CONTEXT_WARN = 0; # more retrocompatible than multi_param()

my $Q = CGI::HTML5->new("a=a-val&b=b-val&c=c-val-1&c=c-val-2");
ok($Q);

my $QQ = $Q->clone();
ok($QQ);

foreach ($Q, $QQ) {
	is_deeply([ sort $_->param() ], [ "a", "b", "c" ]);
	is_deeply([ sort $_->param("a") ], [ "a-val" ]);
	is_deeply([ sort $_->param("b") ], [ "b-val" ]);
	is_deeply([ sort $_->param("c") ], [ "c-val-1", "c-val-2" ]);
}

