use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);

my $t;

$t = $Q->elt(
	[ \"b", sub { map { [ \"i", $_ ] } qw(a b) } ],
);
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<b><i>a</i></b><b><i>b</i></b>");

$t = $Q->elt(
        sub { map { [ \"i", $_ ] } qw(a b) },
);
isa_ok($t, "CGI::HTML::EscapedString");
is_deeply($t, "<i>a</i><i>b</i>");

