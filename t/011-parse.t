use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('CGI::HTML5') };

#########################

sub parse(@) {
	my $ret = CGI::HTML5->parse_html(map { "$_" } @_);
}

is_deeply(parse(), [ ], "empty html 1");
is_deeply(parse(''), [ ], "empty html 2");
is_deeply(parse('<i class="c">t</i>'), [ \"i", { class => "c" }, "t" ], "simple html");

is_deeply(parse('<details><summary>s</summary></details>'),
	[ \"details", [ \"summary", "s" ] ],
	"HTML5 tags");

