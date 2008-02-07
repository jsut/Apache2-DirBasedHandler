package My::Thingy;

use strict;

use Apache2::DirBasedHandler
our @ISA = qw(Apache2::DirBasedHandler);

use Apache2::Const -compile => qw(:common);

sub index {
    my $self = shift;
    my ($r,$uri_args,$args) = @_;

    if (@$uri_args) {
        return Apache2::Const::NOT_FOUND;
    }

    return (
        Apache2::Const::OK,
        qq[this is the index],
        qq[text/plain; charset=utf-8]
    );
}

sub super_page {
    my $self = shift;
    my ($r,$uri_args,$args) = @_;

    return (
        Apache2::Const::OK,
        qq[this is \$location/super and all it's contents],
        qq[text/plain; charset=utf-8]
    );
}

sub super_dooper_page {
    my $self = shift;
    my ($r,$uri_args,$args) = @_;

    return (
        Apache2::Const::OK,
        qq[this is \$location/super/dooper and all it's contents],
        qq[text/plain; charset=utf-8]
    );
}

1;
