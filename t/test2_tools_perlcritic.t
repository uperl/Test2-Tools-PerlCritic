use Test2::V0 -no_srand => 1;
use Test2::Tools::PerlCritic;
use Perl::Critic ();

subtest '_args' => sub {

  subtest 'files' => sub {

    is(
      [Test2::Tools::PerlCritic::_args( 'corpus/lib1/Foo.pm' )],
      array {
        item ['corpus/lib1/Foo.pm'];
        etc;
      },
      'simple file',
    );

    is(
      [Test2::Tools::PerlCritic::_args( 'corpus/lib1' )],
      array {
        item ['corpus/lib1/Bar.pm','corpus/lib1/Baz.pm','corpus/lib1/Foo.pm'];
        etc;
      },
      'simple directory',
    );

    is(
      [Test2::Tools::PerlCritic::_args( ['corpus/lib1/Foo.pm', 'corpus/lib1/Bar.pm'] )],
      array {
        item ['corpus/lib1/Bar.pm','corpus/lib1/Foo.pm'];
        etc;
      },
      'two files',
    );

    is(
      [Test2::Tools::PerlCritic::_args( ['corpus/lib1'] )],
      array {
        item ['corpus/lib1/Bar.pm','corpus/lib1/Baz.pm','corpus/lib1/Foo.pm'];
        etc;
      },
      'directory in array ref',
    );

    like(
      dies { Test2::Tools::PerlCritic::_args() },
      qr/no files provided/,
      'no files provided',
    );

    like(
      dies { Test2::Tools::PerlCritic::_args({}) },
      qr/file argument muse be a file\/directory name or and array of reference of file\/directory names/,
      'must be a scalar or arrray ref',
    );

    like(
      dies { Test2::Tools::PerlCritic::_args('corpus/lib1/Bogus.pm') },
      qr/not a file or directory: corpus\/lib1\/Bogus\.pm/,
      'bogus filename',
    );

  };

  subtest 'critic' => sub {

    my $critic = Perl::Critic->new;
    ref_is(
      [Test2::Tools::PerlCritic::_args('corpus/lib1', $critic)]->[1],
      $critic,
      'pass through critic object',
    );

    ref_is_not(
      [Test2::Tools::PerlCritic::_args('corpus/lib1')]->[1],
      $critic,
      'generate new critic',
    );

    is(
      [Test2::Tools::PerlCritic::_args('corpus/lib1')],
      array {
        item D();
        item object sub {
          prop blessed => 'Perl::Critic';
        };
        etc;
      },
      'generate new critic correct class',
    );

  };

  subtest 'options' => sub {

    my %opts;
    my @opts;

    my $mock = mock 'Perl::Critic' => (
      around => [
        new => sub {
          my $orig = shift;
          my $class = shift;
          %opts = @_;
          @opts = @_;
          $class->$orig;
        },
      ],
    );

    Test2::Tools::PerlCritic::_args('corpus/lib1', [ -foo => 1, -bar => 2 ]);
    is(\@opts, [ -foo =>1, -bar => 2 ], 'passing as array ref');

    Test2::Tools::PerlCritic::_args('corpus/lib1', { -foo => 1, -bar => 2 });
    is(\%opts, { -foo =>1, -bar => 2 }, 'passing as hash ref');

    like(
      dies { Test2::Tools::PerlCritic::_args('corpus/lib1', \"foo") },
      qr/options must be either an array or hash reference/,
      'do not accept non hash or array',
    );

  };

  subtest 'test name' => sub {

    is(
      [Test2::Tools::PerlCritic::_args('corpus/lib1/Foo.pm')],
      array {
        item D();
        item D();
        item 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
      },
      'default test name'
    );

    is(
      [Test2::Tools::PerlCritic::_args('corpus/lib1/Foo.pm', 'override')],
      array {
        item D();
        item D();
        item 'override';
      },
      'override test name'
    );

    my $critic = Perl::Critic->new;

    is(
      [Test2::Tools::PerlCritic::_args('corpus/lib1/Foo.pm', $critic)],
      array {
        item D();
        item D();
        item 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
      },
      'default test name (positional)'
    );

    is(
      [Test2::Tools::PerlCritic::_args('corpus/lib1/Foo.pm', $critic, 'override')],
      array {
        item D();
        item D();
        item 'override';
      },
      'override test name (positional)'
    );


  };

};

subtest 'perl_critic_ok' => sub {

  subtest 'pass' => sub {

    my $mock = mock 'Perl::Critic' => (
      override => [ critique => sub { () } ],
    );

    is(
      intercept { perl_critic_ok 'corpus/lib1/Foo.pm' },
      array {
        event Pass => sub {
          call name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
        };
        end;
      },
      'pass with default test name'
    );

    is(
      intercept { perl_critic_ok 'corpus/lib1/Foo.pm', 'override test name' },
      array {
        event Pass => sub {
          call name => 'override test name';
        };
        end;
      },
      'pass with override test name'
    );

  };

};

done_testing;
