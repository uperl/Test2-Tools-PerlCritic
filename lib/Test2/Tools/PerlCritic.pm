package Test2::Tools::PerlCritic;

use strict;
use warnings;
use Exporter qw( import );
use 5.020;
use experimental qw( postderef signatures );
use Carp qw( croak );
use Ref::Util qw( is_ref is_plain_arrayref is_plain_hashref is_blessed_ref );
use Test2::API qw( context );
use Perl::Critic ();
use Perl::Critic::Utils ();
use Path::Tiny ();
use Class::Tiny qw( critic test_name files );

our @EXPORT = qw( perl_critic_ok );

# ABSTRACT: Testing tools to enforce Perl::Critic policies
# VERSION

=head1 SYNOPSIS

Original procedural interface:

 use Test2::V0;
 use Test2::Tools::PerlCritic;
 
 perl_critic_ok ['lib','t'], 'test library files';
 
 done_testing;

New OO interface:

 use Test2::V0;
 use Test2::Tools::PerlCritic ();
 use Perl::Critic;
 
 my $test_critic = Test2::Tools::PerlCritic->new({
   files     => ['lib','t'],
   test_name => 'test library_files',
 });
 
 $test_critic->perl_critic_ok;
 
 done_testing;

=head1 DESCRIPTION

Test for L<Perl::Critic> violations using L<Test2>.  Although this testing
tool uses the L<Test2> API instead of the older L<Test::Builder> API, the primary
motivation is to provide output in a more useful form.  That is policy violations
are grouped by policy class, and the policy class name is clearly displayed as
a diagnostic.  The author finds the former more useful because he tends to address
one type of violation at a time.  The author finds the latter more useful because
he tends to want to lookup or adjust the configuration of the policy as he is
addressing violations.

=cut

sub BUILDARGS
{
  my $class = shift; # unused

  if(is_plain_hashref $_[0] && @_ == 1)
  {
    return $_[0];
  }

  my $files = shift;
  my @opts;
  my $critic;

  if(defined $_[0] && is_ref $_[0]) {
    if(is_plain_arrayref $_[0])
    {
      @opts = @{ shift() };
    }
    elsif(is_plain_hashref $_[0])
    {
      @opts = %{ shift() };
    }
    elsif(eval { $_[0]->isa('Perl::Critic') })
    {
      $critic = shift;
    }
    else
    {
      croak "options must be either an array or hash reference";
    }
  }

  $critic ||= Perl::Critic->new(@opts);

  my $test_name = shift;

  return {
    files => $files,
    critic => $critic,
    test_name => $test_name,
  };
}

sub BUILD ($self, $)
{
  my $files = $self->files;

  if(defined $files)
  {
    if(is_ref $files)
    {
      unless(is_plain_arrayref $files)
      {
        croak "file argument muse be a file/directory name or and array of reference of file/directory names";
      }
    }
    else
    {
      $files = [$files];
    }

    @$files = map { "$_" } @$files;

  }
  else
  {
    croak "no files provided";
  }

  unless(defined $self->test_name)
  {
    $self->test_name("no Perl::Critic policy violations for @$files");
  }

  @$files = sort map { Path::Tiny->new($_)->stringify } map {
    -f $_
      ? $_
      : -d $_
        ? Perl::Critic::Utils::all_perl_files("$_")
        : croak "not a file or directory: $_";
  } @$files;

  $self->files($files);
}

=head1 FUNCTIONS

=head2 perl_critic_ok

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

Run L<Perl::Critic> on the given files or directories.  The first argument
(C<$path> or C<\@path>) can be either the path to a file or directory, or
a array reference to a list of paths to files and directories.  If C<\@options> or
C<\%options> are provided, then they will be passed into the
L<Perl::Critic> constructor.  If C<$critic> (an instance of L<Perl::Critic>)
is provided, then that L<Perl::Critic> instance will be used instead
of creating one internally.  Finally the C<$test_name> may be provided
if you do not like the default test name.

Only a single test is run regardless of how many files are processed.
this is so that the policy violations can be grouped by policy class
across multiple files.

As a convenience, if the test passes then a true value is returned.
Otherwise a false will be returned.

C<done_testing> or the equivalent is NOT called by this function.
You are responsible for calling that yourself.

Since we do not automatically call C<done_testing>, you can call C<perl_critic_ok>
multiple times, but keep in mind that the policy violations will only be grouped
in each individual call, so it is probably better to provide a list of paths,
rather than make multiple calls.

=head1 CONSTRUCTOR

 my $test_critic = Test2::Tools::PerlCritic->new(%properties);

Properties:

=over 4

=item files

(REQUIRED)

List of files or directories.  Directories will be recursively searched for
Perl files (C<.pm>, C<.pl> and C<.t>).

=item critic

The L<Perl::Critic> instance.  One will be created if not provided.

=item test_name

The name of the test.  This is used in diagnostics.

=back

=cut

sub perl_critic_ok
{
  my $self = is_blessed_ref($_[0]) && $_[0]->isa(__PACKAGE__) ? $_[0] : __PACKAGE__->new(@_);

  my %violations;

  foreach my $file ($self->files->@*)
  {
    foreach my $critic_violation ($self->critic->critique($file))
    {
      my $policy = $critic_violation->policy;
      my $violation = $violations{$policy} //= Test2::Tools::PerlCritic::Violation->new($critic_violation);
      $violation->add_file_location($critic_violation);
    }
  }

  my $ctx = context();

  if(%violations)
  {
    my @diag;

    foreach my $policy (sort keys %violations)
    {
      push @diag, $violations{$policy}->diag;

    }

    $ctx->fail_and_release($self->test_name, @diag);
    return 0;
  }
  else
  {
    $ctx->pass_and_release($self->test_name);
    return 1;
  }
}

package Test2::Tools::PerlCritic::Violation;

use Class::Tiny qw( severity description diagnostics policy files );

sub BUILDARGS ($class, $violation)
{
  my %args = map { $_ => $violation->$_ } qw( severity description diagnostics policy );
  $args{files} = {};
  return \%args;
}

sub add_file_location ($self, $violation)
{
  my $file = $self->files->{$violation->logical_filename} //= Test2::Tools::PerlCritic::File->new($violation);
  $file->add_location($violation);
}

sub _chomp ($str)
{
  chomp $str;
  return $str;
}

sub diag ($self)
{
  my @diag;

  push @diag, '';
  push @diag, sprintf("%s [sev %s]", $self->policy, $self->severity);
  push @diag, $self->description;
  push @diag, _chomp($self->diagnostics);
  push @diag, '';

  foreach my $file (sort { $a->logical_filename cmp $b->logical_filename } values $self->files->%*)
  {
    foreach my $location ($file->locations->@*)
    {
      push @diag, sprintf("found at %s line %s column %s",
        Path::Tiny->new($file->logical_filename)->stringify,
        $location->logical_line_number,
        $location->visual_column_number,
      );
    }
  }

  return @diag;
}

package Test2::Tools::PerlCritic::File;

use Class::Tiny qw( logical_filename locations );

sub BUILDARGS ($class, $violation)
{
  my %args;
  $args{logical_filename} = $violation->logical_filename;
  $args{locations} = [];
  return \%args;
}

sub add_location ($self, $violation)
{
  push $self->locations->@*, Test2::Tools::PerlCritic::Location->new($violation);
}

sub count ($self)
{
  scalar $self->locations->@*;
}

package Test2::Tools::PerlCritic::Location;

use Class::Tiny qw( logical_line_number visual_column_number );

sub BUILDARGS ($class, $violation)
{
  my %args = map { $_ => $violation->$_ } qw( logical_line_number visual_column_number );
  return \%args;
}

1;

=head1 CAVEATS

L<Test::Perl::Critic> has been around longer, and probably does at least some things smarter.
The fact that this module groups policy violations for all files by class means that it has
to store more diagnostics in memory before sending them out I<en masse>, where as
L<Test::Perl::Critic> sends violations for each file as it processes them.  L<Test::Perl::Critic>
also comes with some code to optionally do processing in parallel.  Some of these issues may
or may not be addressed in future versions of this module.

Since this module formats it's output the C<-verbose> option is ignored at the C<set_format>
value is ignored.

=head1 SEE ALSO

=over 4

=item L<Test::Perl::Critic>

=item L<Perl::Critic>

=back

=cut
