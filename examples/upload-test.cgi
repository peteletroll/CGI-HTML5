#!/usr/bin/perl

use strict;
use warnings;

use Data::Dump qw(dump);
use Devel::Peek;
sub peek($) {
	my $ret = "";
	open(my $ORIGSTDERR, ">&", STDERR)
		and close(STDERR)
		and open(STDERR, ">", \$ret)
		or die($!);
	Dump($_[0]);
	open(STDERR, ">&=" . fileno($ORIGSTDERR))
		or die($!);
	return $ret;
}

# use lib "/home/pietro/perl/old-CGI";
use lib "/home/pietro/perl/CGI-HTML5/lib";
use CGI::HTML5;
use CGI::Carp qw(fatalsToBrowser);

my $Q = CGI::HTML5->new();
# my $Q = CGI->new();

binmode \*STDOUT, ":utf8";

print $Q->header();

print $Q->start_html(-title => "file upload test");
print $Q->start_multipart_form();
print
	$Q->hidden(-name => "\xe0", -value => "\xe0"),
	$Q->hidden(-name => "\x{20ac}", -value => "\x{20ac}"),
	$Q->filefield(-name => "file"),
	$Q->submit();
print $Q->end_multipart_form();
print "<hr>\n";
print $Q->hs(\"p", "CGI version: $CGI::VERSION");

# print "<pre>", $Q->escapeHTML(dump(\%ENV)), "</pre>\n";
print "<pre>", $Q->escapeHTML(dump($Q)), "</pre>\n";
if ($Q->param("file")) {
	my $f = $Q->param("file");
	print "file: $f<br>\n";
	print "<pre>", $Q->escapeHTML(peek($f)), "</pre>\n";
	print "<pre>", $Q->escapeHTML(dump($f)), "</pre>\n";
	my $buf = "";
	my $len = 0;
	while (my $n = read($f, $buf, 8192)) {
		print "read: $n<br>\n";
		$len += $n;
	}
	print "length: $len<br>\n";
}
print $Q->end_html();

