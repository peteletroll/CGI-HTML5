#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Std;
use Data::Dumper;

use CGI::HTML5;

my $progname = $0;
$progname =~ s/.*\///;

sub gethtml($) {
	my ($url) = @_;
	require LWP::UserAgent;
	my $res = LWP::UserAgent->new()->get($url);
	$res->is_success or die "$progname: $url: ", $res->status_line, "\n";
	$res->content_type eq "text/html"
		or die "$progname: $url: unsupported content type ", $res->content_type, "\n";
	$res->decoded_content
}

my %opt = ();
getopts("u:", \%opt) or exit 1;

my @html = ();

if (exists $opt{u}) {
	push @html, gethtml($opt{u});
}

@html or push @html, <>;

my $dumper = Data::Dumper->new([ CGI::HTML5->parse_html(@html) ]);
$dumper->Terse(1)->Indent(1)->Useqq(1)->Quotekeys(0)->Sortkeys(1);
print $dumper->Dump(), "\n";

