use strict;
use warnings;

use Test::More;
use lib "t";
require "common.pl";

is_sub_tree(
    sub { (1, 2, my $a, my @b, my %c) },
    listop("list",
        const(\1),
        const(\2),
        padsv("a"),
        padav("b"),
        padhv("c")));

is_sub_tree(
    sub {
        my @a = (1, 2);
    },

    assign("aassign",
        listop("list", padav("a")),
        listop("list", const(\1), const(\2))));

is_sub_tree(
    sub {
        my ($a, @b) = (1, my @c);
    },

    assign("aassign",
        listop("list", padsv("a"), padav("b")),
        listop("list", const(\1), padav("c"))));

is_sub_tree(
    sub {
        my %a = (b => 1, c => my $d);
    },

    assign("aassign",
        listop("list", padhv("a")),
        listop("list",
            const(\"b"),
            const(\1),
            const(\"c"),
            padsv("d"))));

is_sub_tree(
    sub { shift },
    unop("shift", undef),
);

is_sub_tree(
    sub { shift my @a },
    unop("shift", padav("a")),
);

is_sub_tree(
    sub { pop },
    unop("pop", undef),
);

is_sub_tree(
    sub { pop my @a },
    unop("pop", padav("a")),
);

is_sub_tree(
    sub { push my @a, my $b, my %c, 1 },

    listop("push",
        padav("a"),
        padsv("b"),
        padhv("c"),
        const(\1)));

is_sub_tree(
    sub { unshift my @a, my $b, my %c, 1 },

    listop("unshift",
        padav("a"),
        padsv("b"),
        padhv("c"),
        const(\1)));

done_testing;
