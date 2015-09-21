use strict;
use warnings;

use Test::More;
use lib "t";
require "common.pl";

is_sub_tree(
    sub { while (my $x) { $x } },

    {
        op => "leaveloop",
        pred => padsv("x"),
        body => listop("lineseq",
            listop("scope", padsv("x"))),
    });

done_testing;
