use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('CGI::HTML5') };

#########################

my $Q = CGI::HTML5->new();
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
isa_ok($t, "CGI::HTML5::EscapedString");
is_deeply($t, "<div><b>Hi</b> &amp; <i>Bye</i></div>\n");

$t = $Q->elt(
        \"div",
        [
                [ \"b", "Hi" ],
                $Q->literal(" & "),
                [ \"i", "Bye" ]
        ]
);
isa_ok($t, "CGI::HTML5::EscapedString");
is_deeply($t, "<div><b>Hi</b> & <i>Bye</i></div>\n");

