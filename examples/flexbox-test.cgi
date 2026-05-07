#!/usr/bin/perl

# from https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/CSS_layout/Flexbox

use strict;
use warnings;

use CGI::HTML5;
use CGI::Carp qw(fatalsToBrowser);

my $CSS = <<'END';

body {
	background-color: white;
	font-family: sans-serif;
}

header {
	background: purple;
}

h1 {
	text-align: center;
	color: white;
	margin: 0;
}

section {
	zoom: 0.8;
	display: flex;
	flex-flow: row wrap;
}

article {
	padding: 1ex;
	margin: 2em 1em;
	background: aqua;
	flex: 20ex 1;
}

END
$CSS =~ s/^\s+/\n/;
$CSS =~ s/\s+$/\n/;

sub layout($) {
	my ($Q) = @_;
	print $Q->hs(\"header", \"h1", "Flexbox Test");

	my @articles = map {
		[ \"article", 
			[ \"h2", "Article $_" ],
			[ \"p", "Content of article n. $_" ],
			[ \"p", "More content of article n. $_" ],
			[ \"p", join(" ", map { "word-$_" } (1 .. 2 * $_)) ],
		]
	} (1..10);
	print $Q->hs(\"section", @articles);
}

sub main($) {
	my ($Q) = @_;
	print $Q->header();
	print $Q->start_html(-title => "Flexbox Test",
		-style => { -code => $CSS });
	layout($Q);
	print $Q->end_html();
}

binmode STDOUT, ":utf8";
main(CGI::HTML5->new())

