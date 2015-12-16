use strict;
use warnings;

use Test::More;
use B::ExprTree;

my $tree = B::ExprTree::build(sub {
    my $foo 
        = 1;
    $foo;
});

is_deeply $tree->{root}, {
    op => "lineseq",
    location => undef,
    list => [
        {
            op => "sassign",
            location => { file => $0, line => 8 },
            lvalue => {
                op => "padsv",
                location => { file => $0, line => 8 },
                pad_entry => {
                    name => '$foo',
                    outer => 0,
                    value => \undef,
                },
            },
            rvalue => {
                op => "const",
                location => { file => $0, line => 8 },
                pad_entry => {
                    name => undef,
                    outer => 0,
                    value => \1,
                },
            },
        },
        {
            op => "padsv",
            location => { file => $0, line => 10 },
            pad_entry => {
                name => '$foo',
                outer => 0,
                value => \undef,
            },
        },
    ],
};

done_testing;
