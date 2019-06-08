package Test2::Tools::PerlCritic;

use strict;
use warnings;
use base qw( Exporter );
use 5.010;
use Carp qw( croak );
use Ref::Util qw( is_ref is_arrayref is_hashref );
use Test2::API qw( context );
use Perl::Critic ();
use Perl::Critic::Utils ();

our @EXPORT = qw( perl_critic_ok );

# ABSTRACT: Testing tools to enforce Perl::Critic policies
# VERSION

sub _args
{
  my $file = shift;

  if(defined $file)
  {
    unless(-f "$file" || -d "$file")
    {
      croak "no such file: $file";
    }
  }
  else
  {
    croak "no file provided";
  }

  my %opts;
  if(defined $_[0] && is_ref $_[0]) {
    if(is_arrayref $_[0])
    {
      %opts = @{ shift() };
    }
    elsif(is_hashref $_[0])
    {
      %opts = %{ shift() };
    }
    else
    {
      croak "options must be either an array or hash reference";
    }
  }

  my $test_name = shift;

  $test_name //= "no Perl::Critic policy violations for $file";

  ($file, $test_name, %opts);
}

=head1 FUNCTIONS

=head2 perl_critic_ok

 perl_critic_ok $file, \@options, $test_name;
 perl_critic_ok $file, \%options, $test_name;
 perl_critic_ok $file, $test_name;
 perl_critic_ok $file;

=cut

sub perl_critic_ok
{
  my($file_or_dir, $test_name, %opts) = _args(@_);

  my $critic = Perl::Critic->new;
  my %violations;

  my @files = -d "$file_or_dir"
    ? Perl::Critic::Utils::all_perl_files("$file_or_dir")
    : "$file_or_dir";

  foreach my $file (@files)
  {
    foreach my $violation ($critic->critique($file))
    {
      push $violations{$violation->policy}->@*, $violation;
    }
  }

  my $ctx = context();

  if(%violations)
  {
    my @diag;

    foreach my $policy (sort keys %violations)
    {
      my($first) = $violations{$policy}->@*;
      push @diag, '';
      push @diag, sprintf("%s [sev %s]", $policy, $first->severity);
      push @diag, $first->description;
      push @diag, $first->diagnostics;
      push @diag, '';
      foreach my $violation ($violations{$policy}->@*)
      {
        push @diag, sprintf("found at %s line %s column %s",
          $violation->logical_filename,
          $violation->logical_line_number,
          $violation->visual_column_number,
        );
      }
    }

    $ctx->fail_and_release($test_name, @diag);
    return 0;
  }
  else
  {
    $ctx->pass_and_release($test_name);
    return 1;
  }
}

1;
