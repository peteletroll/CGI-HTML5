package CGI::HTML5;

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
	$new->{+__PACKAGE__} = { };
	$new->_extra("stack", [ ]);
	$new->reset_form();
	return $new;
}

sub clone($) {
	$_[0]->new($_[0]);
}

sub elt($@) {
	my $self = shift;
	scalar $self->_to_html(\@_)
}

sub literal($@) {
	my $self = shift;
	_escaped(@_)
}

### form helpers

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

sub value($$) {
	my ($self, $default) = @_;
	defined $default or $default = "";
	sub {
		my ($Q) = @_;
		my $elt = $Q->curelt();
		my $attr = $Q->curattr();
		my $ret = undef;
		my $name = $attr->{name} or croak "<$elt> needs name attribute";
		if ($elt eq "input") {
			my $type = $attr->{type};
			defined $type or $type = "text";
			if ($INPUT_TEXT_LIKE{$type}) {
				my $value = $self->_get_value($name, $default, 1);
				$ret = { type => $type, value => $value };
			} elsif ($INPUT_CHECKABLE{$type}) {
				$ret = {
					value => $default,
					checked => ($Q->_has_value($name, $default, 1) ? "checked" : undef)
				};
			} else {
				croak "value not allowed in <$elt type=\"$type\">";
			}
		} elsif ($elt eq "textarea") {
			my $value = $self->_get_value($name, $default, 1);
			return _escape_text($value);
		} else {
			croak "value not allowed in <$elt>";
		}
		$ret
	}
}

sub options($@) {
	my $self = shift;
	my %label = ();
	my @lst = ();
	foreach my $c (@_) {
		defined $c or next;
		my $r = ref $c;
		if (!$r || $r eq "ARRAY") {
			push @lst, $c;
		} elsif ($r eq "HASH") {
			%label = (%label, %$c);
		} else {
			croak "$r not allowed in options";
		}
	}
	sub {
		my ($Q) = @_;
		my $elt = $Q->curelt();
		my $attr = $Q->curattr();
		my @option = ();
		my $optgroup = "";
		if ($elt eq "select" || $elt eq "datalist") {
			my $name = $attr->{name} or croak "<$elt> needs name attribute";
			foreach my $c (@lst) {
				my $r = ref $c;
				if (!$r) {
					$elt eq "select" or croak "<optgroup> not allowed in <$elt>";
					$optgroup = $c;
				} elsif ($r eq "ARRAY") {
					my $o = [ $self->_options_aux($name, $c, \%label) ];
					if ($optgroup ne "") {
						$o = [ \"optgroup", { label => $optgroup }, $o ];
					}
					push @option, $o;
				} else {
					croak "$r not allowed in options";
				}
			}
		} else {
			croak "options not allowed in <$elt>";
		}
		\@option
	}
}

sub _options_aux($$$) {
	my ($self, $name, $lst, $lbl) = @_;
	my @ret = ();
	foreach my $value (@$lst) {
		my $label = $lbl->{$value};
		defined $label or $label = $value;
		my $selected = $self->_has_value($name, $value, 1) ? "selected" : undef;
		push @ret, [ \"option", { value => $value, selected => $selected }, $label ];
	}
	@ret
}

sub reset_form($) {
	my ($self) = @_;
	my $s = { };
	local $CGI::LIST_CONTEXT_WARN = 0; # more retrocompatible than multi_param()
	foreach my $p ($self->param()) {
		$s->{$p} = [ $self->param($p) ];
	}
	$self->_extra("state", $s);
	$self
}

sub curelt($;$) {
	$_[0]->_extra("stack")->[-2 - 2 * ($_[1] || 0)] || ""
}

sub curattr($;$) {
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

sub _has_param($$) {
	my ($self, $param) = @_;
	my $s = $self->_extra("state");
	exists $s->{$param}
}

sub _has_value($$$;$) {
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

sub _get_value($$;$$) {
	my ($self, $param, $default, $remove) = @_;
	my $s = $self->_extra("state");
	my $values = $s->{$param} or return undef;
	@$values ? ($remove ? shift @$values : $values->[0]) : $default
}

sub _extra($$;$) {
	my ($self, $name, $value) = @_;
	@_ > 2 ? $self->{+__PACKAGE__}{$name} = $value : $self->{+__PACKAGE__}{$name}
}

### initialization

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

our %NEWLINE = map { $_ => 1 } qw(
	body
	div
	head html
	option optgroup
	p
	table tr
);

our %ELEMENT = ();

foreach my $elt (@ELEMENTLIST) {
	my $nl = $NEWLINE{$elt} ? "\n" : "";
	$ELEMENT{$elt} = $EMPTY{$elt} ?
		sub {
			my $self = shift;
			my $attr = undef;
			while (ref $_[0] eq "HASH") {
				$attr = shift;
			}
			@_ and croak "no content allowed in <$elt>";
			_escaped(_open_tag($elt, $attr), $nl)
		} :
		sub {
			my $self = shift;
			my $attr = { };
			my $open = undef;
			my $close = _close_tag($elt) . $nl;
			my @ret = ();
			foreach my $c (@_) {
				my $r = ref $c;
				if ($r eq "HASH") {
					$attr = $c;
					$open = undef;
					next;
				}
				$r eq "CGI::HTML5::EscapedString" or croak "unsupported reference to $r";
				$open ||= _open_tag($elt, $attr);
				push @ret, _escaped($open . "$c" . $close);
			}
			@ret or push @ret, _open_tag($elt, $attr), $close;
			wantarray ? @ret : _escaped(@ret)
		};
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

sub _push_elt_attr($@) {
	my ($self, $elt, $attr) = @_;
	my $s = $self->_extra("stack");
	push @$s, $elt, $attr;
	_guard { splice @$s, -2 }
}

sub _replace_attr($$) {
	my ($self, $newattr) = @_;
	$self->_extra("stack")->[-1] = $newattr;
}

sub _to_html($$) {
	@_ == 2 or confess "_to_html() called with ", scalar @_, " parameters instead of 2";
	my ($self, $obj) = @_;
	defined $obj or return wantarray ? () : undef;
	my $r = ref $obj;
	$r or return _escape_text($obj);
	$r eq "CGI::HTML5::EscapedString" and return $obj;
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
		$elt_guard = $self->_push_elt_attr($elt, $attr = { });
		ref $fun eq "CODE" or croak "unknown element <$elt>";
	}

	while (@lst) {
		my $c = shift @lst;
		defined $c or next;
		my $r = ref $c;
		if ($r eq "CODE") {
			unshift @lst, ($c->($self));
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
	_escaped(@ret)
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
	package CGI::HTML5::EscapedString;
	use overload '""' => sub { ${$_[0]} },
		fallback => 0;
}

sub _escaped(@) {
	bless \(join "", @_), "CGI::HTML5::EscapedString"
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

=head1 NAME

CGI::HTML5 - CGI module extension to create HTML5 pages

=head1 SYNOPSIS

  use CGI::HTML5;

=head1 DESCRIPTION

CGI module extension to create HTML5 pages.

=head1 SEE ALSO

L<CGI> - Handle Common Gateway Interface requests and responses

=head1 AUTHOR

Pietro Cagnoni, E<lt>pietro.cagnoni@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Pietro Cagnoni

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

