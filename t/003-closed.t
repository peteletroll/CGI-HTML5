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

