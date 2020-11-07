use strict;
use warnings;

use Test::More;
BEGIN { use_ok('CGI::HTML5') };

#########################

use Encode;

use File::Temp qw(tempfile);

use HTTP::Request::Common qw(POST);

my @tst = ("a", "\xe0", "\x{20ac}");

foreach my $fld (map { "PARM-$_" } @tst) {
	foreach my $nam (@tst) {
		foreach my $cnt (@tst) {
			# generating content file
			my ($hf, $nf) = tempfile(encode_utf8("FILE-$nam-XXXXXX"), UNLINK => 1);
			my $filecnt = "$cnt\n";
			utf8::encode($filecnt);
			binmode $hf, ":raw";
			print $hf $filecnt;
			close $hf;

			# generating POST request
			my ($hp, $np) = tempfile("POST-$nam-XXXXXX", UNLINK => 1);
			binmode $hp, ":raw";
			my $post = POST(
				"http://localhost/cgi-html5-test",
				Content_Type => "multipart/form-data",
				Content => [ encode_utf8($fld) => [ $nf ] ]
			)->content();
			print $hp $post;
			seek $hp, 0, 0;

			open STDIN, "<", $np or die "can't redirect: $!";
			local $ENV{REQUEST_METHOD} ="POST";
			local $ENV{CONTENT_TYPE} = 'multipart/form-data; boundary=xYzZY';
			my $Q = CGI::HTML5->new();

			is_deeply([ $Q->param() ], [ $fld ], "param list");
			is($Q->param($fld), $nf, "param value");

			my $h = $Q->param($fld);
			local $/ = undef;
			my $newcnt = <$h>;
			is($newcnt, $filecnt, "file content");
		}
	}
}

done_testing();

