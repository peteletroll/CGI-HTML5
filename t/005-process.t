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
is_deeply($Q->_process([
	\"div",
	[
		[ \"b", "Hi" ],
		" & ",
		[ \"i", "Bye" ]
	]
]), "<div><b>Hi</b> &amp; <i>Bye</i></div>\n");

is_deeply($Q->tag(
	\"div",
	[
		[ \"b", "Hi" ],
		$Q->literal(" &amp; "),
		[ \"i", "Bye" ]
	]
), "<div><b>Hi</b> &amp; <i>Bye</i></div>\n");

