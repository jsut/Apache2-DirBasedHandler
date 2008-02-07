package Apache2::DirBasedHandler;

use strict;
use warnings;

use Apache2::Response ();
use Apache2::RequestUtil ();
use Apache2::Log ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(:common);
use Apache2::Request ();

=head1 NAME

Apache2::DirBasedHandler - Directory based Location Handler helper

=head1 VERSION

version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

package My::Thingy

use strict
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
        qq[this is $location/super and all it's contents],
        qq[text/plain; charset=utf-8]
    );
}

sub super_dooper_page {
    my $self = shift;
    my ($r,$uri_args,$args) = @_;

    return (
        Apache2::Const::OK,
        qq[this is $location/super/dooper and all it's contents],
        qq[text/plain; charset=utf-8]
    );
}

1;

=head1 DESCRIPTION

This module is designed to allow people to more quickly implement uri to function
style handlers

=head2 handler

the uri is cut up into bits, then the first argument is used to determine what
page the user is after, so a function is called based on that argument.  The
rest of the uri, the request object, and all our template crap are then passed
into that function.  If there is no uri, a base function called index_page is
called (which you really want to subclass)

=cut

sub handler :method {
    my $self = shift;
    my $r = Apache2::Request->new(shift);

    my $uri_bits = $self->parse_uri($r);
    my $args = $self->init($r);

    my $function;
    my $uri_args = [];
    if (@$uri_bits) {
        while (@$uri_bits) {
            my $try_function = join('_', @$uri_bits) . qq[_page];
            
            $r->warn(qq[trying $try_function]);
            if ($self->can($try_function)) {
                $r->warn(qq[$try_function works!]);
                $function = $try_function;
                last;
            }
            else {
                $r->warn(qq[$try_function not found]);
                unshift @$uri_args, pop @$uri_bits;
            }
        }
        $function ||= qq[index];
    }
    else {
        $function = qq[index];
    }
   
    if (!$function) {
        $r->warn(qq[i do not know what to do with ]. $r->uri);
        return Apache2::Const::NOT_FOUND;
    }
    
    $r->warn(qq[calling $function with path_args (] . join(',',@$uri_args).qq[)]);
    my ($status,$page_out,$content_type) =
        $self->$function($r,$uri_args,$args);

    if ($status ne Apache2::Const::OK) {
        return $status;
    }

    return Apache2::Const::NOT_FOUND
        if !$page_out;

    $r->content_type($content_type);
    $r->print($page_out);
    return $status;
}

=head2 init 

The init function is used to stuff other things into the page function calls.
it should probably return a hash reference to be the most useful.

=cut

sub init {
    my ($self,$r) = @_;
    return {};
}

=head2 parse_uri

takes an Apache::RequestRec (or derived) object, and returns a reference to an
array of all the non-slash parts of the uri.  It strips repeated slashes in the 
same manner that they would be stripped if you do a request for static content

=cut

sub parse_uri {
    my ($self,$r) = @_;

    my $loc = $r->location;
    my $uri = $r->uri;
    $uri =~ s|\/+|\/|gi;
    $uri =~ s|^$loc/?||;
    my @split_uri = split '/', $uri;

    return \@split_uri;
}

=head2 index

index is the function called when someone requests the absolute root of the
location you are talking about

=cut

sub index {
    return (
        Apache2::Const::OK,
        qq[you might want to override "index"],
        'text/html; charset=utf-8'
    );
}

1;
