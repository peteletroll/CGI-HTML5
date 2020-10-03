package CGI::HTML;

use 5.028001;
use strict;
use warnings;

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

### attribute utilities

sub attr($) {
	my ($a) = @_;
	my $ret = "";
	foreach my $n (sort keys %$a) {
		my $v = $a->{$n};
		defined $v or next;
		$n =~ /[\s<>&'"=\/]/ and die "unsafe attribute name '$n'";
		$ret .= " $n";
		$ret .= "=\"" . escape_attr($v) . "\"" if $v ne $n;
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

sub escaped($) {
	my ($s) = shift;
	utf8::upgrade($s);
	bless \$s, "CGI::HTML::EscapedString";
}

sub escape_text($) {
	my ($s) = @_;
	$s =~ s{([<>&])}{ $ENT{$1} ||= sprintf("&#x%x;", ord($1)) }ges;
	escaped $s
}

sub escape_attr($) {
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
