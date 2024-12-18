package CGI::HTML5;

use strict;
use warnings;

use Carp;

use CGI qw(-noxhtml);

our @ISA = qw(CGI);

our $VERSION = '0.01';

our $EXTRA = "{" . __PACKAGE__ . "}";

our $DOCTYPE = "<!DOCTYPE html>";

our $VALID_TAG = qr/^[0-9A-Za-z:\-]+$/;
our $VALID_ATTR = qr/^[^\s<>&'"=\/]+$/;

sub new {
	my $pkg = shift;
	my $new = $pkg->SUPER::new(@_);
	$new->charset("utf8");
	$new->_fix_utf8_params();
	$new->{$EXTRA} = { };
	$new->_extra("stack", [ ]);
	$new->_extra("ascii", 0);
	$new->reset_form();
	return $new;
}

sub clone {
	$_[0]->new($_[0]);
}

sub htmlstring { &hs }

sub hs {
	my $self = shift;
	my $ret = $self->_to_html(\@_);
	$self->ascii() and $ret->to_ascii();
	$ret
}

sub comment {
	my ($self) = shift;
	my $comment = CORE::join("", @_);
	$comment =~ s/-(?=-)/- /g; # double hyphen is not allowed in comments
	_htmlstring("<!-- $comment -->")
}

sub literal {
	my $self = shift;
	_htmlstring(@_)
}

sub open {
	my ($self, $tag, %attr) = @_;
	$tag =~ $VALID_TAG or croak "unallowed tag name '$tag'";
	my $def = $CGI::HTML5::DEFAULT_ATTR{$tag};
	$def and %attr = (%$def, %attr);
	_htmlstring(_open_tag($tag, \%attr))
}

sub close {
	my ($self, $tag) = @_;
	$tag =~ $VALID_TAG or croak "unallowed tag name '$tag'";
	_htmlstring(_close_tag($tag))
}

sub ascii {
       @_ > 1 ?
               $_[0]->_extra("ascii", $_[1]) :
               $_[0]->_extra("ascii")
}

### CGI.pm compatibility

sub query_string {
	my $self = shift;
	$self->_extra("has_upload") or return $self->SUPER::query_string(@_);
	my $ph = $self->_param_hash();
	foreach my $a (sort keys %{$self->_extra("sticky")}) {
		push @{$ph->{".cgifields"}}, $a;
	}
	CGI->new($ph)->query_string()
}

sub start_html {
	my $self = shift;
	my ($title, $author, $base, $xbase, $script, $noscript, $target, $meta, $head, $style, $dtd, $lang, $encoding, $declare_xml, @other) =
		CGI::rearrange([qw(TITLE AUTHOR BASE XBASE SCRIPT NOSCRIPT TARGET META HEAD STYLE DTD LANG ENCODING DECLARE_XML)], @_);
	my @head = ();
	push @head, [ \"meta", { charset => "utf-8" } ];
	ref $meta eq "HASH" and push @head,
		map { [ \"meta", { name => $_, content => $meta->{$_} } ] }
		grep { $_ ne "charset" && defined $meta->{$_} }
		sort keys %$meta;
	defined $title and push @head, [ \"title", $title ];
	if (defined $author) {
		_fix_utf8($author);
		push @head, [ \"link", { rel => "author", href => "mailto:" . _escape_url($author) } ];
	}
	($base || defined $xbase || defined $target)
		and push @head, [ \"base", { href => $xbase || $self->url(-path => 1), target => $target } ];
	defined $head and push @head, $self->hs($head);

	if (defined $script) {
		ref $script eq "ARRAY" or $script = [ $script ];
		foreach my $s (@$script) {
			defined $s or next;
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
	my $headstr = $self->hs(\"head", \@head);
	my $other = @other ? " @other" : "";
	my $ret = $DOCTYPE . "\n"
		. _open_tag(html => { lang => ($lang || "en-US") })
		. "\n"
		. "$headstr"
		. "<body$other>";
	$self->ascii() and _to_ascii($ret);
	$ret
}

sub end_html { "</body></html>\n" }

sub start_form {
	my $self = shift;
	$self->reset_form();
	my $ret = $self->SUPER::start_form(@_);
	$self->ascii() and _to_ascii($ret);
	$ret
}

sub end_form {
	my $self = shift;
	my $ret = $self->SUPER::end_form(@_);
	$self->ascii() and _to_ascii($ret);
	$ret
}

sub start_multipart_form {
	my $self = shift;
	$self->reset_form();
	my $ret = $self->SUPER::start_multipart_form(@_);
	$self->ascii() and _to_ascii($ret);
	$ret
}

sub end_multipart_form {
	my $self = shift;
	my $ret = $self->SUPER::end_multipart_form(@_);
	$self->ascii() and _to_ascii($ret);
	$ret
}

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
	hidden
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

sub sticky {
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
				my $checked = $self->_has_param($name) || $self->_has_sticky($name) ?
					$Q->_has_value($name, $value, 1) :
					$value eq $default;
				$ret = { checked => ($checked ? \1 : \0) };
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
			my $value = $attr->{value};
			defined $value or croak "<$elt> needs value attribute";
			my $selected = $self->_has_param($name) || $self->_has_sticky($name) ?
				$Q->_has_value($name, $value, 1) :
				$value eq $default;
			$ret = { selected => ($selected ? \1 : \0) };
		} else {
			croak "value not allowed in <$elt>";
		}
		$ret
	}
}

sub reset_form {
	my ($self) = @_;
	$self->_extra("state", $self->_param_hash());
	$self->_extra("sticky", { });
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

sub _param_hash {
	my ($self) = @_;
	local $CGI::LIST_CONTEXT_WARN = 0; # more retrocompatible than multi_param()
	my %s = ();
	my $has_upload = 0;
	foreach my $p ($self->param()) {
		my @v = $self->param($p);
		foreach (@v) {
			ref $_ or next;
			$_ = "$_";
			_fix_utf8($_);
			$has_upload++;
		}
		$s{$p} = \@v;
	}
	$self->_extra("has_upload", $has_upload);
	\%s
}

sub _has_param {
	my ($self, $name) = @_;
	my $s = $self->_extra("state");
	defined $name or return scalar %$s;
	defined $s->{$name}
}

sub _has_sticky {
	my ($self, $name) = @_;
	my $f = $self->{".fieldnames"};
	ref $f eq "HASH" && $f->{$name} ? 1 : 0
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
	my $values = $s->{$param} or return $default;
	@$values ? ($remove ? shift @$values : $values->[0]) : $default
}

sub _extra {
	my ($self, $name, $value) = @_;
	@_ > 2 ? $self->{$EXTRA}{$name} = $value : $self->{$EXTRA}{$name}
}

### initialization

sub _open_tag($$);

# from https://developer.mozilla.org/en-US/docs/Web/HTML/Element
our @ELEMENTS = qw(
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
	s samp script section select slot small source span strong style sub summary sup svg
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

our %OUTER_PREFIX = (
	form => \&_form_prefix,
	html => "$DOCTYPE\n",
);

our %INNER_PREFIX = (
	head => "\n",
	ol => "\n",
	optgroup => "\n",
	select => "\n",
	table => "\n",
	tbody => "\n",
	thead => "\n",
	tr => "\n",
	ul => "\n",
);

our %INNER_SUFFIX = (
	form => \&_form_inner_suffix,
);

our %OUTER_SUFFIX = (
	base => "\n",
	body => "\n",
	div => "\n",
	h1 => "\n",
	h2 => "\n",
	h3 => "\n",
	h4 => "\n",
	h5 => "\n",
	h6 => "\n",
	head => "\n",
	html => "\n",
	input => \&_sticky_suffix,
	li => "\n",
	link => "\n",
	meta => "\n",
	ol => "\n",
	optgroup => "\n",
	option => "\n",
	p => "\n",
	select => \&_sticky_suffix,
	table => "\n",
	tbody => "\n",
	td => "\n",
	th => "\n",
	thead => "\n",
	title => "\n",
	tr => "\n",
	ul => "\n",
);

sub _sticky_suffix {
	my ($self) = @_;
	my $elt = $self->curelt();
	my $attr = $self->curattr();
	my $name = $attr->{name};
	defined $name or return "";
	my $sticky = undef;
	if ($elt eq "select" && _bool($attr->{multiple})) {
		$sticky = $name;
	} elsif ($elt eq "input") {
		my $type = $attr->{type} || "";
		$type eq "checkbox" || $type eq "radio"
			and $sticky = $name;
	}
	defined $sticky and $self->register_parameter($sticky);
	""
}

sub _form_prefix {
	my ($self) = @_;
	$self->{'.parametersToAdd'} = { };
	""
}

sub _form_inner_suffix {
	my ($self) = @_;
	my @cgifields = sort keys %{$self->{'.parametersToAdd'} || { }};
	if (@cgifields) {
		return "<div>"
			. CORE::join("", map {
					_open_tag("input", { type => "hidden", name => ".cgifields", value => $_ })
				} @cgifields)
			. "</div>"
	}
	""
}

sub _bool($) {
	my ($v) = @_;
	UNIVERSAL::isa($v, "SCALAR") ? $$v : $v
}

sub _iscode($) {
	UNIVERSAL::isa($_[0], "CODE")
}

our %DEFAULT_ATTR = (
	form => { method => "get", enctype => "multipart/form-data" },
	html => { lang => "en" },
	input => { type => "text" },
);

our %ELEMENT = ();

sub _cb {
	my ($self, $thingy) = @_;
	_iscode($thingy) ? $thingy->($self): $thingy
}

sub _empty_element_generator($) {
	my ($elt) = @_;
	my $outer_prefix = $OUTER_PREFIX{$elt} || "";
	my $outer_suffix = $OUTER_SUFFIX{$elt} || "";
	sub {
		my $self = shift;
		my $flags = shift;
		my $attr = undef;
		while (ref $_[0] eq "HASH") {
			$attr = shift;
		}
		$flags and croak "flag '$flags' not allowed for <$elt>";
		@_ and croak "no content allowed in <$elt>";
		_htmlstring($self->_cb($outer_prefix), _open_tag($elt, $attr),
			$self->_cb($outer_suffix))
	}
}

sub _element_generator($) {
	my ($elt) = @_;
	my $outer_prefix = $OUTER_PREFIX{$elt} || "";
	my $inner_prefix = $INNER_PREFIX{$elt} || "";
	my $inner_suffix = $INNER_SUFFIX{$elt} || "";
	my $outer_suffix = $OUTER_SUFFIX{$elt} || "";
	sub {
		my $self = shift;
		my $flags = shift;
		my $attr = { };
		my $close = _close_tag($elt);
		my @ret = ();
		if ($flags =~ /\*/) {
			my $open = undef;
			foreach my $c (@_) {
				my $r = ref $c;
				if ($r eq "HASH") {
					$attr = $c;
					$open = undef;
					next;
				}
				$r eq "CGI::HTML5::HTMLString" or croak "unsupported reference to $r";
				$open ||= _open_tag($elt, $attr);
				push @ret, $self->_cb($outer_prefix) . $open . $self->_cb($inner_prefix) . "$c"
					. $self->_cb($inner_suffix) . $close
					. $self->_cb($outer_suffix);
			}
			return wantarray ? map { _htmlstring($_) } @ret : _htmlstring(@ret)
		} else {
			push @ret, $self->_cb($outer_prefix), undef, $self->_cb($inner_prefix);
			foreach my $c (@_) {
				my $r = ref $c;
				if ($r eq "HASH") {
					$attr = $c;
					next;
				}
				$r eq "CGI::HTML5::HTMLString" or croak "unsupported reference to $r";
				push @ret, "$c";
			}
			push @ret, $self->_cb($inner_suffix), $close, $self->_cb($outer_suffix);
			$ret[1] = _open_tag($elt, $attr);
			return _htmlstring(@ret)
		}
	}
}

foreach my $elt (@ELEMENTS) {
	$ELEMENT{$elt} ||= $EMPTY{$elt} ?
		_empty_element_generator($elt) :
		_element_generator($elt)
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
	my $flags = "";
	my $attr = undef;
	my @lst = @$obj;
	my @ret = ();
	my $elt_guard = undef;

	if (@lst && ref $lst[0] eq "SCALAR") {
		$elt = ${shift @lst};
		$elt =~ s/([*]+)$// and $flags = $1;
		$fun = $ELEMENT{$elt};
		if (!_iscode($fun)) {
			$ELEMENT{lc $elt} and croak "'$elt' must be lower case";
			croak "unknown element <$elt>";
		}
		my $d = $DEFAULT_ATTR{$elt};
		$d and push @ret, $d;
		$elt_guard = $self->_push_elt_attr($elt, $attr = ($d || { }));
	}

	while (@lst) {
		my $c = shift @lst;
		defined $c or next;
		if (_iscode($c)) {
			unshift @lst, ($c->($self));
			next;
		}
		my $r = ref $c;
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

	$fun and return $fun->($self, $flags, @ret);
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
		my $v = $a->{$n};
		defined $v or next;
		$n =~ $VALID_ATTR or croak "unallowed attribute name '$n'";
		if (ref $v eq "SCALAR") {
			_bool($v) and $ret .= " $n";
		} else {
			$ret .= " $n=\"" . _escape_attr($v) . "\"";
		}
	}
	$ret
}

### upload filename UTF-8 wrapper

{
	package CGI::File::Temp; # keep @ISA happy with old CGI.pm

	package CGI::HTML5::Fh;
	our @ISA = qw(CGI::File::Temp Fh);

	use overload '""' => \&asString;

	sub rebless {
		my $fh = pop;
		defined $fh
			and grep { ref $fh eq $_ } @ISA
			or return undef;
		$fh->asString(); # force autoload if needed
		bless $fh, __PACKAGE__
	}

	sub asString {
		my ($self) = shift;
		my $s = $self->SUPER::asString(@_);
		CGI::HTML5::_fix_utf8($s);
		$s
	}
}

### escaping utilities

{
	package CGI::HTML5::HTMLString;
	use overload fallback => 0,
		'""' => \&string,
		'bool' => \&string,
		'!' => sub { !$_[0]->string() },
		'.' => sub {
			my ($self, $other, $swap) = @_;
			ref $other eq __PACKAGE__ or $other = CGI::HTML5::_escape_text($other);
			CGI::HTML5::_htmlstring($swap ? ($$other, $$self) : ($$self, $$other))
		},
		'.=' => sub {
			my ($self, $other) = @_;
			ref $other eq __PACKAGE__ or $other = CGI::HTML5::_escape_text($other);
			$$self .= $$other;
			$self
		};

	sub to_ascii($) {
		goto &CGI::HTML5::_to_ascii
	}

	sub string { ${$_[0]} }
}

sub _htmlstring(@) {
	no warnings "uninitialized";
	bless \CORE::join("", @_), "CGI::HTML5::HTMLString"
}

our %ENT = (
	"<" => "&lt;",
	">" => "&gt;",
	"&" => "&amp;",
	"\"" => "&quot;",
	"\xa0" => "&nbsp;",
);

sub _escape_text($) {
	my ($s) = @_;
	$s =~ s{([<>&\xa0])}{ $ENT{$1} || sprintf("&#x%x;", ord($1)) }ges;
	_htmlstring($s)
}

sub _escape_attr($) {
	my ($s) = @_;
	$s =~ s{([<>&'"\x00-\x1f\xa0])}{ $ENT{$1} || sprintf("&#x%x;", ord($1)) }ges;
	$s
}

our %ESC = (" " => "+");

sub _escape_url($) {
	my ($s) = @_;
	_fix_utf8($s);
	utf8::encode($s);
	$s =~ s{([^0-9A-Za-z_.~\-])}{ $ESC{$1} ||= sprintf "%%%02x", ord($1) }ges;
	$s
}

sub _fix_utf8_params {
	my ($self) = @_;

	$self->path_info();
	_fix_utf8($self->{".path_info"});

	my $param = $self->{param} || $self;
	foreach (@{$self->{".parameters"} || [ ]}) {
		my $o = $_;
		_fix_utf8($_, @{$param->{$o}});
		$_ eq $o or $param->{$_} = delete $param->{$o};
	}
}

sub _fix_utf8 {
	foreach (@_) {
		defined $_ or next;
		ref $_ and CGI::HTML5::Fh::rebless($_), next;
		utf8::is_utf8($_) || utf8::decode($_) || utf8::upgrade($_);
	}
}

sub _to_ascii($) {
	$_[0] =~ s{([\x{80}-\x{10ffff}])}{ sprintf("&#x%x;", ord($1)) }ges;
}

### build CGI::HTML5 structure from HTML

sub _tree_to_struct($);
sub _update_tagset();
sub _convert_new_cdata_tags($);

sub parse_html {
	my $self = shift;

	_update_tagset();
	require HTML::TreeBuilder;
	my $tree = HTML::TreeBuilder->new();
	$tree->warn(1);
	foreach my $html (@_) {
		_fix_utf8($html);
		$html = _convert_new_cdata_tags($html);
		$tree->parse($html);
	}
	$tree->eof();

	my @ret = ();
	push @ret, _tree_to_struct($_) foreach $tree->guts;
	$tree->delete();
	@ret == 1 ? $ret[0] : \@ret
}

# CDATA HTML5 tags HTML::Parser doesn't know about
our %NEW_CDATA = map { $_ => 1 } qw(svg);
our $NEW_CDATA_REPLACER = "xmp";
our $NEW_CDATA_NAME_ATTR = "$NEW_CDATA_REPLACER-stands-for";

sub _tree_to_struct($) {
	my ($e) = @_;
	ref $e or return $e;
	$e->isa("HTML::Element") or croak "convert() can't handle ", ref($e), "\n";

	my @ret = ();
	my $tag = $e->tag;
	my %attr = $e->all_external_attr;
	delete $attr{"/"};

	if ($tag eq $NEW_CDATA_REPLACER && exists $attr{$NEW_CDATA_NAME_ATTR}) {
		$tag = delete $attr{$NEW_CDATA_NAME_ATTR};
	}

	foreach (keys %attr) {
		$attr{$_} eq $_ and $attr{$_} = \(my $o = 1);
	}

	push @ret, \$tag;
	push @ret, \%attr;

	push @ret, _tree_to_struct($_) foreach $e->content_list;

	\@ret
}

our $_update_tagset_done = 0;

sub _update_tagset() {
	$_update_tagset_done and return 0;
	require HTML::Tagset;
	foreach my $tag (@ELEMENTS) {
		$HTML::Tagset::isKnown{$tag} and next;
		my $empty = $EMPTY{$tag};
		# warn __PACKAGE__, ": adding \U$tag\E", ($empty ? " empty" : ""), " tag to HTML::Tagset\n";
		$HTML::Tagset::isKnown{$tag} = 1;
		$HTML::Tagset::isBodyElement{$tag} = 1;
		if ($empty) {
			$HTML::Tagset::emptyElement{$tag} = 1;
		} else {
			$HTML::Tagset::canTighten{$tag} = 1;
		}
	}
	$HTML::Tagset::isCDATA_Parent{svg} = 1;
	$_update_tagset_done = 1
}

sub _convert_new_cdata_tags($) {
	my ($html) = @_;
	_fix_utf8($html);
	require HTML::Parser;
	my $ret = "";
	my $p = HTML::Parser->new(
		default_h => [ sub { $ret .= $_[0] }, "text" ],
		start_h => [ sub {
				my ($tag, $attr, $text) = @_;
				if ($NEW_CDATA{$tag}) {
					$text = _open_tag($NEW_CDATA_REPLACER,
						{ %$attr, $NEW_CDATA_NAME_ATTR => $tag });
				}
				$ret .= $text;
			}, "tagname,attr,text" ],
		end_h => [ sub {
				my ($tag, $text) = @_;
				if ($NEW_CDATA{$tag}) {
					$text = _close_tag($NEW_CDATA_REPLACER);
				}
				$ret .= $text;
			}, "tagname,text" ],
	);
	$p->parse($html);
	$p->eof;
	$ret
}

1;

__END__

=head1 NAME

CGI::HTML5 - CGI.pm HTML5 extension

=head1 SYNOPSIS

  use CGI::HTML5;

  my $q = CGI::HTML->new();

  # all CGI.pm functions are available
  print $q->header();

  # HTML5 compliant <head> generation
  print $q->start_html(-title => "HTML5 page");

  # tag generation and text escaping
  print $q->hs(\"h1", "Tips & Tricks");
  # <h1>Tips &amp; Tricks</h1>

  # repeated tag generation
  print $q->hs(\"p*", "A paragraph.", "Another paragraph.");
  # <p>A paragraph.</p>
  # <p>Another paragraph.</p>

  # disable repeated tag generation
  print $q->hs(\"p*", [ "A paragraph.", "The same paragraph." ]);
  # <p>A paragraph.The same paragraph.</p>

  # nested tag generation
  print $q->hs(\"p", [ \"b", "A bold paragraph" ]);
  # <p><b>A bold paragraph</b></p>

  # attributes
  print $q->hs("This is a ", [ \"a", { href => "tgt.cgi?a=1&b=2" }, "link" ], ".");
  # This is a <a href="tgt.cgi?a=1&amp;b=2">link</a>.

  # low level tag generation
  print $q->open("a", href => "index.html");
  # <a href="index.html">
  print $q->close("a");
  # </a>

  print $q->end_html();

=head1 DESCRIPTION

CGI::HTML5 brings good old CGI.pm into the new HTML5 world.

=head1 Design goals

=over

=item *
produce HTML5 content;

=item *
easy migration from CGI.pm;

=item *
generate HTML from data structures;

=item *
support sticky forms;

=item *
handle HTML escaping transparently, while preventing unwanted double
escaping ("&amp;amp;");

=item *
always use UTF-8;

=item *
no need to write HTML tags by hand.

=back

=head1 NOTES

CGI::HTML5 tag generation works with lower case tag names and attributes
only.

CGI::HTML5 intentionally lacks XHTML generation capabilities.

=head1 SEE ALSO

L<CGI> - Handle Common Gateway Interface requests and responses

L<HTML::Tiny> - Lightweight, dependency free HTML/XML generation

=head1 AUTHOR

peteletroll

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by peteletroll

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

