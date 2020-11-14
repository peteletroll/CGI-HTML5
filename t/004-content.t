use strict;
use warnings;

use Test::More tests => 18;
BEGIN { use_ok('CGI::HTML5') };

#########################

my $Q = CGI::HTML5->new();
ok($Q);

my $t;

$t = $Q->hs(\"div");
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<div></div>\n");

$t = $Q->hs(\"div", "Hi & Bye");
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<div>Hi &amp; Bye</div>\n");

$t = $Q->hs(\"span", "Hi & Bye");
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<span>Hi &amp; Bye</span>");

$t = $Q->hs(\"div", $Q->hs(\"span", "Hi & Bye"));
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<div><span>Hi &amp; Bye</span></div>\n");

$t = $Q->hs(\"span", $Q->hs(\"div", "Hi & Bye"));
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<span><div>Hi &amp; Bye</div>\n</span>");

$t = $Q->hs(\"div", { class => "c1" }, "Hi",
	{ class => "c2" }, "Bye");
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<div class=\"c2\">HiBye</div>\n");

$t = $Q->hs(\"div*", { class => "c1" }, "Hi",
	{ class => "c2" }, "Bye");
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<div class=\"c1\">Hi</div>\n<div class=\"c2\">Bye</div>\n");

$t = $Q->hs(\"span", { class => "c1" }, "Hi",
	{ class => "c2" }, "Bye");
is_deeply($t, "<span class=\"c2\">HiBye</span>");

$t = $Q->hs(\"span*", { class => "c1" }, "Hi",
	{ class => "c2" }, "Bye");
is_deeply($t, "<span class=\"c1\">Hi</span><span class=\"c2\">Bye</span>");

