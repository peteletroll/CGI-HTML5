use strict;
use warnings;

use Test::More tests => 25;
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

is_deeply($Q->hs(\"input", { type => "text", name => "a" }, $Q->sticky("default")),
	"<input name=\"a\" type=\"text\" value=\"a1\">");
is_deeply($Q->hs(\"input", { type => "text", name => "a" }, $Q->sticky("default")),
	"<input name=\"a\" type=\"text\" value=\"a2\">");
is_deeply($Q->hs(\"input", { type => "text", name => "a" }, $Q->sticky("default")),
	"<input name=\"a\" type=\"text\" value=\"default\">");

$Q->reset_form();
is_deeply($Q->hs(\"textarea", { name => "a" }, $Q->sticky("default")),
	"<textarea name=\"a\">a1</textarea>");
is_deeply($Q->hs(\"textarea", { name => "a" }, $Q->sticky("default")),
	"<textarea name=\"a\">a2</textarea>");
is_deeply($Q->hs(\"textarea", { name => "a" }, $Q->sticky("default")),
	"<textarea name=\"a\">default</textarea>");

$Q->reset_form();
is_deeply($Q->hs(\"input", { name => "a", type => "checkbox", value => "a1" }, $Q->sticky("a1")),
	"<input checked name=\"a\" type=\"checkbox\" value=\"a1\">"
	. "<input name=\".checkbox\" type=\"hidden\" value=\"a\">");
is_deeply($Q->hs(\"input", { name => "a", type => "checkbox", value => "a1" }, $Q->sticky("a1")),
	"<input name=\"a\" type=\"checkbox\" value=\"a1\">");
is_deeply($Q->hs(\"input", { name => "a", type => "checkbox", value => "a2" }, $Q->sticky("a1")),
	"<input checked name=\"a\" type=\"checkbox\" value=\"a2\">");
is_deeply($Q->hs(\"input", { name => "a", type => "checkbox", value => "a2" }, $Q->sticky("a1")),
	"<input name=\"a\" type=\"checkbox\" value=\"a2\">");

is_deeply($Q->hs(\"input", { name => "c", type => "checkbox", value => "c1" }, $Q->sticky("c1")),
	"<input name=\"c\" type=\"checkbox\" value=\"c1\">"
	. "<input name=\".checkbox\" type=\"hidden\" value=\"c\">");
is_deeply($Q->hs(\"input", { name => "c", type => "checkbox", value => "c2" }, $Q->sticky("c1")),
	"<input name=\"c\" type=\"checkbox\" value=\"c2\">");

my $Q0 = CGI::HTML5->new("");
is_deeply($Q0->hs(\"input", { name => "c", type => "checkbox", value => "c1" }, $Q0->sticky("c1")),
	"<input checked name=\"c\" type=\"checkbox\" value=\"c1\">"
	. "<input name=\".checkbox\" type=\"hidden\" value=\"c\">");
is_deeply($Q0->hs(\"input", { name => "c", type => "checkbox", value => "c2" }, $Q0->sticky("c1")),
	"<input name=\"c\" type=\"checkbox\" value=\"c2\">");

$Q->reset_form();
is_deeply($Q->hs(\"select", { name => "a" }, [
		[ \"optgroup", { label => "grp" },
			[ \"option", { value => "a1" }, $Q->sticky("a1"), "Hi&Bye" ] ],
		[ \"option", { value => "a2" }, $Q->sticky("a1"), "a2" ],
		[ \"option", { value => "a3" }, $Q->sticky("a1"), "a3" ]
	]),
	"<select name=\"a\">\n<optgroup label=\"grp\">\n<option selected value=\"a1\">Hi&amp;Bye</option>\n"
	. "</optgroup>\n"
	. "<option selected value=\"a2\">a2</option>\n"
	. "<option value=\"a3\">a3</option>\n"
	. "</select>"
	. "<input name=\".select\" type=\"hidden\" value=\"a\">");

is_deeply($Q->hs(\"select", { name => "c" }, [
		[ \"optgroup", { label => "grp" },
			[ \"option", { value => "c1" }, $Q->sticky("c1"), "Hi&Bye" ] ],
		[ \"option", { value => "c2" }, $Q->sticky("c1"), "c2" ],
		[ \"option", { value => "c3" }, $Q->sticky("c1"), "c3" ]
	]),
	"<select name=\"c\">\n<optgroup label=\"grp\">\n<option value=\"c1\">Hi&amp;Bye</option>\n"
	. "</optgroup>\n"
	. "<option value=\"c2\">c2</option>\n"
	. "<option value=\"c3\">c3</option>\n"
	. "</select>"
	. "<input name=\".select\" type=\"hidden\" value=\"c\">");

is_deeply($Q0->hs(\"select", { name => "c" }, [
		[ \"optgroup", { label => "grp" },
			[ \"option", { value => "c1" }, $Q0->sticky("c1"), "Hi&Bye" ] ],
		[ \"option", { value => "c2" }, $Q0->sticky("c1"), "c2" ],
		[ \"option", { value => "c3" }, $Q0->sticky("c1"), "c3" ]
	]),
	"<select name=\"c\">\n<optgroup label=\"grp\">\n<option selected value=\"c1\">Hi&amp;Bye</option>\n"
	. "</optgroup>\n"
	. "<option value=\"c2\">c2</option>\n"
	. "<option value=\"c3\">c3</option>\n"
	. "</select>"
	. "<input name=\".select\" type=\"hidden\" value=\"c\">");

