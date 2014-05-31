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


=attr session

Handle for the current session object, if any

=cut

has session => (
    is        => 'rw',
    isa       => Session,
    lazy      => 1,
    builder   => '_build_session',
    predicate => '_has_session',
    clearer   => 1,
);

sub _build_session {
    my ($self) = @_;
    my $session;

    # Find the session engine
    my $engine = $self->app->engine('session');

    # find the session cookie if any
    if ( !$self->destroyed_session ) {
        my $session_id;
        my $session_cookie = $self->app->cookie( $engine->cookie_name );
        if ( defined $session_cookie ) {
            $session_id = $session_cookie->value;
        }

        # if we have a session cookie, try to retrieve the session
        if ( defined $session_id ) {
            eval { $session = $engine->retrieve( id => $session_id ) };
            croak "Fail to retrieve session: $@"
              if $@ && $@ !~ /Unable to retrieve session/;
        }
    }

    # create the session if none retrieved
    return $session ||= $engine->create();
}

=method has_session

Returns true if session engine has been defined and if either a session object
has been instantiated in the context or if a session cookie was found and not
subsequently invalidated.

=cut

sub has_session {
    my ($self) = @_;

    my $engine = $self->app->engine('session');

    return $self->_has_session
      || ( $self->app->cookie( $engine->cookie_name )
        && !$self->has_destroyed_session );
}

=attr destroyed_session

We cache a destroyed session here; once this is set we must not attempt to
retrieve the session from the cookie in the request.  If no new session is
created, this is set (with expiration) as a cookie to force the browser to
expire the cookie.

=cut

has destroyed_session => (
    is        => 'rw',
    isa       => InstanceOf ['Dancer2::Core::Session'],
    predicate => 1,
);

=method destroy_session

Destroys the current session and ensures any subsequent session is created
from scratch and not from the request session cookie

=cut

sub destroy_session {
    my ($self) = @_;

    # Find the session engine
    my $engine = $self->app->engine('session');

    # Expire session, set the expired cookie and destroy the session
    # Setting the cookie ensures client gets an expired cookie unless
    # a new session is created and supercedes it
    my $session = $self->session;
    $session->expires(-86400);    # yesterday
    $engine->destroy( id => $session->id );

    # Clear session in context and invalidate session cookie in request
    $self->destroyed_session($session);
    $self->clear_session;

    return;
}


1;
