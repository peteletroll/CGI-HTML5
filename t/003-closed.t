# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl CGI-HTML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);
is($Q->tag_br(), "<br>");
is($Q->tag_img({ src => "z" }), "<img src=\"z\">");
is($Q->tag_input({ type => "checkbox", checked => "checked", other => undef }),
	"<input checked type=\"checkbox\">");

