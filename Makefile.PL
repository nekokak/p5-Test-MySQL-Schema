use inc::Module::Install;
name 'Test-MySQL-Schema';
all_from 'lib/Test/MySQL/Schema.pm';

#requires '';

test_requires 'Test::More' => '0.94';

tests 't/*.t t/*/*.t';
author_tests('xt');

auto_set_repository;

WriteAll;
