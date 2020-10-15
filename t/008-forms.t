use strict;
use warnings;

use Test::More tests => 17;
BEGIN { use_ok('CGI::HTML') };

#########################

my $query = "a=a1;a=a2;b=b1;b=b2";
my $Q = CGI::HTML->new($query);
ok($Q);

ok($Q->_has_param("a"));
ok($Q->_has_param("b"));
ok(!$Q->_has_param("c"));

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

