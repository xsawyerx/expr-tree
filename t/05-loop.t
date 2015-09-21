use strict;
use warnings;

use Test::More;
use lib "t";
require "common.pl";

is_sub_tree(
    sub { while (my $x) { $x = $x / 2 } },

    {
        op => "leaveloop",
        pred => padsv("x"),
        body => listop("lineseq",
            listop("scope",
                assign("sassign",
                    padsv("x"),
                    binop("divide",
                        padsv("x"),
                        const(\2))))),
    });

done_testing;
