use strict;
use warnings;

use Test::More;
use lib "t";
require "common.pl";

is_sub_tree(
    sub { my $var ? 1 : undef },

    {
        op => "cond_expr",
        pred => padsv("var", 0),
        then => const(\1),
        else => {
            op => "undef",
        },
    },
);

is_sub_tree(
    sub { if (my $var) { 1 } else { 2 } },

    {
        op => "cond_expr",
        pred => padsv("var", 0),
        then => {
            op => "scope",
            list => [ const(\1) ],
        },
        else => {
            op => "leave",
            list => [ const(\2) ],
        },
    },
);

is_sub_tree(
    sub { my $a && my $b || my $c; },

    binop("or",
        binop("and",
            padsv("a", 0),
            padsv("b", 0)),
        padsv("c", 0)));

is_sub_tree(
    sub { my $a and my $b or my $c xor my $d },

    binop("xor",
        binop("or",
            binop("and", padsv("a", 0), padsv("b", 0)),
            padsv("c", 0)),
        padsv("d", 0)));

done_testing;
