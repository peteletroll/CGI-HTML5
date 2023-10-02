#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Std;

use CGI::HTML5;

sub gethtml($);
sub deparse($);

my $progname = $0;
$progname =~ s/.*\///;

my %opt = ();
getopts("u:", \%opt) or exit 1;

my @html = ();

if (exists $opt{u}) {
	push @html, gethtml($opt{u});
}

@html or push @html, <>;

my $tree = CGI::HTML5->parse_html(@html);

print deparse($tree), "\n";

exit 0;

sub gethtml($) {
	my ($url) = @_;
	require LWP::UserAgent;
	my $res = LWP::UserAgent->new()->get($url);
	$res->is_success or die "$progname: $url: ", $res->status_line, "\n";
	$res->content_type eq "text/html"
		or die "$progname: $url: unsupported content type ", $res->content_type, "\n";
	$res->decoded_content
}

sub deparse($) {
	my ($tree) = @_;

	if (eval { require Data::Dump; 1 }) {
		return Data::Dump::dump($tree);
	}

	require Data::Dumper;
	my $dumper = Data::Dumper->new([ $tree ]);
	$dumper->Terse(1)->Indent(1)->Useqq(1)->Quotekeys(0)->Sortkeys(1);
	$dumper->Dump()
}

