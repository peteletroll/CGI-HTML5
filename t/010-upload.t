use strict;
use warnings;

use Test::More;
BEGIN { use_ok('CGI::HTML5') };

#########################

use Encode;

use File::Temp qw(tempfile);

use HTTP::Request::Common qw(POST);

my @tst = ("a", "\xe0", "\x{20ac}");
# @tst = ("\xe0", "\x{20ac}");

utf8::upgrade($_) foreach @tst;

my $boundary = "CGI-HTML5-TEST-BOUNDARY";

binmode STDOUT, ":raw";

sub _escape($) {
	my ($s) = @_;
	utf8::upgrade($s);
	utf8::encode($s);
	$s = CGI::escape($s);
	$s
}

close STDIN or die "can't close STDIN: $!";

local $| = 1;

foreach my $cnt (@tst) {
	# generating content file
	my ($hf, $nf) = tempfile(encode_utf8("FILE-cnt-$cnt-XXXXXX"), UNLINK => 1);
	binmode $hf, ":raw";
	my $cnt_bytes = encode_utf8("CONT-$cnt\n");
	print $hf "$cnt_bytes";
	close $hf;

	foreach my $nam (@tst) {
		foreach my $val (@tst) {
			my $lbl = encode_utf8("nam=$nam val=$val cnt=$cnt");
			# print "\nLABEL ", $lbl, "\n";

			# generating POST request
			my ($hp, $np) = tempfile(encode_utf8("POST-nam=$nam-val=$val-cnt=$cnt-XXXXXX"), UNLINK => 1);
			binmode $hp, ":raw";
			my $content_type = "multipart/form-data; boundary=$boundary";
			my $post = POST("http://localhost/cgi-html5-test",
				Content_Type => $content_type,
				Content => [ encode_utf8($nam) => [ $nf ] ]
			)->content();
			# print "-" x 20, "\n", $post, "-" x 20, "\n";
			print $hp $post;
			close $hp;

			my $Q = do {
				local %ENV = (
					GATEWAY_INTERFACE => "CGI/1.1",
					REQUEST_METHOD => "POST",
					CONTENT_TYPE => $content_type,
				);
				open STDIN, "<:raw", $np or die "can't redirect STDIN: $!";
				CGI::initialize_globals();
				my $Q = CGI::HTML5->new();
				close STDIN or die "can't close STDIN: $!";
				$Q
			};

			is($Q->query_string(), _escape($nam) . "=" . _escape(decode_utf8($nf)), "query string - $lbl");
			is_deeply([ $Q->param() ], [ $nam ], "param list - $lbl");
			is($Q->param($nam), $nf, "param value - $lbl");

			my $h = $Q->param($nam);
			local $/ = undef;
			my $newcnt = <$h>;
			is($newcnt, $cnt_bytes, "file content - $lbl");
		}
	}
}

done_testing();

