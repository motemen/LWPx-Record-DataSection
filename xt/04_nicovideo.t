use strict;
use Test::More;
use LWPx::Record::DataSection {
    record_response_header => [ qw(Set-Cookie X-Niconico-Authflag) ], 
    record_request_cookie  => [ 'user_session' ],
};

BEGIN { *CORE::GLOBAL::time = sub { 1298029590 } }

use WWW::NicoVideo::Download;
use Config::Pit;

my $config = pit_get('nicovideo.jp');
my $nicovideo = WWW::NicoVideo::Download->new(
    email => $config->{username},
    password => $config->{password},
);
ok my $url = $nicovideo->prepare_download('sm13465059');

done_testing;
