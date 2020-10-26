use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('CGI::HTML5') };

#########################

my $Q = CGI::HTML5->new();
ok($Q);

my $t;

$t = $Q->comment("this --> that");
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<!-- this - - > that -->");

$t = $Q->elt(\"br");
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<br>");

$t = $Q->elt(\"img", { src => "z" });
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<img src=\"z\">");

$t = $Q->elt(\"input", { type => "checkbox" }, { checked => "checked", other => undef });
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<input checked type=\"checkbox\">");

