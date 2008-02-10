package Apache2::DirBasedHandler;

use strict;

use Apache2::Response ();
use Apache2::RequestUtil ();
use Apache2::Log ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(:common);
use Apache2::Request ();

our $VERSION = '0.02';
our $Debug = 0;

=head1 NAME

Apache2::DirBasedHandler - Directory based Location Handler helper

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
style handlers.  This module is intended to be subclassed.

A request for 

  $r->location . qq[/foo/bar/baz/]

will be served by the first of the following functions with is defined

  foo_bar_baz_page
  foo_bar_page
  foo_page
  index

=head2 handler

C<handler> is the guts of DirBasedHandler.  It provides the basic structure of the
modules, turning the request uri into an array, which is then turned into possible
function calls.  

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
            my $try_function = $self->uri_to_function($r,$uri_bits);
            
            $Debug && $r->warn(qq[trying $try_function]);
            if ($self->can($try_function)) {
                $Debug && $r->warn(qq[$try_function works!]);
                $function = $try_function;
                last;
            }
            else {
                $Debug && $r->warn(qq[$try_function not found]);
                unshift @$uri_args, pop @$uri_bits;
            }
        }
        $function ||= qq[index];
    }
    else {
        $function = qq[index];
    }
   
    if (!$function) {
        $Debug && $r->warn(qq[i do not know what to do with ]. $r->uri);
        return Apache2::Const::NOT_FOUND;
    }
    
    $Debug && $r->warn(qq[calling $function with path_args (] . join(',',@$uri_args).qq[)]);
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

C<init> is used to include objects or data you want to be passed into 
your page functions.  To be most useful it should return a hash reference. 
The default implementation returns a reference to an empty hash.

=cut

sub init {
    my ($self,$r) = @_;
    return {};
}

=head2 parse_uri

C<parse_uri> takes an Apache::RequestRec (or derived) object, and returns a reference to an
array of all the non-slash parts of the uri.  It strips repeated slashes in the 
same manner that they would be stripped if you do a request for static content.

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

=head2 uri_to_function

C<uri_to_function> converts an Apache2::RequestRec (or derived) object and an
array reference and returns and returns the name of a function to handle the
request it's arguments describe.

=cut

sub uri_to_function {
    my ($self) = shift;
    my ($r,$uri_bits) = @_;

    return join('_', @$uri_bits) . qq[_page];
}

=head2 index

C<index> handles requests for $r->location, and any requests that have no 
other functions defined to handle them.  You must subclass it (or look silly)

=cut

sub index {
    return (
        Apache2::Const::OK,
        qq[you might want to override "index"],
        'text/html; charset=utf-8'
    );
}

1;
