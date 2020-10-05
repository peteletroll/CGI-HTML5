# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl CGI-HTML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('CGI::HTML') };

#########################

my $Q = CGI::HTML->new();
ok($Q);
is_deeply($Q->tag(
	[ \"b", sub { map { [ \"i", $_ ] } qw(a b) } ],
), "<b><i>a</i></b><b><i>b</i></b>");

is_deeply($Q->tag(
	sub { map { [ \"i", $_ ] } qw(a b) },
), "<i>a</i><i>b</i>");

