#!/usr/bin/perl

use strict;
use Test;

BEGIN { plan tests => 3 }

use Inline MzScheme => q{

(define (square x) (* x x))

(define plus_two
    (lambda (num)
            (+ num 2)))

(define cat_two
    (lambda (str)
            (string-append str "two")))

};

my $three = plus_two(1);
ok($three, 3);

my $one_two = cat_two("one");
ok($one_two, "onetwo");

my $squared = square(1.61828);
ok(substr($squared, 0, 5), 2.618);
