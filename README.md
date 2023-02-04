# NAME

CGI::HTML5 - CGI.pm HTML5 extension

# SYNOPSIS

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

# DESCRIPTION

CGI::HTML5 brings good old CGI.pm into the new HTML5 world.

# Design goals

- produce HTML5 content;
- easy migration from CGI.pm;
- generate HTML from data structures;
- support sticky forms;
- handle HTML escaping transparently, while preventing unwanted double
escaping ("&amp;amp;amp;");
- always use UTF-8;
- no need to write HTML tags by hand.

# NOTES

CGI::HTML5 tag generation works with lower case tag names and attributes
only.

CGI::HTML5 intentionally lacks XHTML generation capabilities.

# SEE ALSO

[CGI](https://metacpan.org/pod/CGI) - Handle Common Gateway Interface requests and responses

[HTML::Tiny](https://metacpan.org/pod/HTML%3A%3ATiny) - Lightweight, dependency free HTML/XML generation

# AUTHOR

Pietro Cagnoni, <pietro.cagnoni@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2020 by Pietro Cagnoni

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.
