use strict;
use warnings;

use Test::More tests => 22;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);

is_deeply(scalar $Q->_to_html([ ]), "");

my $t = $Q->literal("<br>", "");
is_deeply($Q->_to_html($t), $t);
is_deeply($Q->_to_html([ $t ]), $t);

my $s = "Hi & Bye";
my $e = CGI::HTML::_escape_text($s);
my $es = "$e";

is_deeply($Q->_to_html($s), $e);
is_deeply(scalar $Q->_to_html([ ]), "");

is_deeply($Q->_to_html([ \"b", $s ]), "<b>$es</b>");
is_deeply($Q->_to_html([ \"b", sub { $s } ]), "<b>$es</b>");
is_deeply($Q->_to_html([ \"b", [ $s ] ]), "<b>$es</b>");
is_deeply($Q->_to_html([ \"b", [ sub { $s } ] ]), "<b>$es</b>");

is_deeply($Q->_to_html([ \"b", $s, $s ]), "<b>$es</b>" x 2);
is_deeply($Q->_to_html([ \"b", sub { ($s, $s) } ]), "<b>$es</b>" x 2);
is_deeply($Q->_to_html([ \"b", [ $s, $s ] ]), "<b>$es$es</b>");
is_deeply($Q->_to_html([ \"b", [ sub { ($s, $s) } ] ]), "<b>$es$es</b>");

is_deeply($Q->_to_html([ \"b", [ \"i", $s, $s ] ]), "<b><i>$es</i><i>$es</i></b>");
is_deeply($Q->_to_html([ \"b", [ \"i", sub { ($s, $s) } ] ]), "<b><i>$es</i><i>$es</i></b>");
is_deeply($Q->_to_html([ \"b", [ \"i", [ $s, $s ] ] ]), "<b><i>$es$es</i></b>");
is_deeply($Q->_to_html([ \"b", [ \"i", [ sub { ($s, $s) } ] ] ]), "<b><i>$es$es</i></b>");

sub iterator($$);
sub iterator($$) {
	my ($obj, $count) = @_;
	$count > 0 or return ();
	($obj, iterator($obj, $count - 1))
}

$t = [ \"b", "a" ];
my $ts = $Q->_to_html($t);
$ts = "$ts";
is_deeply(scalar $Q->_to_html([ iterator($t, 5) ]), scalar($ts x 5));
is_deeply([ $Q->_to_html([ \"i", iterator($t, 5) ]) ], [ ("<i>$ts</i>") x 5 ]);

is_deeply(scalar $Q->_to_html([ \"b",
	{ class => "b" }, "Hi",
	{ class => "c" }, "Bye",
]), "<b class=\"b\">Hi</b><b class=\"c\">Bye</b>");

