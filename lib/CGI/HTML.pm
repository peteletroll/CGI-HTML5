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
	return $new;
}

sub clone($) {
	$_[0]->new($_[0]);
}

sub tag($@) {
	my $self = shift;
	$self->_process(\@_)
}

sub literal($@) {
	my $self = shift;
	_escaped(join("", @_))
}

### initialization

# from https://developer.mozilla.org/en-US/docs/Web/HTML/Element
my @TAG = qw(
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
my %EMPTY = map { $_ => 1 } qw(
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

my %NEWLINE = map { $_ => 1 } qw(
	body
	div
	head html
	p
	table tr
);

foreach my $tag (@TAG) {
	my $fname = "tag_$tag";
	my $nl = $NEWLINE{$tag} ? "\n" : "";
	$CGI::HTML::{$fname} and next;
	if ($EMPTY{$tag}) {
		$CGI::HTML::{$fname} = sub {
			my $self = shift;
			my $attr = (ref $_[0] eq "HASH" ? shift : undef);
			@_ and croak "no content allowed in <$tag>";
			_escaped(_open_tag($tag, $attr) . $nl)
		};
	} else {
		$CGI::HTML::{$fname} = sub {
			# warn "CONTENT '$tag'\n";
			my $self = shift;
			my %attr = ();
			my $open = undef;
			my $close = _escaped(_close_tag($tag) . $nl);
			my @ret = ();
			foreach (@_) {
				my $c = $_;
				# warn "ELEM '$c'\n";
				my $r = ref $c;
				if (!$r) {
					$c = _escape_text($c);
				} elsif ($r eq "CGI::HTML::EscapedString") {
					# nothing
				} elsif ($r eq "HASH") {
					%attr = (%attr, %$c);
					$open = undef;
					next;
				} elsif ($r eq "ARRAY") {
					$c = $self->_process($c);
				} else {
					croak "unsupported reference to $r";
				}
				$open ||= _open_tag($tag, \%attr);
				push @ret, $open, $c, $close;
			}
			@ret or push @ret, _open_tag($tag, \%attr), $close;
			_escaped(join("", @ret))
		};
	}
}

### main processing

sub _process($$) {
	my ($self, $lst) = @_;
	my @ret = ();
	if (@$lst > 0 && ref $lst->[0] eq "SCALAR") {
		my @lst = @$lst;
		my $tag = ${shift @lst};
		my $fname = "tag_$tag";
		my $f = $CGI::HTML::{$fname};
		ref $f eq "CODE" or croak "unknown tag <$tag>";
		push @ret, $f->($self, @lst);
	} else {
		foreach my $c (@$lst) {
			my $r = ref $c;
			if (!$r) {
				push @ret, _escape_text($c);
			} elsif ($r eq "CGI::HTML::EscapedString") {
				push @ret, $c;
			} elsif ($r eq "ARRAY") {
				push @ret, $self->_process($c);
			} else {
				croak "unsupported reference to $r";
			}
		}
	}
	join("", @ret);
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

sub _attr($) {
	my ($a) = @_;
	$a or return "";
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
	"\xa0" => "&nbsp;",
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
	$s =~ s{([<>&\xa0])}{ $ENT{$1} ||= sprintf("&#x%x;", ord($1)) }ges;
	_escaped $s
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
