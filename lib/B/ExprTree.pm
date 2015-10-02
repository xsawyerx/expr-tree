package B::ExprTree;

use 5.020;
use strict;
use warnings;

use B;

our $VERSION = "0.1";

sub codevars {
    my $obj = shift;
    my ($names, $values) = $obj->PADLIST->ARRAY;
    my @names = $names->ARRAY;
    my @values = $values->ARRAY;

    my @res;
    foreach my $idx (0 .. $#names) {
        my $name_sv = $names[$idx];
        my $is_special = $name_sv->isa("B::SPECIAL");

        my $name = $is_special ? "<special>" : $name_sv->PV;

        my $value_sv = $values[$idx];
        my $value_ref = $value_sv->isa("B::SPECIAL") ? $value_sv : $value_sv->object_2svref;

        push @res, {
            name => $name,
            value => $value_ref,
            outer => !$is_special && $name_sv->FLAGS & B::SVf_FAKE ? 1 : 0,
        };
    }

    return \@res;
}

sub opname {
    my $op = shift;
    my $name = $op->name;
    return $name eq "null"
        ? substr B::ppname($op->targ), 3
        : $name;
}

my %ops;
sub expr {
    my ($scope, $op, %args) = @_;

    local @$scope{keys %args} = values %args;

    my $type = ref $op;
    my $name = opname($op);
    my $impl = $ops{$name} // die "unsupported op $name of type $type";

    my %def;
    $def{op} = $name;
    $def{location} = $scope->{location}
        unless $scope->{args}{no_locations};

    my @ops = map +{ %def, %$_ }, $impl->($scope, $op);

    wantarray ? @ops : $ops[0];
}

sub build {
    my ($code, %args) = @_;

    my $obj = B::svref_2object $code;
    my $scope = {
        args => \%args,
        vars => codevars($obj),
    };

    my $tree = expr $scope, $obj->ROOT;
    return {
        vars => $scope->{vars},
        root => $tree,
    };
}

$ops{null} =
$ops{scalar} =
$ops{entersub} =
$ops{leavesub} = sub {
    my ($scope, $op) = @_;
    return expr($scope, $op->first);
};

$ops{unstack} =
$ops{enter} =
$ops{padrange} =
$ops{pushmark} = sub {
    return ();
};

$ops{nextstate} = sub {
    my ($scope, $op) = @_;
    $scope->{location} = { file => $op->file, line => $op->line } if $op->can("file");
    return ();
};

$ops{push} =
$ops{unshift} =
$ops{list} =
$ops{leave} =
$ops{scope} =
$ops{lineseq} = sub {
    my ($scope, $op) = @_;
    my $child = $op->first;
    my @list;
    while (!UNIVERSAL::isa($child, "B::NULL")) {
        push @list, expr($scope, $child);
        $child = $child->sibling;
    }

    return {
        list => \@list,
    };
};

$ops{const} =
$ops{padav} =
$ops{padhv} =
$ops{padsv} = sub {
    my ($scope, $op) = @_;
    return {
        pad_entry => $scope->{vars}->[$op->targ],
    };
};

$ops{gv} = sub {
    my ($scope, $op) = @_;
    return {
        pad_entry => $scope->{vars}->[$op->padix],
    };
};

$ops{undef} = sub {
    my ($scope, $op) = @_;
    return {
    };
};

$ops{cond_expr} = sub {
    my ($scope, $op) = @_;
    return {
        pred => expr($scope, $op->first),
        then => expr($scope, $op->first->sibling),
        else => expr($scope, $op->first->sibling->sibling),
    };
};

$ops{and} =
$ops{or} =
$ops{xor} =
sub {
    my ($scope, $op) = @_;
    return {
        args => [
            expr($scope, $op->first),
            expr($scope, $op->first->sibling),
        ],
    };
};

$ops{add} =
$ops{subtract} =
$ops{multiply} =
$ops{divide} =
$ops{modulo} =
$ops{bit_and} =
$ops{bit_or} =
$ops{bit_xor} =
$ops{left_shift} =
$ops{right_shift} =
$ops{eq} =
$ops{le} =
$ops{lt} =
$ops{ge} =
$ops{gt} =
$ops{seq} =
$ops{sle} =
$ops{slt} =
$ops{sge} =
$ops{sgt} =
sub {
    my ($scope, $op) = @_;

    my $res = {
        op => opname($op),
        args => [ map expr($scope, $op->$_), qw/first last/ ],
    };

    if ($op->private & B::OPpTARGET_MY) {
        return {
            op => "sassign",
            lvalue => {
                op => "padsv",
                pad_entry => $scope->{vars}->[$op->targ],
            },
            rvalue => $res,
        };
    }
    else {
        return $res;
    }
};

$ops{rv2av} = sub {
    my ($scope, $op) = @_;

    if ($op->name eq "null" && opname($op->first) eq "aelemfast") {
        return expr($scope, $op->first);
    }

    return {
        arg => expr($scope, $op->first),
    };
};

$ops{abs} =
$ops{negate} =
$ops{rv2hv} = sub {
    my ($scope, $op) = @_;
    return {
        arg => expr($scope, $op->first),
    };
};

$ops{aelem} = sub {
    my ($scope, $op) = @_;

    if (ref $op eq "B::UNOP" && $op->name eq "null") {
        return expr($scope, $op->first);
    };

    return {
        array => expr($scope, $op->first),
        index => expr($scope, $op->last),
    };
};

$ops{aelemfast} = sub {
    my ($scope, $op) = @_;
    return {
        pad_entry => $scope->{vars}->[$op->padix],
        index => $op->private,
    };
};

$ops{aelemfast_lex} = sub {
    my ($scope, $op) = @_;
    return {
        pad_entry => $scope->{vars}->[$op->targ],
        index => $op->private,
    };
};

$ops{helem} = sub {
    my ($scope, $op) = @_;
    return {
        hash => expr($scope, $op->first),
        key => expr($scope, $op->last),
    };
};

$ops{sassign} =
$ops{aassign} = sub {
    my ($scope, $op) = @_;
    return {
        rvalue => expr($scope, $op->first),
        lvalue => expr($scope, $op->last),
    };
};

$ops{pop} =
$ops{shift} = sub {
    my ($scope, $op) = @_;

    my $class = ref $op;
    if ($class eq "B::UNOP") {
        return {
            arg => expr($scope, $op->first),
        };
    }
    elsif ($class eq "B::OP") {
        return {
            arg => undef,
        };
    }
    else {
        die "unknown op_shift class: $class";
    }
};

sub assert {
    my ($self, $targ, $name) = @_;

    $self = opname($self);
    $targ = opname($targ);

    die "$self: unexpected child $targ"
        unless $targ eq $name;
}

$ops{leaveloop} = sub {
    my ($scope, $op) = @_;

    assert($op, $op->first, "enterloop");

    assert($op, my $null = $op->last, "null");
    assert($op, my $cond = $null->first, "and");

    return {
        pred => expr($scope, $cond->first),
        body => expr($scope, $cond->first->sibling),
    };
};

1;

=head1 NAME

B::ExprTree - build an expression tree from Perl opcodes

=cut
