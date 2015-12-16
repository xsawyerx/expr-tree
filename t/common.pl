use strict;
use warnings;

use Test::More;

require_ok "B::ExprTree";

sub is_sub_tree {
    my ($code, @seq) = @_;

    my $tree = B::ExprTree::build($code, no_locations => 1);

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
    padop("const", undef, 0, shift)
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
    padop("gv", undef, 0, \*{$name});
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

sub listop {
    my ($op, @list) = @_;
    return {
        op => $op,
        list => [ @list ],
    };
}

sub assign {
    my ($op, $lvalue, $rvalue) = @_;
    return {
        op => $op,
        lvalue => $lvalue,
        rvalue => $rvalue,
    };
}

