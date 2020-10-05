use strict;
use warnings;

use Test::More tests => 8;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);

my $t;

$t = $Q->tag_br();
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<br>");

$t = $Q->tag_img({ src => "z" });
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<img src=\"z\">");

$t = $Q->tag_input({ type => "checkbox", checked => "checked", other => undef });
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<input checked type=\"checkbox\">");

