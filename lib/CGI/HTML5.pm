package CGI::HTML5;

use strict;
use warnings;

use Carp;

use CGI qw(-utf8 -noxhtml);
binmode STDOUT, ":utf8";

our @ISA = qw(CGI);

our $VERSION = '0.01';

our $EXTRA = "-- " . __PACKAGE__ . " data --";

our $DOCTYPE = "<!doctype html>";

sub new {
	my $pkg = shift;
	my $new = $pkg->SUPER::new(@_);
	$new->charset("utf8");
	$new->{$EXTRA} = { };
	$new->_extra("stack", [ ]);
	$new->reset_form();
	return $new;
}

sub clone {
	$_[0]->new($_[0]);
}

sub elt {
	my $self = shift;
	scalar $self->_to_html(\@_)
}

sub comment {
	my ($self) = shift;
	my $comment = CORE::join("", @_);
	$comment =~ s/-->/- - >/g;
	_htmlstring("<!-- $comment -->")
}

sub literal {
	my $self = shift;
	_htmlstring(@_)
}

sub open {
	my ($self, $tag, $attr) = @_;
	my $def = $CGI::HTML5::DEFAULT_ATTR{$tag};
	if ($attr) {
		$def and $attr = { %$def, %$attr };
	} else {
		$attr = $def;
	}
	_htmlstring(_open_tag($tag, $attr))
}

sub close {
	my ($self, $tag) = @_;
	_htmlstring(_close_tag($tag))
}

### CGI.pm compatibility

sub start_html {
	my $self = shift;
	my ($title, $author, $base, $xbase, $script, $noscript, $target, $meta, $head, $style, $dtd, $lang, $encoding, $declare_xml, @other) =
		CGI::rearrange([qw(TITLE AUTHOR BASE XBASE SCRIPT NOSCRIPT TARGET META HEAD STYLE DTD LANG ENCODING DECLARE_XML)], @_);
	my @head = ();
	defined $title and push @head, [ \"title", $title ];
	defined $author and push @head, [ \"link", { rev => "made", href => "mailto:$author" } ];
	($base || $xbase || $target) and push @head, [ \"base", { href => $xbase || $self->url(-path => 1), target => $target } ];
	ref $meta eq "HASH" and push @head, map { [ \"meta", { name => $_, content => $meta->{$_} } ] } sort keys %$meta;
	defined $head and push @head, $self->elt($head);

	if (defined $script) {
		ref $script eq "ARRAY" or $style = [ $script ];
		foreach my $s (@$script) {
			ref $s eq "HASH" or $s = { -src => $s };
			push @head, [ \"script", { src => $s->{-src} }, $self->literal($s->{-code}) ], "\n";
		}
	}
	if (defined $style) {
		ref $style eq "ARRAY" or $style = [ $style ];
		foreach my $s (@$style) {
			ref $s eq "HASH" or $s = { -src => $s };
			defined $s->{-src} and push @head, [ \"link", { rel => "stylesheet", href => $s->{-src} } ];
			defined $s->{-code} and push @head, [ \"style", $self->literal($s->{-code}) ], "\n";
		}
	}

	defined $noscript and push @head, [ \"noscript", $noscript ];
	my $headstr = $self->elt(\"head", \@head);
	my $other = @other ? " @other" : "";
	_htmlstring($DOCTYPE . "\n"
		. _open_tag(html => { lang => ($lang || "en-US") })
		. "\n"
		. "$headstr"
		. "<body$other>")
}

sub end_html { _htmstring("</body></html>\n") }

sub script_name {
	my $self = shift;
	my $ret = $self->SUPER::script_name(@_);
	if (!defined $ret || $ret eq "") {
		$ret = $0;
		$ret =~ s/.*\///;
	}
	$ret
}

### html helpers

sub join {
	my $self = shift;
	my $separator = shift;
	my @ret = ();
	foreach my $elt (@_) {
		@ret and push @ret, $separator;
		push @ret, $elt;
	}
	\@ret
}

sub style {
	my $self = shift;
	caller eq "CGI" and return $self->SUPER::style(@_);
	my @ret = ();
	while (@_) {
		my $s = shift;
		push @ret, ($s =~ /\n/) ?
			[ \"style", $self->literal($s) ] :
			[ \"link", { rel => "stylesheet", href => $s } ];
	}
	\@ret
}

sub script {
	my $self = shift;
	caller eq "CGI" and return $self->SUPER::script(@_);
	my $type = undef;
	my @ret = ();
	while (@_) {
		my $s = shift;
		if ($s eq "type") {
			$type = shift;
			next;
		} else {
			push @ret, ($s =~ /\n/) ?
				[ \"script", { type => $type }, $self->literal($s) ] :
				[ \"script", { type => $type, src => $s } ];
		}
	}
	\@ret
}

### form values helpers

our %INPUT_TEXT_LIKE = map { $_ => 1 } qw(
	date datetime-local
	email
	month
	number
	search
	tel text time
	url
	week
);

our %INPUT_CHECKABLE = map { $_ => 1 } qw(
	checkbox
	radio
);

sub default {
	my ($self, $default) = @_;
	defined $default or $default = "";
	sub {
		my ($Q) = @_;
		my $elt = $Q->curelt();
		my $attr = $Q->curattr();
		my $ret = undef;
		if ($elt eq "input") {
			my $name = $attr->{name} or croak "<$elt> needs name attribute";
			my $type = $attr->{type};
			defined $type or $type = "text";
			if ($INPUT_TEXT_LIKE{$type}) {
				my $value = $self->_get_value($name, $default, 1);
				$ret = { type => $type, value => $value };
			} elsif ($INPUT_CHECKABLE{$type}) {
				my $value = $attr->{value};
				defined $value or croak "<$elt type=\"$type\"> needs value attribute";
				my $checked = $self->_has_param($name) ?
					$Q->_has_value($name, $value, 1) :
					$value eq $default;
				$ret = {
					checked => ($checked ? "checked" : undef)
				};
			} else {
				croak "value not allowed in <$elt type=\"$type\">";
			}
		} elsif ($elt eq "textarea") {
			my $name = $attr->{name} or croak "<$elt> needs name attribute";
			my $value = $self->_get_value($name, $default, 1);
			$ret = _escape_text($value);
		} elsif ($elt eq "option") {
			my $name = $Q->curattr("select")->{name};
			defined $name or croak "<$elt> needs outer <select> name attribute";
			my $selected = $self->_has_value($name, $default, 1) ? "selected" : undef;
			$ret = { value => $default, selected => $selected };
		} else {
			croak "value not allowed in <$elt>";
		}
		$ret
	}
}

sub reset_form {
	my ($self) = @_;
	my $s = { };
	local $CGI::LIST_CONTEXT_WARN = 0; # more retrocompatible than multi_param()
	foreach my $p ($self->param()) {
		$s->{$p} = [ $self->param($p) ];
	}
	$self->_extra("state", $s);
	$self
}

sub curelt {
	$_[0]->_extra("stack")->[-2 - 2 * ($_[1] || 0)] || ""
}

sub curattr {
	my ($self, $i) = @_;
	$i ||= 0;
	if ($i =~ /^[a-z]/) {
		my $elt = $i;
		$i = 0;
		for (;;) {
			my $e = $self->curelt($i);
			$e or last;
			$e eq $elt and last;
			$i++;
		}
	}
	$self->_extra("stack")->[-1 - 2 * $i] || { }
}

sub _has_param {
	my ($self, $param) = @_;
	my $s = $self->_extra("state");
	defined $s->{$param}
}

sub _has_value {
	my ($self, $param, $value, $remove) = @_;
	my $s = $self->_extra("state");
	my $values = $s->{$param} or return 0;
	my $found = grep { $_ eq $value } @$values;
	if ($found && $remove) {
		my $count = 0;
		@$values = map { $_ eq $value ? ($count++ ? ($_) : ()) : ($_) } @$values;
	};
	return $found;
}

sub _get_value {
	my ($self, $param, $default, $remove) = @_;
	my $s = $self->_extra("state");
	my $values = $s->{$param} or return undef;
	@$values ? ($remove ? shift @$values : $values->[0]) : $default
}

sub _extra {
	my ($self, $name, $value) = @_;
	@_ > 2 ? $self->{$EXTRA}{$name} = $value : $self->{$EXTRA}{$name}
}

### initialization

sub _open_tag($$);

# from https://developer.mozilla.org/en-US/docs/Web/HTML/Element
our @ELEMENTLIST = qw(
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

our %PREFIX = (
	html => "$DOCTYPE\n",
);

our %INNER_PREFIX = (
	head => "\n" . _open_tag("meta", { charset => "utf-8" }) . "\n",
	optgroup => "\n",
	select => "\n",
	table => "\n",
	tbody => "\n",
	thead => "\n",
	tr => "\n",
);

our %SUFFIX = (
	body => "\n",
	div => "\n",
	head => "\n",
	html => "\n",
	link => "\n",
	meta => "\n",
	optgroup => "\n",
	option => "\n",
	p => "\n",
	table => "\n",
	tbody => "\n",
	td => "\n",
	th => "\n",
	thead => "\n",
	title => "\n",
	tr => "\n",
);

our %DEFAULT_ATTR = (
	html => { lang => "en" },
	form => { method => "get", enctype => "multipart/form-data" },
);

our %ELEMENT = ();

sub _empty_element_generator($) {
	my ($elt) = @_;
	my $prefix = $PREFIX{$elt} || "";
	my $suffix = $SUFFIX{$elt} || "";
	sub {
		my $self = shift;
		my $attr = undef;
		while (ref $_[0] eq "HASH") {
			$attr = shift;
		}
		@_ and croak "no content allowed in <$elt>";
		_htmlstring($prefix, _open_tag($elt, $attr), $suffix)
	}
}

sub _element_generator($) {
	my ($elt) = @_;
	my $prefix = $PREFIX{$elt} || "";
	my $inner_prefix = $INNER_PREFIX{$elt} || "";
	my $suffix = $SUFFIX{$elt} || "";
	sub {
		my $self = shift;
		my $attr = { };
		my $open = undef;
		my $close = _close_tag($elt) . $suffix;
		my @ret = ();
		foreach my $c (@_) {
			my $r = ref $c;
			if ($r eq "HASH") {
				$attr = $c;
				$open = undef;
				next;
			}
			$r eq "CGI::HTML5::HTMLString" or croak "unsupported reference to $r";
			$open ||= _open_tag($elt, $attr);
			push @ret, _htmlstring($prefix, $open, $inner_prefix, "$c", $close);
		}
		@ret or push @ret, _htmlstring($prefix, _open_tag($elt, $attr), $inner_prefix, $close);
		wantarray ? @ret : _htmlstring(@ret)
	}
}

foreach my $elt (@ELEMENTLIST) {
	$ELEMENT{$elt} ||= $EMPTY{$elt} ?
		_empty_element_generator($elt) : _element_generator($elt)
}

### main processing

{
	package CGI::HTML5::Guard;
	sub DESTROY { $_[0]->() }
}

sub _guard(&) {
	defined wantarray or die "_guard() in void context";
	bless $_[0], "CGI::HTML5::Guard"
}

sub _push_elt_attr {
	my ($self, $elt, $attr) = @_;
	my $s = $self->_extra("stack");
	push @$s, $elt, $attr;
	_guard { splice @$s, -2 }
}

sub _replace_attr {
	my ($self, $newattr) = @_;
	$self->_extra("stack")->[-1] = $newattr;
}

sub _to_html {
	@_ == 2 or confess "_to_html() called with ", scalar @_, " parameters instead of 2";
	my ($self, $obj) = @_;
	defined $obj or return wantarray ? () : undef;
	my $r = ref $obj;
	$r or return _escape_text($obj);
	$r eq "CGI::HTML5::HTMLString" and return $obj;
	$r eq "ARRAY" or croak "bad _to_html($r) call";

	my $elt = undef;
	my $fun = undef;
	my $attr = undef;
	my @lst = @$obj;
	my @ret = ();
	my $elt_guard = undef;

	if (@lst && ref $lst[0] eq "SCALAR") {
		$elt = ${shift @lst};
		$fun = $ELEMENT{$elt};
		if (ref $fun ne "CODE") {
			$ELEMENT{lc $elt} and croak "\"\Q$elt\E\" must be lower case";
			croak "unknown element <$elt>";
		}
		my $d = $DEFAULT_ATTR{$elt};
		$d and push @ret, $d;
		$elt_guard = $self->_push_elt_attr($elt, $attr = ($d || { }));
	}

	while (@lst) {
		my $c = shift @lst;
		defined $c or next;
		my $r = ref $c;
		if ($r eq "CODE") {
			unshift @lst, ($c->($self));
			next;
		}
		if ($r eq "SCALAR") {
			unshift @lst, $c;
			@lst = $self->_to_html(\@lst);
			next;
		}
		if ($r eq "HASH") {
			$fun or croak "attributes not allowed here";
			$attr = { %$attr, %$c };
			push @ret, $attr;
			$self->_replace_attr($attr);
			next;
		}
		push @ret, $self->_to_html($c);
	}

	$fun and return $fun->($self, @ret);
	_htmlstring(@ret)
}

### tag utilities

sub _open_tag($$) { "<$_[0]" . _attr($_[1]) . ">" }

sub _close_tag($) { "</$_[0]>" }

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
	package CGI::HTML5::HTMLString;
	use overload '""' => sub { ${$_[0]} },
		fallback => 0;
}

sub _htmlstring(@) {
	no warnings "uninitialized";
	bless \(CORE::join "", @_), "CGI::HTML5::HTMLString"
}

sub _escape_text($) {
	my ($s) = @_;
	$s =~ s{([<>&\xa0])}{ $ENT{$1} ||= sprintf("&#x%x;", ord($1)) }ges;
	_htmlstring($s)
}

sub _escape_attr($) {
	my ($s) = @_;
	$s =~ s{([<>&'"\x00-\x1f\xa0])}{ $ENT{$1} ||= sprintf("&#x%x;", ord($1)) }ges;
	$s
}

1;

__END__

=head1 NAME

CGI::HTML5 - CGI.pm HTML5 extension with HTML::Tiny like content generation

=head1 SYNOPSIS

  use CGI::HTML5;

  my $q = CGI::HTML->new();

  # all CGI.pm functions are available
  print $q->header();

  # HTML5 compliant <head> generation
  print $q->start_html(-title => "HTML5 page");

  # tag generation and text escaping
  print $q->elt(\"h1", "Tips & Tricks");
  # <h1>Tips &amp; Tricks</h1>

  # repeated tag generation
  print $q->elt(\"p", "A paragraph", "Another paragraph");
  # <p>A paragraph</p>
  # <p>Another paragraph</p>

  # nested tag generation
  print $q->elt(\"p", [ \"b", "A bold paragraph" ]);
  # <p><b>A bold paragraph</b></p>

  # attributes
  print $q->elt("This is a ", [ \"a", { href => "tgt.html" }, "link" ], ".");
  # This is a <a href="tgt.html">link</a>.

  print $q->end_html();

=head1 DESCRIPTION

CGI::HTML5 design goals are:

=over

=item *
work as a drop-in replacement for CGI.pm;

=item *
generate HTML from data structures, like HTML::Tiny does;

=item *
preserve form values across submits as CGI.pm does;

=item *
produce HTML5 content;

=item *
always use UTF-8;

=item *
handle HTML escaping transparently, while preventing unwanted double
escaping ("&amp;amp;");

=item *
never have to write HTML tags by hand.

=back

CGI::HTML5 tag generation works with lower case tag names and attributes
only.

CGI::HTML5 intentionally lacks XHTML generation capabilities.

=head1 SEE ALSO

L<CGI> - Handle Common Gateway Interface requests and responses

L<HTML::Tiny> - Lightweight, dependency free HTML/XML generation

=head1 AUTHOR

Pietro Cagnoni, E<lt>pietro.cagnoni@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Pietro Cagnoni

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

