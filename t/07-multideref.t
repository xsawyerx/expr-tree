use strict;
use warnings;

use Test::More;
use lib "t";
require "common.pl";

my ($x, $y, @a, %h);

is_sub_tree(
    sub { $h{$x}[1]{a}[$y] },
    {
        op => "aelem",
        index => padsv("y", 1),
        array => unop("rv2av", {
            op => "helem",
            key => const(\"a"),
            hash => unop("rv2hv", {
                op => "aelem",
                index => const(\1),
                array => unop("rv2av", {
                    op => "helem",
                    hash => padhv("h", 1),
                    key => padsv("x", 1),
                }),
            }),
        }),
    });

is_sub_tree(
    sub { $h{$x + 1}[1]{$A::x}[$y + 2] },
    {
        op => "aelem",
        index => binop("add", padsv("y", 1), const(\2)),
        array => unop("rv2av", {
            op => "helem",
            key => gv("A::x"),
            hash => unop("rv2hv", {
                op => "aelem",
                index => const(\1),
                array => unop("rv2av", {
                    op => "helem",
                    hash => padhv("h", 1),
                    key => binop("add", padsv("x", 1), const(\1))
                }),
            }),
        }),
    });

is_sub_tree(
    sub { $x->[1]{2} },
    {
        op => "helem",
        key => const(\2),
        hash => unop("rv2hv", {
            op => "aelem",
            index => const(\1),
            array => unop("rv2av", padsv("x", 1)),
        })
    });

done_testing;
