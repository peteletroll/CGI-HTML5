use strict;
use warnings;

use Test::More tests => 21;
BEGIN { use_ok('CGI::HTML5') };

#########################

my $query = "a=a1;a=a2;b=b1;b=b2";
my $Q = CGI::HTML5->new($query);
ok($Q);

is($Q->_get_value("a"), "a1");
is($Q->_get_value("a"), "a1");

is($Q->_get_value("b", "", 1), "b1");
is($Q->_get_value("b"), "b2");
is($Q->_get_value("b", "", 1), "b2");
is($Q->_get_value("b"), undef);

is_deeply($Q->elt(\"input", { name => "a" }, $Q->value("default")),
	"<input name=\"a\" type=\"text\" value=\"a1\">");
is_deeply($Q->elt(\"input", { name => "a" }, $Q->value("default")),
	"<input name=\"a\" type=\"text\" value=\"a2\">");
is_deeply($Q->elt(\"input", { name => "a" }, $Q->value("default")),
	"<input name=\"a\" type=\"text\" value=\"default\">");

$Q->reset_form();
is_deeply($Q->elt(\"textarea", { name => "a" }, $Q->value("default")),
	"<textarea name=\"a\">a1</textarea>");
is_deeply($Q->elt(\"textarea", { name => "a" }, $Q->value("default")),
	"<textarea name=\"a\">a2</textarea>");
is_deeply($Q->elt(\"textarea", { name => "a" }, $Q->value("default")),
	"<textarea name=\"a\">default</textarea>");

$Q->reset_form();
is_deeply($Q->elt(\"input", { name => "a", type => "checkbox", value => "a1" }, $Q->value("a1")),
	"<input checked name=\"a\" type=\"checkbox\" value=\"a1\">");
is_deeply($Q->elt(\"input", { name => "a", type => "checkbox", value => "a1" }, $Q->value("a1")),
	"<input name=\"a\" type=\"checkbox\" value=\"a1\">");
is_deeply($Q->elt(\"input", { name => "a", type => "checkbox", value => "a2" }, $Q->value("a1")),
	"<input checked name=\"a\" type=\"checkbox\" value=\"a2\">");
is_deeply($Q->elt(\"input", { name => "a", type => "checkbox", value => "a2" }, $Q->value("a1")),
	"<input name=\"a\" type=\"checkbox\" value=\"a2\">");

$Q->reset_form();
is_deeply($Q->elt(\"input", { name => "c", type => "checkbox", value => "c1" }, $Q->value("c1")),
	"<input checked name=\"c\" type=\"checkbox\" value=\"c1\">");
is_deeply($Q->elt(\"input", { name => "c", type => "checkbox", value => "c2" }, $Q->value("c1")),
	"<input name=\"c\" type=\"checkbox\" value=\"c2\">");

$Q->reset_form();
is_deeply($Q->elt(\"select", { name => "a" }, [
		[ \"optgroup", { label => "grp" },
			[ \"option", { value => "a1" }, $Q->value("a1"), "Hi&Bye" ] ],
		[ \"option", $Q->value("a2"), "a2" ],
		[ \"option", $Q->value("a3"), "a3" ]
	]),
	"<select name=\"a\">\n<optgroup label=\"grp\">\n<option selected value=\"a1\">Hi&amp;Bye</option>\n"
	. "</optgroup>\n"
	. "<option selected value=\"a2\">a2</option>\n"
	. "<option value=\"a3\">a3</option>\n"
	. "</select>");

