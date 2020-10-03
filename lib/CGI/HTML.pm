package CGI::HTML;

use 5.028001;
use strict;
use warnings;

use Carp;

use CGI qw(-utf8);
binmode STDOUT, ":utf8";

our @ISA = qw(CGI);

our $VERSION = '0.01';

sub new($@) {
	my $pkg = shift;
	my $new = $pkg->SUPER::new(@_);
	$new->charset("utf8");
	return $new;
}

sub clone($) {
	$_[0]->new($_[0]);
}

### initialization

our @TAG = qw(
	a abbr acronym address area
	b base bdo big blockquote body br button
	caption cite code col colgroup
	dd del dfn div dl dt
	em
	fieldset form frame frameset
	h1 h2 h3 h4 h5 h6
	head hr html
	i iframe img input ins
	kbd
	label legend li link
	map meta
	noframes noscript
	object ol optgroup option
	p param pre
	q
	samp script select small span strong style sub sup
	table tbody td textarea tfoot th thead title tr tt
	ul
	var
);

our %CLOSED = map { $_ => 1 } qw(
	area
	base br
	col
	frame
	hr
	img input
	link
	meta
	param
);

### tag utilities

sub _open_tag($$) {
	my ($t, $a) = @_;
	$t =~ /[\s<>&'"=\/]/ and croak "unsafe tag name '$t'";
	$a = _attr($a);
	_escaped("<$t$a>")
}

sub _close_tag($) {
	my ($t) = shift;
	$t =~ /[\s<>&'"=\/]/ and croak "unsafe tag name '$t'";
	_escaped("</$t>")
}

### attribute utilities

sub _attr($) {
	my ($a) = @_;
	my $ret = "";
	foreach my $n (sort keys %$a) {
		my $v = $a->{$n};
		defined $v or next;
		$n =~ /[\s<>&'"=\/]/ and croak "unsafe attribute name '$n'";
		$ret .= " $n";
		$ret .= "=\"" . _escape_attr($v) . "\"" if $v ne $n;
	}
	$ret
}

### escaping utilities

our %ENT = (
	"<" => "&lt;",
	">" => "&gt;",
	"&" => "&amp;",
	"\"" => "&quot;",
);

{
	package CGI::HTML::EscapedString;
	use overload '""' => sub { ${$_[0]} };
}

sub _escaped($) {
	my ($s) = shift;
	utf8::upgrade($s);
	bless \$s, "CGI::HTML::EscapedString";
}

sub _escape_text($) {
	my ($s) = @_;
	$s =~ s{([<>&])}{ $ENT{$1} ||= sprintf("&#x%x;", ord($1)) }ges;
	_escaped $s
}

sub _escape_attr($) {
	my ($s) = @_;
	$s =~ s{([<>&'"\x00-\x19])}{ $ENT{$1} ||= sprintf("&#x%x;", ord($1)) }ges;
	$s
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CGI::HTML - Perl extension for blah blah blah

=head1 SYNOPSIS

  use CGI::HTML;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for CGI::HTML, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Pietro Cagnoni, E<lt>pietro@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Pietro Cagnoni

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
