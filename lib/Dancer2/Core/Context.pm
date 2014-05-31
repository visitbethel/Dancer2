package Dancer2::Core::Context;

# ABSTRACT: handles everything proper to a request's context.

use Moo;
use URI::Escape;
use Carp 'croak';

use Dancer2::Core::Types;

=attr app

Reference to the L<Dancer2::Core::App> object for the current application.

=cut


has app => (
    is        => 'rw',
    isa       => InstanceOf ['Dancer2::Core::App'],
    weak_ref  => 1,
    predicate => 1,
);



1;
