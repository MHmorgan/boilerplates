#!/usr/bin/env perl
#
#  _____           
# |  ___|__   ___  
# | |_ / _ \ / _ \ 
# |  _| (_) | (_) |
# |_|  \___/ \___/ 
#                  

use v5.30.0;
use utf8;
use strict;
use warnings;

use open qw(:std :utf8);
use common;
use Getopt::Long;


my $HELP = !(scalar @ARGV);
my $VERBOSE = 0;

GetOptions(
    'help|h'    => \$HELP,
    'verbose|v' => \$VERBOSE,
);

if ($HELP) {
    print while (<DATA>);
    exit;
}


sub foo {
    my ($name, $n) = @_;
    $n = 1 unless $n;
    $name = 'foo' unless $name;
    say "Hello $name!" while $n-- > 0;
}


say "Hello world!";
say "Suddenly the cave collapses!" if $VERBOSE;


__DATA__
 ___         
| __|__  ___ 
| _/ _ \/ _ \
|_|\___/\___/
             
Usage: foo [-v] [-h]

Do something cool!

