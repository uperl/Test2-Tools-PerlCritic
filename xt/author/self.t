use Test2::V0;
use Test2::Tools::PerlCritic;

perl_critic_ok 'lib', [ -profile => 'perlcritic' ];
perl_critic_ok 't',   [ -profile => 'perlcritic' ];

done_testing;
