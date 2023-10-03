use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('CGI::HTML5') };

$HTML::TreeBuilder::DEBUG = 0;

#########################

sub show_tagset() {
	no warnings "once";
	$HTML::TreeBuilder::DEBUG or return;
	use Data::Dump qw(dump);
	print "Tagset: ", Data::Dump::dump({
		emptyElement => [ sort keys %HTML::Tagset::emptyElement ],
		optionalEndTag => [ sort keys %HTML::Tagset::optionalEndTag ],
		linkElements => \%HTML::Tagset::linkElements,
		# boolean_attr => \%HTML::Tagset::boolean_attr,
		isPhraseMarkup => [ sort keys %HTML::Tagset::isPhraseMarkup ],
		is_Possible_Strict_P_Content => [ sort keys %HTML::Tagset::is_Possible_Strict_P_Content ],
		isHeadElement => [ sort keys %HTML::Tagset::isHeadElement ],
		# isList => [ sort keys %HTML::Tagset::isList ],
		# isTableElement => [ sort keys %HTML::Tagset::isTableElement ],
		# isFormElement => [ sort keys %HTML::Tagset::isFormElement ],
		isBodyMarkup => [ sort keys %HTML::Tagset::isBodyMarkup ],
		isHeadOrBodyElement => [ sort keys %HTML::Tagset::isHeadOrBodyElement ],
		isKnown => [ sort keys %HTML::Tagset::isKnown ],
		canTighten => [ sort keys %HTML::Tagset::canTighten ],
		p_closure_barriers => \@HTML::Tagset::p_closure_barriers,
		isCDATA_Parent => [ sort keys %HTML::Tagset::isCDATA_Parent ],
	}), "\n";
}

sub parse(@) {
	my $ret = CGI::HTML5->parse_html(map { "$_" } @_);
}

is_deeply(parse(), [ ], "empty html");

show_tagset();

is_deeply(parse('<i class="c">t</i>'), [ \"i", { class => "c" }, "t" ], "simple html");

is_deeply(parse('<details><summary><b>s</b></summary><div><i>c</i></div></details>'),
	[ \"details", [ \"summary", [ \"b", "s" ] ], [ \"div", [ \"i", "c" ] ] ],
	"HTML5 tags");

