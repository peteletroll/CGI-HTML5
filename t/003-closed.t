use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('CGI::HTML5') };

#########################

my $Q = CGI::HTML5->new();
ok($Q);

my $t;

$t = $Q->elt(\"br");
isa_ok($t, "CGI::HTML5::EscapedString");
is_deeply($t, "<br>");

$t = $Q->elt(\"img", { src => "z" });
isa_ok($t, "CGI::HTML5::EscapedString");
is_deeply($t, "<img src=\"z\">");

$t = $Q->elt(\"input", { type => "checkbox" }, { checked => "checked", other => undef });
isa_ok($t, "CGI::HTML5::EscapedString");
is_deeply($t, "<input checked type=\"checkbox\">");

