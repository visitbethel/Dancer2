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
        
        get '/appindex' => sub {
          return template 'index';
        };
        
        get '/appviewspartial' => sub {
          return template 'views/partial';
        };
    }

    my $app = Dancer2->runner->psgi_app;
    is( ref $app, 'CODE', 'Got app' );
    
    ok( -f 'app/index.html', 'template index is here');
    ok( -f 'app/views/partial.html', 'template views/partial is here');
    
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

            my $res3 = $cb->( GET '/appindex');
            is( $res3->code, 200, '[/appindex] Correct status' );
            is( $res3->content, 'INDEX', '[/appindex] Correct content' );

            my $res4 = $cb->( GET '/appviewspartial');
            is( $res4->code, 200, '[/appviewspartial] Correct status' );
            is( $res4->content, 'PARTIAL', '[/appviewspartial] Correct content' );
        }
    };

};

done_testing;
