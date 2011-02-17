use inc::Module::Install;

name 'Test-Fake-LWP';
all_from 'lib/Test/Fake/LWP.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

auto_set_repository;
auto_include;

WriteAll;
