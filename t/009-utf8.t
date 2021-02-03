use strict;
use warnings;

use Test::More tests => 1409;
BEGIN { use_ok('CGI::HTML5') };

#########################

sub _escape($) {
	my ($s) = @_;
	utf8::upgrade($s);
	utf8::encode($s);
	$s =~ s{([^\w])}{ sprintf "%%%02X", ord($1) }ge;
	$s
}

sub _entities($) {
	CGI::HTML5::_escape_text($_[0])->string()
}

sub _to_ascii($$) {
	my ($text, $ascii) = @_;
	$ascii and $text =~ s{([\x{80}-\x{10ffff}])}{ sprintf("&#x%x;", ord($1)) }ges;
	$text
}

my @tst = ("a", "&", "\xe0", "\x{20ac}");
foreach my $ascii (0, 1) {
	foreach my $name (@tst) {
		my $uname = _escape($name);
		my $hname = _entities($name);
		foreach my $val1 (@tst) {
			my $uval1 = _escape($val1);
			my $hval1 = _entities($val1);
			foreach my $val2 (@tst) {
				my $uval2 = _escape($val2);
				my $hval2 = _entities($val2);
				my $qs = CGI::HTML5->new({ $name => [ $val1, $val2 ]})->query_string();
				is($qs, "$uname=$uval1;$uname=$uval2", "query string value '$qs'");

				local $CGI::LIST_CONTEXT_WARN = 0;

				my $Q = CGI::HTML5->new($qs);
				$Q->ascii($ascii);
				is($Q->query_string(), $qs, "query string round trip");
				is_deeply([ $Q->param() ], [ $name ], "param list check");
				is_deeply([ $Q->param($name) ], [ $val1, $val2 ], "param value check");
				my $p = $Q->param($name);
				is(length($p), 1, "param() with utf8");

				is_deeply($Q->hs(\"input", { name => $name }, $Q->sticky()),
					_to_ascii("<input name=\"$hname\" type=\"text\" value=\"$hval1\">", $ascii),
					"input tag");
				is_deeply($Q->hs(\"input", { name => $name }, $Q->sticky()),
					_to_ascii("<input name=\"$hname\" type=\"text\" value=\"$hval2\">", $ascii),
					"input tag");
				is_deeply($Q->hs(\"input", { name => $name }, $Q->sticky()),
					_to_ascii("<input name=\"$hname\" type=\"text\" value=\"\">", $ascii),
					"input tag");

				$Q = CGI::HTML5->new($qs);
				is_deeply($Q->hs(\"textarea", { name => $name }, $Q->sticky()),
					"<textarea name=\"$hname\">$hval1</textarea>",
					"textarea");
				is_deeply($Q->hs(\"textarea", { name => $name }, $Q->sticky()),
					"<textarea name=\"$hname\">$hval2</textarea>",
					"textarea");
				is_deeply($Q->hs(\"textarea", { name => $name }, $Q->sticky()),
					"<textarea name=\"$hname\"></textarea>",
					"textarea");
			}
		}
	}
}

