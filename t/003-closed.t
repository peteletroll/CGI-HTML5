use strict;
use warnings;

use Test::More tests => 12;
BEGIN { use_ok('CGI::HTML5') };

#########################

my $Q = CGI::HTML5->new();
ok($Q);

my $t;

$t = $Q->comment("this --> that");
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<!-- this - - > that -->");

$t = $Q->hs(\"br");
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<br>");

$t = $Q->hs(\"img", { src => "z" });
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<img src=\"z\">");

$t = $Q->hs(\"input", { type => "checkbox" }, { checked => \1, other => undef });
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<input checked type=\"checkbox\">");

$t = $Q->hs(\"input", { type => "checkbox" }, { checked => \0, other => undef });
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<input type=\"checkbox\">");

