use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'CGI::HTML5',
    VERSION_FROM      => 'lib/CGI/HTML5.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { CGI => 0 }, # e.g., Module::Name => 1.1
    BUILD_REQUIRES    => { Pod::Markdown => 0 }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/CGI/HTML5.pm', # retrieve abstract from module
    AUTHOR            => 'peteletroll',
    LICENSE           => 'perl',
    EXE_FILES         => [ 'bin/html-to-CGI-HTML5' ],
);

sub MY::postamble {
	return <<'END'

all:: README.md

README.md: lib/CGI/HTML5.pm
	pod2markdown $^ > $@

END
}

