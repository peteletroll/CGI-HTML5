#!/usr/bin/perl

use strict;
use warnings;

use lib "/home/pietro/perl/CGI-HTML5/lib";
use CGI::HTML5;
use CGI::Carp qw(fatalsToBrowser);

#use Data::Dumper;
#sub tostr($) {
#	Data::Dumper->new([ $_[0] ], [ "\$Q" ])
#		->Terse(1)
#		->Indent(1)
#		->Sortkeys(1)
#		->Dump()
#}

use Data::Dump qw(dump);
sub tostr($) {
	dump($_[0])
}

my $ASCII = 0;

my @METHOD = (0..2);
my %METHOD = (
	0 => "GET",
	1 => "POST",
	2 => "POST/multipart",
);

my $Q0 = CGI::HTML5->new();
$Q0->ascii($ASCII);

my $METHOD = $Q0->param(".method");
defined $METHOD && $METHOD{$METHOD} or $Q0->param(".method", $METHOD = 0);

my @VAL = ("\xe0", "b", "c", "d", "\x{20ac}");
my $DEF = $VAL[2];

binmode STDOUT, ":utf8";
print $Q0->header();
print $Q0->start_html(
	-title => "CGI::HTML5 form stickiness test - [@VAL]",
	-meta => {
		generator => ref($Q0),
		viewport => "width=device-width, initial-scale=1.0"
	},
	-author => "pietro\@superbia",
	-style => { -code => q{
		body {
			font-family: sans-serif;
		}

		table {
			width: 100%;
			border-collapse: collapse;
			margin-left: auto;
			margin-right: auto;
		}

		td {
			vertical-align: top;
			border: solid black 1px;
			padding: 2ex;
			width: 50%;
		}

		div.scroll-x {
			overflow-x: auto;
		}

		form p {
			display: inline-block;
			vertical-align: top;
			padding: 1ex;
			border: solid #ccc 1px;
		}

		ul.params {
			font-weight: bold;
		}

		ul.params ol {
			font-weight: normal;
		}
	} },
), "\n";

print "<table><tr>\n";
print "<td colspan=\"2\" style=\"text-align: center\">";
print "Method:";
foreach my $p (@METHOD) {
	my $l = $METHOD{$p};
	my $href = $Q0->url(-relative => 1) . "?.method=$p";
	my $a = [ \"a", { href => $href }, $l ];
	print "\n";
	if ($p == $METHOD) {
		print $Q0->hs(\"b", $a);
	} else {
		print $Q0->hs($a);
	}
}
print "&nbsp;";
print "</td></tr><tr><td>\n";

{
	my $Q = CGI::HTML5->new();
	$Q->ascii($ASCII);
	print "<p><b>", ref($Q), "</b></p>\n";
	$Q->path_info();
	my $dump = tostr($Q);
	my $post = $Q->param(".method") || 0;
	print $post > 1 ?
		$Q->start_multipart_form(-action => $Q->url(-relative => 1)) :
		$Q->start_form(-method => ($post ? "post" : "get"), -action => $Q->url(-relative => 1));
	print "\n";
	print $Q->hs(\"p", map { [ \"input", { name => "input-text", size => 1 }, $Q->sticky($_) ], "\n" } @VAL);
	print $Q->hs(\"p", map { [ \"textarea", { name => "textarea" }, $Q->sticky($_) ], "\n" } @VAL);
	print $Q->hs(\"p", map { [ \"label", [ \"input", { name => "input-checkbox", type => "checkbox", value => $_ }, $Q->sticky($DEF) ], $_ ], "\n" } @VAL);
	print $Q->hs(\"p", map { [ \"label", [ \"input", { name => "input-radio", type => "radio", value => $_ }, $Q->sticky($DEF) ], $_ ], "\n" } @VAL);
	print $Q->hs(\"p", \"select", { name => "select" }, map { [ \"option", { value => $_ }, $Q->sticky($DEF), $_ ] } @VAL);
	print $Q->hs(\"p", \"select", { name => "select-multiple", multiple => \1, size => scalar @VAL }, map { [ \"option", { value => $_ }, $Q->sticky($DEF), $_ ] } @VAL);
	print $Q->hs(\"p", [ \"input", { type => "file", name => "input-file" } ]) if $post > 1;
	print $Q->hs([ \"br" ], \"p",
		[ \"input", { type => "submit" } ],
		$Q->hs(\"input", { type => "hidden", name => ".method" }, $Q->sticky(0)));
	print $post > 1 ?
		$Q->end_multipart_form() :
		$Q->end_form();

	print $Q0->hs(\"hr");
	print $Q0->hs($Q->query_string());
	print $Q0->hs(\"hr");
	show_params($Q);
	print $Q0->hs(\"hr");
	print $Q0->hs(\"div", { class => "scroll-x" }, \"pre", $dump), "\n";
}

print "</td><td>\n";

{
	my $Q = CGI->new();
	print "<p><b>", ref($Q), "</b></p>\n";
	$Q->charset("utf8");
	$Q->path_info();
	my $dump = tostr($Q);
	my $post = $Q->param(".method") || 0;
	print $post > 1 ?
		$Q->start_multipart_form(-action => $Q->url(-relative => 1)) :
		$Q->start_form(-method => ($post ? "post" : "get"), -action => $Q->url(-relative => 1));
	print "\n";
	print "<p>", (map { $Q->textfield(-name => "input-text", -value => $_, -size => 1), "\n" } @VAL), "</p>\n";
	print "<p>", (map { $Q->textarea(-name => "textarea", -value => $_), "\n" } @VAL), "</p>\n";
	print "<p>", $Q->checkbox_group(-name => "input-checkbox", -values => \@VAL, -default => [ $DEF ]), "</p>\n";
	print "<p>", $Q->radio_group(-name => "input-radio", -values => \@VAL, -default => [ $DEF ]), "</p>\n";
	print "<p>", $Q->popup_menu(-name => "select", -values => \@VAL, -default => [ $DEF ]), "</p>\n";;
	print "<p>", $Q->scrolling_list(-name => "select-multiple", -values => \@VAL, -default => [ $DEF ], -size => scalar @VAL, -multiple => 1), "</p>\n";
	print "<p>", $Q->filefield(-name => "input-file"), "</p>\n" if $post > 1;
	print "<br><p>",
		$Q->submit(),
		$Q->hidden(-name => ".method", -value => 0),
		"</p>\n";
	print $post > 1 ?
		$Q->end_multipart_form() :
		$Q->end_form();

	print $Q0->hs(\"hr");
	print $Q0->hs($Q->query_string());
	print $Q0->hs(\"hr");
	show_params($Q);
	print $Q0->hs(\"hr");
	print "<div class=\"scroll-x\">", $Q0->hs(\"pre", $dump), "</div>\n";
}

print "</td></tr></table>\n";

print $Q0->end_html();

sub show_params {
	my ($Q) = @_;
	local $CGI::LIST_CONTEXT_WARN = 0;
	$Q->param() and print $Q0->hs(\"ul", { class => "params" },
		map {
			[ \"li", [ $_, \"ol", [ [ \"li*", map { "$_" } $Q->param($_) ] ] ] ]
		} sort $Q->param()
	);
}

