#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::Installed;

my $inst = ExtUtils::Installed->new();
my @modules = $inst->modules();

for (@modules)
{
    print $_ . " " . $inst->version ($_)."\n";
}



