package CGI::HTML;

use 5.028001;
use strict;
use warnings;

use Carp;

use CGI qw(-utf8 -noxhtml);
binmode STDOUT, ":utf8";

our @ISA = qw(CGI);

our $VERSION = '0.01';

sub new($@) {
	my $pkg = shift;
	my $new = $pkg->SUPER::new(@_);
	$new->charset("utf8");
	$new->{__PACKAGE__} = { };
	return $new;
}

sub clone($) {
	$_[0]->new($_[0]);
}

sub tag($@) {
	my $self = shift;
	scalar $self->_to_html(\@_)
}

sub literal($@) {
	my $self = shift;
	_escaped(@_)
}

### initialization

# from https://developer.mozilla.org/en-US/docs/Web/HTML/Element
our @TAGLIST = qw(
	a abbr address area article aside audio
	b base bdi bdo blockquote body br button
	canvas caption cite code col colgroup
	data datalist dd del details dfn dialog div dl dt
	em embed
	fieldset figcaption figure footer form
	h1 h2 h3 h4 h5 h6 head header hgroup hr html
	i iframe img input ins
	kbd
	label legend li link
	main map mark menu meta meter
	nav noscript
	object ol optgroup option output
	p param picture pre progress
	q
	rb rp rt rtc ruby
	s samp script section select slot small source span strong style sub summary sup
	table tbody td template textarea tfoot th thead time title tr track
	u ul
	var video
	wbr
);

# from https://developer.mozilla.org/en-US/docs/Glossary/empty_element
our %EMPTY = map { $_ => 1 } qw(
	area
	base br
	col
	embed
	hr
	img input
	link
	meta
	param
	source
	track
	wbr
);

our %NEWLINE = map { $_ => 1 } qw(
	body
	div
	head html
	p
	table tr
);

our %DEFAULT_ATTR = (
);

our %TAG = ();

foreach my $tag (@TAGLIST) {
	my $nl = $NEWLINE{$tag} ? "\n" : "";
	$TAG{$tag} = $EMPTY{$tag} ?
		sub {
			my $self = shift;
			my $attr = _default_attr($tag);
			while (ref $_[0] eq "HASH") {
				$attr = { %$attr, %{+shift} };
			}
			@_ and croak "no content allowed in <$tag>";
			_escaped(_open_tag($tag, $attr), $nl)
		} :
		sub {
			my $self = shift;
			my $attr = _default_attr($tag);
			my $open = undef;
			my $close = _close_tag($tag) . $nl;
			my @ret = ();
			foreach my $c (@_) {
				my $r = ref $c;
				if ($r eq "HASH") {
					$attr = { %$attr, %$c };
					$open = undef;
					next;
				}
				$r eq "CGI::HTML::EscapedString" or croak "unsupported reference to $r";
				$open ||= _open_tag($tag, $attr);
				push @ret, _escaped($open . "$c" . $close);
			}
			@ret or push @ret, _open_tag($tag, $attr), $close;
			wantarray ? @ret : _escaped(@ret)
		};
}

### main processing

sub _to_html($$) {
	@_ == 2 or confess "_to_html() called with ", scalar @_, " parameters instead of 2";
	my ($self, $obj) = @_;
	defined $obj or return wantarray ? () : undef;
	my $r = ref $obj;
	$r or return _escape_text($obj);
	$r eq "CGI::HTML::EscapedString" and return $obj;
	$r eq "ARRAY" or croak "bad _to_html($r) call";

	my $fun = undef;
	my @lst = @$obj;
	my @ret = ();

	if (@lst && ref $lst[0] eq "SCALAR") {
		my $tag = ${shift @lst};
		$fun = $TAG{$tag};
		ref $fun eq "CODE" or croak "unknown tag <$tag>";
	}

	while (@lst) {
		my $elt = shift @lst;
		defined $elt or next;
		my $r = ref $elt;
		if ($r eq "CODE") {
			unshift @lst, ($elt->($self));
			next;
		}
		if ($r eq "HASH") {
			$fun or croak "attributes not allowed here";
			push @ret, $elt;
			next;
		}
		push @ret, $self->_to_html($elt);
	}

	$fun and return $fun->($self, @ret);
	_escaped(@ret)
}

### tag utilities

sub _open_tag($$) {
	my ($t, $a) = @_;
	$a = _attr($a);
	"<$t$a>"
}

sub _close_tag($) {
	my ($t) = @_;
	"</$t>"
}

### attribute utilities

sub _default_attr($) {
	my ($tag) = @_;
	my $attr = $DEFAULT_ATTR{$tag};
	$attr ? { %$attr, -tag => $tag } : { -tag => $tag }
}

sub _attr($) {
	my ($a) = @_;
	$a or return "";
	my $ret = "";
	foreach my $n (sort keys %$a) {
		$n =~ /^-/ and next;
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
	"\xa0" => "&nbsp;",
);

{
	package CGI::HTML::EscapedString;
	use overload '""' => sub { ${$_[0]} },
		fallback => 0;
}

sub _escaped(@) {
	bless \(join "", @_), "CGI::HTML::EscapedString"
}

sub _escape_text($) {
	my ($s) = @_;
	$s =~ s{([<>&\xa0])}{ $ENT{$1} ||= sprintf("&#x%x;", ord($1)) }ges;
	_escaped($s)
}

sub _escape_attr($) {
	my ($s) = @_;
	$s =~ s{([<>&'"\x00-\x19\xa0])}{ $ENT{$1} ||= sprintf("&#x%x;", ord($1)) }ges;
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
