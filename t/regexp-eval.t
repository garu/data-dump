#!perl
use strict;
use warnings;
use Test::More;
use Data::Dump qw(dump);

our $RAN;

my $   foo = 'SCALAR-SENTINEL';
my @    bar = ('ARRAY-SENTINEL');

my @sources = (
    '@{[ $main::RAN++ ]}',
    '${[ $main::RAN++ ]}',
    '${\ $main::RAN++ }',
    '@{[1]}',
    '${[1]}',
    '@{2}',
    '${2}',
    '@{ 1,2 }',
    '${ 1,2 }',
    '@[1]',
    '$[1]',
    '@{[[1]]}',
    '${[[1]]}',
    '@{{2}',
    '${{2}',
    '@foo',
    '@@bar',
    '@@@{x}',
    '@$foo',
    '@0',
    '@_',
    q{@'foo},
    '@:foo',
    '$foo',
    '$|',
    '$]',
    '$$',
    '$^W',
    '$#foo',
    '$' . '\\w',
    '$' . ('\\' x 2) . 'w',
    '$!',
    '\\@{x}',
    '\\${x}',
    ('\\' x 2) . '@{x}',
    ('\\' x 3) . '@{x}',
    ('\\' x 2) . '$foo',
    ('\\' x 3) . '$foo',
    '^foo$',
    '(a$)',
    '$',
    '$ foo',
    '$  foo',
    '$' . (' ' x 3) . 'foo',
    '$' . "\t" . 'foo',
    '$' . "\n" . 'foo',
    '$' . "\r" . 'foo',
    '$' . "\f" . 'foo',
    '$' . "\x0B" . 'foo',
    '@ bar',
    '@  bar',
    '@' . (' ' x 4) . 'bar',
    '@' . "\t" . 'bar',
    '@' . "\n" . 'bar',
    '@' . "\r" . 'bar',
    '@' . "\f" . 'bar',
    '@' . "\x0B" . 'bar',
    '@ ',
    '@-',
    '@(?:x)',
);

my %unchanged = (
    '$ '                       => 'qr/$ /',
    '$ foo'                    => 'qr/$ foo/',
    '$' . (' ' x 3) . 'foo'    => 'qr/$' . (' ' x 3) . 'foo/',
    '@ '                       => 'qr/@ /',
    '@' . (' ' x 4) . 'bar'    => 'qr/@' . (' ' x 4) . 'bar/',
    '@-'                       => 'qr/@-/',
    '@(?:x)'                   => 'qr/@(?:x)/',
);

plan tests => scalar(@sources) * 3 + 3 + scalar(keys %unchanged) + 2;

sub make_regexp {
    my $source = shift;
    local $SIG{__WARN__} = sub { };
    return qr/$source/;
}

sub eval_dump {
    my $dump = shift;
    local $SIG{__WARN__} = sub {
        warn @_ unless $_[0] =~ /Unescaped left brace|Quantifier unexpected on zero-length/;
    };
    return eval $dump;
}

for my $source (@sources) {
    my $regexp = make_regexp($source);
    local $RAN = 0;

    my $dump = dump($regexp);
    my $restored = eval_dump($dump);
    my $got = defined $restored ? "$restored" : '<undef>';

    is($@, '', "eval works for regex [$source]");
    is($RAN, 0, "no code interpolation for regex [$source]");
    is($got, "$regexp", "regex [$source] round-trips");
}

{
    my $regexp = make_regexp('@{[ $main::RAN++ ]}');
    local $RAN = 0;

    my $dump = dump({ re => $regexp });
    my $restored = eval_dump($dump);
    my $got = defined $restored && ref $restored->{re}
        ? "$restored->{re}" : '<undef>';

    is($@, '', 'eval works for nested regex');
    is($RAN, 0, 'no code interpolation for nested regex');
    is($got, "$regexp", 'nested regex round-trips');
}

is($foo, 'SCALAR-SENTINEL', 'scalar sentinel is in scope');
is("@bar", 'ARRAY-SENTINEL', 'array sentinel is in scope');

for my $source (sort keys %unchanged) {
    is(dump(make_regexp($source)), $unchanged{$source},
       "dump of [$source] is unchanged");
}
