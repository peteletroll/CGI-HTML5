use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);

my $t;

$t = $Q->_to_html([
	\"div",
	[
		[ \"b", "Hi" ],
		" & ",
		[ \"i", "Bye" ]
	]
]);
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($Q->_to_html([
	\"div",
	[
		[ \"b", "Hi" ],
		" & ",
		[ \"i", "Bye" ]
	]
]), "<div><b>Hi</b> &amp; <i>Bye</i></div>\n");

$t = $Q->tag(
        \"div",
        [
                [ \"b", "Hi" ],
                $Q->literal(" &amp; "),
                [ \"i", "Bye" ]
        ]
);
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<div><b>Hi</b> &amp; <i>Bye</i></div>\n");

