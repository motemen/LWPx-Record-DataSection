use strict;
use Test::More;

eval q{
    use Test::TCP;
    use File::Temp;
    use Plack::Loader;
};

plan skip_all => "Could not load modules: $@" if $@;
plan tests => 6;

my $count = 0;
my $app = sub {
    my $env = shift;
    $count++;
    if ($env->{PATH_INFO} eq '/') {
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ "hello ($count)" ] ];
    } elsif ($env->{PATH_INFO} eq '/newline') {
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ "hello ($count)\n" ] ];
    } elsif ($env->{PATH_INFO} eq '/redirect') {
        return [ 302, [ 'Content-Type' => 'text/plain', Location => '/' ], [ ] ];
    }
};

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $server = Plack::Loader->auto(port => $port, host => '127.0.0.1');
        $server->run($app);
    }
);

my ($fh, $filename) = File::Temp::tempfile();
print $fh do { local $/; scalar <DATA> };
close $fh;

sub run_script {
    my $path = shift || '';
    my @command = ($^X, map("-I$_", @INC), $filename, $server->port, $path);
    return `@command`;
}

is run_script(''), "hello (1)", 'server response';
is run_script(''), "hello (1)", 'server response (stored)';

is run_script('newline'), "hello (2)\n", 'server response w/newline';
is run_script('newline'), "hello (2)\n", 'server response w/newline (stored)';

is run_script('redirect'), "hello (1)", 'server response redirect';
is run_script('redirect'), "hello (1)", 'server response redirect (stored)';

open my $fh, '<', $filename;
note <$fh>;

__DATA__
#!perl
use strict;
use LWPx::Record::DataSection;
use LWP::Simple qw($ua);

my ($port, $path) = @ARGV;

my $res = $ua->get("http://127.0.0.1:$port/$path");
print $res->content;
