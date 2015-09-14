use 5.020;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'B::ExprTree',
    AUTHOR           => q{Vickenty Fesunov <cpan-exprtree@setattr.net>},
    VERSION_FROM     => 'lib/B/ExprTree.pm',
    ABSTRACT_FROM    => 'lib/B/ExprTree.pm',
    LICENSE          => 'bsd',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.020,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    },
);
