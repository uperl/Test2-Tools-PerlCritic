use Test2::V0 -no_srand => 1;
use Test2::Tools::PerlCritic;
use Perl::Critic ();

subtest 'BUILDARGS / BUILD' => sub {

  subtest 'files' => sub {

    is(
      Test2::Tools::PerlCritic->new( 'corpus/lib1/Foo.pm' ),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call files => ['corpus/lib1/Foo.pm'];
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
        call test_name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
      },
      'simple file',
    );

    is(
      Test2::Tools::PerlCritic->new( 'corpus/lib1' ),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call files => ['corpus/lib1/Bar.pm','corpus/lib1/Baz.pm','corpus/lib1/Foo.pm'];
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
        call test_name => 'no Perl::Critic policy violations for corpus/lib1';
      },
      'simple directory',
    );

    is(
      Test2::Tools::PerlCritic->new( ['corpus/lib1/Foo.pm', 'corpus/lib1/Bar.pm'] ),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call files => ['corpus/lib1/Bar.pm','corpus/lib1/Foo.pm'];
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
        call test_name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm corpus/lib1/Bar.pm';
      },
    );

    is(
      Test2::Tools::PerlCritic->new( ['corpus/lib1'] ),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call files => ['corpus/lib1/Bar.pm','corpus/lib1/Baz.pm','corpus/lib1/Foo.pm'];
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
        call test_name => 'no Perl::Critic policy violations for corpus/lib1';
      },
      'directory in array ref',
    );

    like(
      dies { Test2::Tools::PerlCritic->new() },
      qr/no files provided/,
      'no files provided',
    );

    like(
      dies { Test2::Tools::PerlCritic->new('corpus/lib1/Bogus.pm') },
      qr/not a file or directory: corpus\/lib1\/Bogus\.pm/,
      'bogus filename',
    );

  };

  subtest 'critic' => sub {

    my $critic = Perl::Critic->new;
    ref_is(
      Test2::Tools::PerlCritic->new('corpus/lib1', $critic)->critic,
      $critic,
      'pass through critic object',
    );

    ref_is_not(
      Test2::Tools::PerlCritic->new('corpus/lib1')->critic,
      $critic,
      'generate new critic',
    );

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1'),
      object {
        prop blessed => 'Test2::Tools::PerlCritic';
        call critic => object {
          prop blessed => 'Perl::Critic';
        };
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

    Test2::Tools::PerlCritic->new('corpus/lib1', [ -foo => 1, -bar => 2 ]);
    is(\@opts, [ -foo =>1, -bar => 2 ], 'passing as array ref');

    Test2::Tools::PerlCritic->new('corpus/lib1', { -foo => 1, -bar => 2 });
    is(\%opts, { -foo =>1, -bar => 2 }, 'passing as hash ref');

    like(
      dies { Test2::Tools::PerlCritic->new('corpus/lib1', \"foo") },
      qr/options must be either an array or hash reference/,
      'do not accept non hash or array',
    );

  };

  subtest 'test name' => sub {

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1/Foo.pm'),
      object {
        call test_name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
      },
      'default test name'
    );

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1/Foo.pm', 'override'),
      object {
        call test_name => 'override';
      },
      'override test name'
    );

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1/Foo.pm', Perl::Critic->new),
      object {
        call test_name => 'no Perl::Critic policy violations for corpus/lib1/Foo.pm';
      },
      'default test name (positional)'
    );

    is(
      Test2::Tools::PerlCritic->new('corpus/lib1/Foo.pm', Perl::Critic->new, 'override'),
      object {
        call test_name => 'override';
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

  subtest 'fail' => sub {

    package main {}
    package Perl::Critic::Policy::Foo::Bar {

      use base qw( Perl::Critic::Policy );
      use Perl::Critic::Utils qw( :booleans :severities );

      sub supported_parameters {
        return {
          name => 'foo_bar',
          description => 'A violation of the simple Foo Bar principal',
        };
      }

      sub default_severity { $SEVERITY_HIGHEST }
      sub default_themes { () }
      sub applies_to { 'PPI::Token::Word' }

      sub violates {
        my($self, $elem) = @_;
        if($elem->literal eq 'package')
        {
          return $self->violation( 'Foo Bar found', [29], $elem);
        }
        return;
      }

    }

    my $critic = Perl::Critic->new(
      -only => 1,
    );
    $critic->add_policy( -policy => 'Perl::Critic::Policy::Foo::Bar' );

    is(
      intercept { perl_critic_ok 'corpus/lib1', $critic },
      array {
        event Fail => sub {
          call name => 'no Perl::Critic policy violations for corpus/lib1';
          call facet_data => hash {
            field info => [map {
              my %foo = ( debug => 1, tag => 'DIAG', details => $_ );
              \%foo;
            } (
              '',
              'Perl::Critic::Policy::Foo::Bar [sev 5]',
              'Foo Bar found',
              '    No diagnostics available',
              '',
              'found at corpus/lib1/Bar.pm line 1 column 1',
              'found at corpus/lib1/Baz.pm line 1 column 1',
              'found at corpus/lib1/Foo.pm line 1 column 1',
            )];
            etc;
          };
        };
      },
      'simple fail'
    );

  };

};

done_testing;
