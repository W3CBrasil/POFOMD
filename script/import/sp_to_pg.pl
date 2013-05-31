#!/usr/bin/perl

use strict;
use warnings;
use FindBin '$Bin';

if (scalar @ARGV < 2) {
    exec 'perl', "-I$Bin/../../lib", "$Bin/sp.pl", '--usage';
}

exec 'perl', "-I$Bin/../../lib", "$Bin/sp.pl", '--year', $ARGV[0], '--dataset', $ARGV[1];
