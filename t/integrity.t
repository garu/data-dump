#!perl

use strict;
use warnings;
use Test qw(plan ok);
plan tests => 1;

use Data::Dump qw(dump);

use utf8;
my $data = { x => 'infтест' };

my $output = dump($data);
ok($output, dump($data));
