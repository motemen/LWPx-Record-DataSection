package Test::Fake::LWP;
use strict;
use warnings;
use LWP::Protocol;
use HTTP::Response;
use Data::Section::Simple;

our $VERSION = '0.01';

our $Data;
our ($Pkg, $File, $Fh);

sub import {
    my $class = shift;
    if (defined $Pkg) {
        require Carp;
        Carp::croak("only one class can use $class");
    }
    ($Pkg, $File) = caller;
}

INIT {
    $Data = Data::Section::Simple->new($Pkg)->get_data_section;
    unless (defined $Data) {
        __PACKAGE__->append_to_file("\n__DATA__\n\n");
    }
    LWP::Protocol::Fake->fake;
}

sub append_to_file {
    my $class = shift;
    unless ($Fh && fileno $Fh) {
        open $Fh, '>>', $File or die $!;
    }
    print $Fh @_;
}

sub request_to_key {
    my ($class, $req) = @_;
    return join ' ', $req->method, $req->uri;
}

sub restore_response {
    my ($class, $req) = @_;

    my $key = $class->request_to_key($req);
    if (my $string = $Data && $Data->{$key}) {
        $string =~ s/\n\z//;
        my $res = HTTP::Response->parse($string);
        $res->request($req);
        return $res;
    }
}

sub store_response {
    my ($class, $res, $req) = @_;
    my $key = $class->request_to_key($req);
    $class->append_to_file("@@ $key\n");
    $class->append_to_file($res->as_string("\n"), "\n");
}

package #
    LWP::Protocol::Fake;

our $ORIGINAL_LWP_Protocol_create = \&LWP::Protocol::create;

sub fake {
    my $class = shift;
    no warnings 'redefine';
    *LWP::Protocol::create = sub { LWP::Protocol::Fake->new(@_) };
}

sub new {
    my ($class, $scheme, $ua) = @_;
    bless { scheme => $scheme, ua => $ua, real => &$ORIGINAL_LWP_Protocol_create($scheme, $ua) }, $class;
}

sub request {
    my ($self, $request, $proxy, $arg, $size, $timeout) = @_;

    if (my $res = Test::Fake::LWP->restore_response($request)) {
        return $res;
    } else {
        my $res = $self->{real}->request($request, $proxy, $arg, $size, $timeout);
        Test::Fake::LWP->store_response($res, $request);
        return $res;
    }
}

1;

__END__

=head1 NAME

Test::Fake::LWP - Fake LWP response from __DATA__ section

=head1 SYNOPSIS

  use Test::More;
  use Test::Fake::LWP;
  use LWP::Simple qw($ua);

  my $res = $ua->get('http://www.example.com/'); # does not access to the internet actually
  is $res->code, 200;

  __DATA__

  @@ GET http://www.example.com/
  HTTP/1.0 200 OK
  Content-Type: text/html
  ... # HTTP response

=head1 DESCRIPTION

Test::Fake::LWP overrides LWP::Protocol and creates response object from __DATA__ section.
The response should be recorded as below:

  __DATA__

  @@ [method] [url]
  [raw response]

  @@ [method] [url]
  [raw response]

  ...

=head1 RECORDING RESPONSES

When LWP try to send request without corresponding data section,
Test::Fake::LWP allows actual connection and records the response to the test file's __DATA__ section.

Example:

  # test.t
  use strict;
  use Test::More;
  use Test::Fake::LWP;
  use LWP::Simple qw($ua);

  my $res = $ua->get('http://www.example.com/');
  is $res->code, 200;

  # No __END__ please, Test::Fake::LWP confuses
  __DATA__

Running this test appends the actual response to the test file itself, thus produces such:

  # test.t
  use strict;
  use Test::More;
  use Test::Fake::LWP;
  use LWP::Simple qw($ua);

  my $res = $ua->get('http://www.example.com/');
  is $res->code, 200;

  # No __END__ please, Test::Fake::LWP confuses
  __DATA__
  @@ GET http://www.example.com/
  HTTP/1.0 302 Found
  Connection: Keep-Alive
  Location: http://www.iana.org/domains/example/
  ...
  
  @@ GET http://www.iana.org/domains/example/
  HTTP/1.1 200 OK
  ...

After that running the test does not require internet connection.

=head1 CAVEATS

If the file contains __END__ section, storing respnose will not work.

__DATA__ section key does not contain POST parameters, etc. (this is in TODO)

=head1 TODO

Make available to use other parameters for keys.

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
