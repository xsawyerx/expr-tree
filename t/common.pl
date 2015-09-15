use strict;
use warnings;

use Test::More;

require_ok "B::ExprTree";

sub is_sub_tree {
    my ($code, @seq) = @_;

    my $tree = B::ExprTree::build($code);

    is_deeply $tree->{root}, {
        op => "lineseq",
        list => [ @seq ],
    };

    return $tree->{root};
}

sub padop {
    my ($op, $name, $outer, $value) = @_;
    $outer //= 0;
    return {
        op => $op,
        pad_entry => {
            name => $name,
            outer => $outer,
            value => $value,
        },
    };
}

sub const {
    padop("const", "<special>", 0, shift)
}

sub padsv {
    my ($name, $outer, $value) = @_;
    $value //= \undef;
    padop("padsv", "\$$name", $outer, $value);
}

sub padav {
    my ($name, $outer, $value) = @_;
    $value //= [];
    padop("padav", "\@$name", $outer, $value);
}

sub padhv {
    my ($name, $outer, $value) = @_;
    $value //= {};
    padop("padhv", "\%$name", $outer, $value);
}

sub gv {
    my ($name) = @_;
    no strict "refs";
    padop("gv", "<special>", 0, \*{$name});
}

sub unop {
    my ($op, $arg) = @_;
    return {
        op => $op,
        arg => $arg,
    };
}

sub binop {
    my ($op, @args) = @_;
    return {
        op => $op,
        args => [ @args ],
    };
}

