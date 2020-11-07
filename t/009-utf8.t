use strict;
use warnings;

use Test::More tests => 271;
BEGIN { use_ok('CGI::HTML5') };

#########################

sub _escape($) {
	my ($s) = @_;
	utf8::upgrade($s);
	utf8::encode($s);
	$s =~ s{([^\w])}{ sprintf "%%%02X", ord($1) }ge;
	$s
}

my @tst = ("a", "\xe0", "\x{20ac}");
foreach my $name (@tst) {
	my $uname = _escape($name);
	foreach my $val1 (@tst) {
		my $uval1 = _escape($val1);
		foreach my $val2 (@tst) {
			my $uval2 = _escape($val2);
			my $qs = CGI::HTML5->new({ $name => [ $val1, $val2 ]})->query_string();
			is($qs, "$uname=$uval1;$uname=$uval2", "query string value '$qs'");

			local $CGI::LIST_CONTEXT_WARN = 0;

			my $Q = CGI::HTML5->new($qs);
			is($Q->query_string(), $qs, "query string round trip");
			is_deeply([ $Q->param() ], [ $name ], "param list check");
			is_deeply([ $Q->param($name) ], [ $val1, $val2 ], "param value check");
			my $p = $Q->param($name);
			is(length($p), 1, "param() with utf8");
			is_deeply($Q->hs(\"input", { name => $name }, $Q->sticky()),
				"<input name=\"$name\" type=\"text\" value=\"$val1\">",
				"input tag");
			is_deeply($Q->hs(\"input", { name => $name }, $Q->sticky()),
				"<input name=\"$name\" type=\"text\" value=\"$val2\">",
				"input tag");
			is_deeply($Q->hs(\"input", { name => $name }, $Q->sticky()),
				"<input name=\"$name\" type=\"text\" value=\"\">",
				"input tag");

			is_deeply($Q->textfield(-name => $name),
				"<input type=\"text\" name=\"$name\" value=\"$val1\">",
				"CGI::textfield()");
			is_deeply($Q->textarea(-name => $name),
				"<textarea name=\"$name\" >$val1</textarea>",
				"CGI::textarea()");
		}
	}
}

