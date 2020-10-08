use strict;
use warnings;

use Test::More tests => 24;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);

is_deeply(scalar $Q->_to_html([ ], ""), "");

my $t = $Q->literal("<br>", "");
is_deeply($Q->_to_html($t, ""), $t);
is_deeply($Q->_to_html([ $t ], ""), $t);

my $s = "Hi & Bye";
my $e = CGI::HTML::_escape_text($s);
my $es = "$e";

is_deeply($Q->_to_html($s, ""), $e);
is_deeply($Q->_to_html($s, sub { "" }), $e);
is_deeply($Q->_to_html($s, sub { () }), $e);
is_deeply(scalar $Q->_to_html([ ], ""), "");

is_deeply($Q->_to_html([ \"b", $s ], "t"), "<b>$es</b>");
is_deeply($Q->_to_html([ \"b", sub { $s } ], "t"), "<b>$es</b>");
is_deeply($Q->_to_html([ \"b", [ $s ] ], "t"), "<b>$es</b>");
is_deeply($Q->_to_html([ \"b", [ sub { $s } ] ], "t"), "<b>$es</b>");

is_deeply($Q->_to_html([ \"b", $s, $s ], "t"), "<b>$es</b>" x 2);
is_deeply($Q->_to_html([ \"b", sub { ($s, $s) } ], "t"), "<b>$es</b>" x 2);
is_deeply($Q->_to_html([ \"b", [ $s, $s ] ], "t"), "<b>$es$es</b>");
is_deeply($Q->_to_html([ \"b", [ sub { ($s, $s) } ] ], "t"), "<b>$es$es</b>");

is_deeply($Q->_to_html([ \"b", [ \"i", $s, $s ] ], "t"), "<b><i>$es</i><i>$es</i></b>");
is_deeply($Q->_to_html([ \"b", [ \"i", sub { ($s, $s) } ] ], "t"), "<b><i>$es</i><i>$es</i></b>");
is_deeply($Q->_to_html([ \"b", [ \"i", [ $s, $s ] ] ], "t"), "<b><i>$es$es</i></b>");
is_deeply($Q->_to_html([ \"b", [ \"i", [ sub { ($s, $s) } ] ] ], "t"), "<b><i>$es$es</i></b>");

sub iterator($$);
sub iterator($$) {
	my ($obj, $count) = @_;
	$count > 0 or return ();
	($obj, iterator($obj, $count - 1))
}

$t = [ \"b", "a" ];
my $ts = $Q->_to_html($t, "t");
$ts = "$ts";
is_deeply(scalar $Q->_to_html([ iterator($t, 5) ], ""), scalar($ts x 5));
is_deeply([ $Q->_to_html([ \"i", iterator($t, 5) ], "t") ], [ "<i>$ts</i>" x 5 ]);

is_deeply(scalar $Q->_to_html(
	[ \"b",
		{ class => "b" }, "Hi",
		{ class => "c" }, "Bye",
	],
"t"), "<b class=\"b\">Hi</b><b class=\"c\">Bye</b>");

