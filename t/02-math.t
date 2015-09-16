use strict;
use warnings;

use Test::More;
use lib "t";
require "common.pl";

my ($a, $b, $c, $d);

is_sub_tree(
    sub { $a + $b - 24 * $c / $d % 42 },

    binop("subtract",
        binop("add",
            padsv("a", 1),
            padsv("b", 1)),
        binop("modulo",
            binop("divide",
                binop("multiply",
                    const(\24),
                    padsv("c", 1)),
                padsv("d", 1)),
            const(\42))));

is_sub_tree(
    sub { ($a << 1) & ($b >> 2) | 3 ^ $c },

    binop("bit_xor",
        binop("bit_or",
            binop("bit_and",
                binop("left_shift",
                    padsv("a", 1),
                    const(\1)),
                binop("right_shift",
                    padsv("b", 1),
                    const(\2))),
            const(\3)),
    padsv("c", 1)));

done_testing;
