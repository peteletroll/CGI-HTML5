# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl CGI-HTML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 11;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new("a=a-val&b=b-val&c=c-val-1&c=c-val-2");
ok($Q);

my $QQ = $Q->clone();
ok($QQ);

foreach ($Q, $QQ) {
	is_deeply([ sort $_->multi_param() ], [ "a", "b", "c" ]);
	is_deeply([ sort $_->multi_param("a") ], [ "a-val" ]);
	is_deeply([ sort $_->multi_param("b") ], [ "b-val" ]);
	is_deeply([ sort $_->multi_param("c") ], [ "c-val-1", "c-val-2" ]);
}

