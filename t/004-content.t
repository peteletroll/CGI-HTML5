# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl CGI-HTML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 15;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);

my $t;

$t = $Q->tag(\"div");
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<div></div>\n");

$t = $Q->tag(\"div", "Hi & Bye");
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<div>Hi &amp; Bye</div>\n");

$t = $Q->tag(\"span", "Hi & Bye");
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<span>Hi &amp; Bye</span>");

$t = $Q->tag(\"div", $Q->tag(\"span", "Hi & Bye"));
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<div><span>Hi &amp; Bye</span></div>\n");

$t = $Q->tag(\"span", $Q->tag(\"div", "Hi & Bye"));
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<span><div>Hi &amp; Bye</div>\n</span>");

$t = $Q->tag(\"div", { class => "c1" }, "Hi",
	{ class => "c2" }, "Bye");
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<div class=\"c1\">Hi</div>\n<div class=\"c2\">Bye</div>\n");

$t = $Q->tag(\"span", { class => "c1" }, "Hi",
	{ class => "c2" }, "Bye");
is_deeply($t, "<span class=\"c1\">Hi</span><span class=\"c2\">Bye</span>");

