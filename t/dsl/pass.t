use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

subtest 'pass within routes' => sub {
    {

        package App;
        use Dancer2;

        get '/' => sub { 'hello' };
        get '/**' => sub {
            header 'X-Pass' => 'pass';
            pass;
            redirect '/'; # won't get executed as pass returns immediately.
        };
        get '/pass' => sub {
            return "the baton";
        };
        get '/template_extension' => sub {
          return engine('template')->default_tmpl_ext;
        };
    }

    my $app = Dancer2->runner->psgi_app;
    is( ref $app, 'CODE', 'Got app' );
    
    test_psgi $app, sub {
        my $cb = shift;

        {
            my $res = $cb->( GET '/pass' );
            is( $res->code, 200, '[/pass] Correct status' );
            is( $res->content, 'the baton', '[/pass] Correct content' );
            is(
                $res->headers->header('X-Pass'),
                'pass',
                '[/pass] Correct X-Pass header',
            );
            my $res2 = $cb->( GET '/template_extension');
            is( $res2->code, 200, '[/template_extension] Correct status' );
            is( $res2->content, 'html', '[/template_extension] Correct content' );
        }
    };

};

done_testing;
