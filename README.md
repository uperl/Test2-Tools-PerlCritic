# Test2::Tools::PerlCritic [![Build Status](https://secure.travis-ci.org/plicease/Test2-Tools-PerlCritic.png)](http://travis-ci.org/plicease/Test2-Tools-PerlCritic)

Testing tools to enforce Perl::Critic policies

# SYNOPSIS

```perl
use Test2::V0;
use Test2::Tools::PerlCritic;

perl_critic_ok 'lib', 'test library files';
perl_critic_ok 't',   'test test files';

done_testing;
```

# DESCRIPTION

Test for [Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic) violations using [Test2](https://metacpan.org/pod/Test2).  Although this testing tool
uses the [Test2](https://metacpan.org/pod/Test2) API instead of the older [Test::Builder](https://metacpan.org/pod/Test%3A%3ABuilder) API, the primary
motivation is to provide output in a more useful form.  That is policy violations
are grouped by policy class, and the policy class name is clearly displayed as
a diagnostic.  The author finds the former more useful because he tends to address
one type of violation at a time.  The author finds the latter more useful because
he tends to want to lookup or adjust the configuration of the policy as he is
addressing violations.

# FUNCTIONS

## perl\_critic\_ok

```
perl_critic_ok $file_or_directory, \@options, $test_name;
perl_critic_ok $file_or_directory, \%options, $test_name;
perl_critic_ok $file_or_directory, $critic, $test_name;
perl_critic_ok $file_or_directory, $test_name;
perl_critic_ok $file_or_directory;
```

Run [Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic) on the given file or directory.  If `\@options` or
`\%options` are provided, then they will be passed into the
[Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic) constructor.  If `$critic` (an instance of [Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic))
is provided, then that [Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic) instance will be used instead
of creating one internally.  Finally the `$test_name` may be provided
if you do not like the default test name.

Only a single test is run regardless of how many files are processed.
this is so that the policy violations can be grouped by policy class
across multiple files.

As a convenience, if the test passes then a true value is returned.
Otherwise a false will be returned.

`done_testing` or the equivalent is NOT called by this function.
You are responsible for calling that yourself.

# CAVEATS

[Test::Perl::Critic](https://metacpan.org/pod/Test%3A%3APerl%3A%3ACritic) has been around longer, and probably does at least some things smarter.
The fact that this module groups policy violations for all files by class means that it has
to store more diagnostics in memory before sending them out _en masse_, where as
[Test::Perl::Critic](https://metacpan.org/pod/Test%3A%3APerl%3A%3ACritic) sends violations for each file as it processes them.  [Test::Perl::Critic](https://metacpan.org/pod/Test%3A%3APerl%3A%3ACritic)
also comes with some code to optionally do processing in parallel.  Some of these issues may
or may not be addressed in future versions of this module.

Since this module formats it's output the `-verbose` option is ignored at the `set_format`
value is ignored.

# SEE ALSO

- [Test::Perl::Critic](https://metacpan.org/pod/Test%3A%3APerl%3A%3ACritic)
- [Perl::Critic](https://metacpan.org/pod/Perl%3A%3ACritic)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
