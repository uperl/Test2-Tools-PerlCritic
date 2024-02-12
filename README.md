# Test2::Tools::PerlCritic ![linux](https://github.com/uperl/Test2-Tools-PerlCritic/workflows/linux/badge.svg) ![static](https://github.com/uperl/Test2-Tools-PerlCritic/workflows/static/badge.svg)

Testing tools to enforce Perl::Critic policies

# SYNOPSIS

Original procedural interface:

```perl
use Test2::V0;
use Test2::Tools::PerlCritic;

perl_critic_ok ['lib','t'], 'test library files';

done_testing;
```

New OO interface:

```perl
use Test2::V0;
use Test2::Tools::PerlCritic ();
use Perl::Critic;

my $test_critic = Test2::Tools::PerlCritic->new({
  files     => ['lib','t'],
  test_name => 'test library_files',
});

$test_critic->perl_critic_ok;

done_testing;
```

# DESCRIPTION

Test for [Perl::Critic](https://metacpan.org/pod/Perl::Critic) violations using [Test2](https://metacpan.org/pod/Test2).  Although this testing
tool uses the [Test2](https://metacpan.org/pod/Test2) API instead of the older [Test::Builder](https://metacpan.org/pod/Test::Builder) API, the primary
motivation is to provide output in a more useful form.  That is policy violations
are grouped by policy class, and the policy class name is clearly displayed as
a diagnostic.  The author finds the former more useful because he tends to address
one type of violation at a time.  The author finds the latter more useful because
he tends to want to lookup or adjust the configuration of the policy as he is
addressing violations.

# FUNCTIONS

## perl\_critic\_ok

```
perl_critic_ok $path, \@options, $test_name;
perl_critic_ok \@path, \@options, $test_name;
perl_critic_ok $path, \%options, $test_name;
perl_critic_ok \@path, \%options, $test_name;
perl_critic_ok $path, $critic, $test_name;
perl_critic_ok \@path, $critic, $test_name;
perl_critic_ok $path, $test_name;
perl_critic_ok \@path, $test_name;
perl_critic_ok $path;
perl_critic_ok \@path;
```

Run [Perl::Critic](https://metacpan.org/pod/Perl::Critic) on the given files or directories.  The first argument
(`$path` or `\@path`) can be either the path to a file or directory, or
a array reference to a list of paths to files and directories.  If `\@options` or
`\%options` are provided, then they will be passed into the
[Perl::Critic](https://metacpan.org/pod/Perl::Critic) constructor.  If `$critic` (an instance of [Perl::Critic](https://metacpan.org/pod/Perl::Critic))
is provided, then that [Perl::Critic](https://metacpan.org/pod/Perl::Critic) instance will be used instead
of creating one internally.  Finally the `$test_name` may be provided
if you do not like the default test name.

Only a single test is run regardless of how many files are processed.
this is so that the policy violations can be grouped by policy class
across multiple files.

As a convenience, if the test passes then a true value is returned.
Otherwise a false will be returned.

`done_testing` or the equivalent is NOT called by this function.
You are responsible for calling that yourself.

Since we do not automatically call `done_testing`, you can call `perl_critic_ok`
multiple times, but keep in mind that the policy violations will only be grouped
in each individual call, so it is probably better to provide a list of paths,
rather than make multiple calls.

# CONSTRUCTOR

```perl
my $test_critic = Test2::Tools::PerlCritic->new(\%properties);
```

Properties:

- files

    (REQUIRED)

    List of files or directories.  Directories will be recursively searched for
    Perl files (`.pm`, `.pl` and `.t`).

- critic

    The [Perl::Critic](https://metacpan.org/pod/Perl::Critic) instance.  One will be created if not provided.

- test\_name

    The name of the test.  This is used in diagnostics.

# METHODS

## perl\_critic\_ok

```
$test_critic->perl_critic_ok;
```

The method version works just like the functional version above,
except it doesn't take any additional arguments.

## add\_hook

```
$test_critic->add_hook($hook_name, \&code);
```

Adds the given hook.  Available hooks:

- cleanup

    ```perl
    $test_critic->add_hook(cleanup => sub ($test_critic, $global) {
      ...
    });
    ```

    This hook is called when the [Test2::Tools::PerlCritic](https://metacpan.org/pod/Test2::Tools::PerlCritic) instance is destroyed.

    If the hook is called during global destruction of the Perl interpreter,
    `$global` will be set to a true value.

    This hook can be set multiple times.

- progressive\_check

    ```perl
    $test_critic->add_hook(progressive_check => sub ($test_critic, $policy, $file, $count) {
      ...
      return $bool;
    });
    ```

    This hook is made available for violations in existing code when new policies
    are added.  Passed in are the [Test2::Tools::PerlCritic](https://metacpan.org/pod/Test2::Tools::PerlCritic) instance, the policy
    name, the filename and the number of times the violation was found.  If the
    violations are from an old code base with grandfathered allowed violations,
    this hook should return true, and the violation will be reported as a `note`
    instead of `diag` and will not cause the test as a whole to fail.  Otherwise
    the violation will be reported using `diag` and the test as a whole will fail.

    This hook can only be set once.

# CAVEATS

[Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic) has been around longer, and probably does at least some things smarter.
The fact that this module groups policy violations for all files by class means that it has
to store more diagnostics in memory before sending them out _en masse_, where as
[Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic) sends violations for each file as it processes them.  [Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic)
also comes with some code to optionally do processing in parallel.  Some of these issues may
or may not be addressed in future versions of this module.

Since this module formats it's output the `-verbose` option is ignored at the `set_format`
value is ignored.

# SEE ALSO

- [Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic)
- [Perl::Critic](https://metacpan.org/pod/Perl::Critic)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
