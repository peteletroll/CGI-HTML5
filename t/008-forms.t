use strict;
use warnings;

use Test::More tests => 31;
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

$Q->start_form();
is_deeply($Q->hs(\"input", { type => "text", name => "a" }, $Q->sticky("default")),
	"<input name=\"a\" type=\"text\" value=\"a1\">");
is_deeply($Q->hs(\"input", { type => "text", name => "a" }, $Q->sticky("default")),
	"<input name=\"a\" type=\"text\" value=\"a2\">");
is_deeply($Q->hs(\"input", { type => "text", name => "a" }, $Q->sticky("default")),
	"<input name=\"a\" type=\"text\" value=\"default\">");
is($Q->end_form(), "</form>");

$Q->start_form();
is_deeply($Q->hs(\"textarea", { name => "a" }, $Q->sticky("default")),
	"<textarea name=\"a\">a1</textarea>");
is_deeply($Q->hs(\"textarea", { name => "a" }, $Q->sticky("default")),
	"<textarea name=\"a\">a2</textarea>");
is_deeply($Q->hs(\"textarea", { name => "a" }, $Q->sticky("default")),
	"<textarea name=\"a\">default</textarea>");
is($Q->end_form(), "</form>");

$Q->start_form();
is_deeply($Q->hs(\"input", { name => "a", type => "checkbox", value => "a1" }, $Q->sticky("a1")),
	"<input checked name=\"a\" type=\"checkbox\" value=\"a1\">");
is_deeply($Q->hs(\"input", { name => "a", type => "checkbox", value => "a1" }, $Q->sticky("a1")),
	"<input name=\"a\" type=\"checkbox\" value=\"a1\">");
is_deeply($Q->hs(\"input", { name => "a", type => "checkbox", value => "a2" }, $Q->sticky("a1")),
	"<input checked name=\"a\" type=\"checkbox\" value=\"a2\">");
is_deeply($Q->hs(\"input", { name => "a", type => "checkbox", value => "a2" }, $Q->sticky("a1")),
	"<input name=\"a\" type=\"checkbox\" value=\"a2\">");

is_deeply($Q->hs(\"input", { name => "c", type => "checkbox", value => "c1" }, $Q->sticky("c1")),
	"<input checked name=\"c\" type=\"checkbox\" value=\"c1\">");
is_deeply($Q->hs(\"input", { name => "c", type => "checkbox", value => "c2" }, $Q->sticky("c1")),
	"<input name=\"c\" type=\"checkbox\" value=\"c2\">");
is($Q->end_form(), "<div><input type=\"hidden\" name=\".cgifields\" value=\"c\" ><input type=\"hidden\" name=\".cgifields\" value=\"a\" ></div>\n</form>");

my $Q0 = CGI::HTML5->new("");
is_deeply($Q0->hs(\"input", { name => "c", type => "checkbox", value => "c1" }, $Q0->sticky("c1")),
	"<input checked name=\"c\" type=\"checkbox\" value=\"c1\">");
is_deeply($Q0->hs(\"input", { name => "c", type => "checkbox", value => "c2" }, $Q0->sticky("c1")),
	"<input name=\"c\" type=\"checkbox\" value=\"c2\">");
is($Q0->end_form(), "<div><input type=\"hidden\" name=\".cgifields\" value=\"c\" ></div>\n</form>");

$Q->start_form();
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
	. "</select>");

is_deeply($Q->hs(\"select", { name => "c" }, [
		[ \"optgroup", { label => "grp" },
			[ \"option", { value => "c1" }, $Q->sticky("c1"), "Hi&Bye" ] ],
		[ \"option", { value => "c2" }, $Q->sticky("c1"), "c2" ],
		[ \"option", { value => "c3" }, $Q->sticky("c1"), "c3" ]
	]),
	"<select name=\"c\">\n<optgroup label=\"grp\">\n<option selected value=\"c1\">Hi&amp;Bye</option>\n"
	. "</optgroup>\n"
	. "<option value=\"c2\">c2</option>\n"
	. "<option value=\"c3\">c3</option>\n"
	. "</select>");
is($Q->end_form(), "</form>");

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
	. "</select>");
is($Q0->end_form(), "<div><input type=\"hidden\" name=\".cgifields\" value=\"c\" ></div>\n</form>");

