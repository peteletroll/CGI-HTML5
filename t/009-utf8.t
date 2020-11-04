use strict;
use warnings;

use Test::More tests => 19;
BEGIN { use_ok('CGI::HTML5') };

#########################

use Data::Dump qw(dump);

sub _fix_utf8_params($) {
	my ($self) = @_;
	foreach (@{$self->{".parameters"} || [ ]}) {
		my $o = $_;
		utf8::is_utf8($_) || utf8::decode($_) foreach $_, @{$self->{param}{$o}};
		$self->{param}{$_} = delete $self->{param}{$o};
	}
}

foreach my $tst ("a", "\xe0", "\x{20ac}") {
	utf8::upgrade($tst);
	my $utst = $tst;
	utf8::upgrade($utst);
	utf8::encode($utst);
	$utst =~ s{([^\w])}{ sprintf "%%%02X", ord($1) }ge;
	my $qs = CGI::HTML5->new({ $tst => [ $tst, $tst ]})->query_string();
	is($qs, "$utst=$utst;$utst=$utst", "query string value '$qs'");

	local $CGI::LIST_CONTEXT_WARN = 0;

	my $Q = CGI::HTML5->new($qs);
	_fix_utf8_params($Q);
	$Q->reset_form();
	print "CGI ", dump([ $tst, $Q ]), "\n";
	is($Q->query_string(), $qs, "query string round trip");
	is_deeply([ $Q->param() ], [ $tst ], "param list check");
	is_deeply([ $Q->param($tst) ], [ $tst, $tst ], "param value check");
	my $p = $Q->param($tst);
	is(length($p), 1, "param() with utf8");
	is_deeply($Q->hs(\"input", { name => $tst }, $Q->sticky()),
		"<input name=\"$tst\" type=\"text\" value=\"$tst\">");
}

