use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('CGI::HTML5') };

#########################

my $Q = CGI::HTML5->new();
ok($Q);

my $t;

$t = $Q->hs(
	[ \"b", sub { map { [ \"i", $_ ] } qw(a b) } ],
);
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<b><i>a</i></b><b><i>b</i></b>");

$t = $Q->hs(
        sub { map { [ \"i", $_ ] } qw(a b) },
);
isa_ok($t, "CGI::HTML5::HTMLString");
is_deeply($t, "<i>a</i><i>b</i>");

