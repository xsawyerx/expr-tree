use strict;
use warnings;

use Test::More 'tests' => 3;
use B::ExprTree;

## no critic qw(ValuesAndExpressions::ProhibitDuplicateHashKeys)

my %known_str_ops = (
    'const' => sub { ${ $_[0]->{'value'} } },
    'padsv' => sub { $_[0]->{'pad_entry'}{'name'} },
);

sub find_op {
    my ( $op_struct, $elem_type, $cb ) = @_;
    my $op_type = $op_struct->{'op'};

    $op_type eq $elem_type
        and return $cb->( $op_struct );

    # I don't know all types, obviously
    if ( $op_type eq 'list' || $op_type eq 'lineseq' ) {
        foreach my $inner_op_struct ( @{ $op_struct->{'list'} } ) {
            find_op( $inner_op_struct, $elem_type, $cb );
        }
    }

    # Double obviously
    if ( $op_type eq 'aassign' ) {
        foreach my $key ( qw< lvalue rvalue > ) {
            my $inner_op_struct = $op_struct->{$key};
            find_op( $inner_op_struct, $elem_type, $cb );
        }
    }

    return;
}

sub find_dups {
    my ( $code, @exp_dups ) = @_;
    my %found_dups;

    my $tree = B::ExprTree::build( $code, 'no_locations' => 1 );

    find_op( $tree->{'root'}, 'list', sub {
        my $list_op = shift;

        my %names;
        foreach my $item ( @{ $list_op->{'list'} } ) {
            my $item_str_cb = $known_str_ops{ $item->{'op'} }
                or return;

            my $item_name = $item_str_cb->($item);

            # Count and check at the same time
            if ( $names{$item_name}++ > 0 ) {
                # This isn't the smartest check
                # since we're populating a global collection of duplicates
                # from any list we find, which is really bad.
                # Not sure how to do it correctly though...
                $found_dups{$item_name} = 1;
            }
        }
    });

    is_deeply(
        [ sort keys %found_dups ],
        [ sort @exp_dups ],
        'Correctly found all dups: ' . join ', ', @exp_dups,
    );
}

find_dups(
    sub {
        my %hash_with_dup_keys = (
            'foo' => 1,
            'bar' => 2,
            'foo' => 3,
        );
    },
    qw<foo>,
);

find_dups(
    sub {
        my %hash_with_dup_keys = (
            'foo' => 1,
            'bar' => 2,
            'bar' => 4,
            'foo' => 3,
        );
    },
    qw< foo bar >,
);

find_dups(
    sub {
        my $bar;
        my %hash_with_dup_keys = (
            'foo' => 1,
            'bar' => 2,
            $bar  => 4,
            "foo" => 3,
            $bar  => 5,
        );
    },
    qw< foo $bar >,
);
