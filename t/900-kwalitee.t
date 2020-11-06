use strict;
use warnings;

use Test::More;

BEGIN {
	plan skip_all => 'set RELEASE_TESTING=1 for Kwalitee tests'
		unless $ENV{RELEASE_TESTING};
}

use Test::Kwalitee qw(kwalitee_ok);
kwalitee_ok();
done_testing();

