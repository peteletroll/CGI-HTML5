use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);

is_deeply(scalar $Q->_to_html([ ]), "");

is_deeply($Q->_to_html("Hi & Bye"), "Hi &amp; Bye");

