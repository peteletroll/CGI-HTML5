# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl CGI-HTML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);
is_deeply($Q->tag_div("Hi & Bye"), "<div>Hi &amp; Bye</div>\n");
is_deeply($Q->tag_span("Hi & Bye"), "<span>Hi &amp; Bye</span>");
is_deeply($Q->tag_div($Q->tag_span("Hi & Bye")), "<div><span>Hi &amp; Bye</span></div>\n");
is_deeply($Q->tag_span($Q->tag_div("Hi & Bye")), "<span><div>Hi &amp; Bye</div>\n</span>");
is_deeply($Q->tag_div({ class => "c1" }, "Hi",
	{ class => "c2" }, "Bye"),
	"<div class=\"c1\">Hi</div>\n<div class=\"c2\">Bye</div>\n");
is_deeply($Q->tag_span({ class => "c1" }, "Hi",
	{ class => "c2" }, "Bye"),
	"<span class=\"c1\">Hi</span><span class=\"c2\">Bye</span>");

