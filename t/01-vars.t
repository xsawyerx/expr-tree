use strict;
use warnings;

use Test::More;
use lib "t";
require "common.pl";

is_sub_tree(
    sub { 1 },
    const(\1));

is_sub_tree(
    sub { -1.5e-1 },
    const(\-1.5e-1));

is_sub_tree(
    sub { my $var },
    padsv("var", 0),
);

my ($x, $y, @a, %h);

is_sub_tree(
    sub { $a[$x] },
    {
        op => "aelem",
        array => padav("a", 1),
        index => padsv("x", 1),
    });

is_sub_tree(
    sub { $a[1] },
    {
        op => "aelemfast_lex",
        pad_entry => { name => '@a', outer => 1, value => [] },
        index => 1,
    });

is_sub_tree(
    sub { $x->[$y] },
    {
        op => "aelem",
        array => unop("rv2av", padsv("x", 1)),
        index => padsv("y", 1),
    });

is_sub_tree(
    sub { $B::EXPORT_OK[$x] },
    {
        op => "aelem",
        array => unop("rv2av", gv("B::EXPORT_OK")),
        index => padsv("x", 1),
    });

is_sub_tree(
    sub { $B::EXPORT_OK[1] },
    {
        op => "aelemfast",
        pad_entry => { name => "<special>", outer => 0, value => \*B::EXPORT_OK },
        index => 1,
    });

is_sub_tree(
    sub { $h{foo} },
    {
        op => "helem",
        hash => padhv("h", 1),
        key => const(\"foo"),
    });

is_sub_tree(
    sub { $x->{$y} },
    {
        op => "helem",
        hash => unop("rv2hv", padsv("x", 1)),
        key => padsv("y", 1),
    });

is_sub_tree(
    sub { my $x = my $y },
    assign("sassign",
        padsv("x"),
        padsv("y")));

done_testing;
