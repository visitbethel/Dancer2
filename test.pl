use Dancer2;

get '/' => sub {
    content_type 'text/plain';
    "HI\n";
};

dance;
