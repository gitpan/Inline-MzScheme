#!/usr/bin/perl

use strict;
use inc::Module::Install;

name('Inline-MzScheme');
version_from('lib/Inline/MzScheme.pm');
abstract_from('lib/Inline/MzScheme.pm');
author('Autrijus Tang <autrijus@autrijus.org>');
license('perl');
requires(qw(
    Inline              0.43
    Language::MzScheme  0.03
));
can_cc() or die "This module requires a C compiler";

WriteAll( sign => 1 );
