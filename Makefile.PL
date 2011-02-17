use inc::Module::Install;

name 'Test-Fake-LWP';
all_from 'lib/Test/Fake/LWP.pm';

requires 'Data::Section::Simple';
requires 'HTTP::Response';
requires 'LWP::Protocol';
requires 'LWP::UserAgent';
requires 'Carp';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

auto_set_repository;
auto_include;

WriteAll;
