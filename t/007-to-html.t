use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);

my $t;

my $s = "Hi & Bye";
my $es = CGI::HTML::_escape_text($s);

is_deeply(scalar $Q->_to_html([ ], ""), "");

is_deeply($Q->_to_html($s, ""), $es);

$t = $Q->literal("<br>", "");
is_deeply($Q->_to_html($t, ""), $t);
is_deeply($Q->_to_html([ $t ], ""), $t);

