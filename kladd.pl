#!/usr/bin/env perl

use v5.30.0;
use utf8;
use strict;
use warnings;

BEGIN { push @INC, "$ENV{HOME}/lib"; }

use open qw(:std :utf8);
use common;
use Getopt::Long;

my $EDITOR = $ENV{EDITOR} // 'nvim';
my $DIR = "$ENV{HOME}/.local/share/kladd";

my $_BRANCH_STR     = qx{ git symbolic-ref --quiet HEAD 2>/dev/null } =~ s/.*\///r;
my $_DIRECTORY_STR  = $ENV{PWD} =~ s/.*\///r;
chomp($_BRANCH_STR, $_DIRECTORY_STR);

my $HELP = !(scalar @ARGV);
my $LIST = 0;
my $REMOVE = 0;
my $DUMP = 0;
my $DIRECTORY = 0;
my $BRANCH = 0;

GetOptions(
    'help|h' => \$HELP,
    'dump|d' => \$DUMP,
    'branch|b' => \$BRANCH,
    'dir' => \$DIRECTORY,
    'ls' => \$LIST,
    'rm' => \$REMOVE,
);


my $NAME = shift;
if ($BRANCH) {
    die "Git branch not found.\n"
        unless $_BRANCH_STR;
    $NAME .= '-' if $NAME;
    $NAME .= $_BRANCH_STR;
}
if ($DIRECTORY) {
    die "Cannot make a kladd for this dir.\n"
        unless $_DIRECTORY_STR;
    $NAME .= '-' if $NAME;
    $NAME .= $_DIRECTORY_STR;
}


if ($HELP) {
    print while (<DATA>);
    exit;
}


system "mkdir -p $DIR";
chdir $DIR or die $!;
exec "ls -1 | sort" if $LIST;

exec "$EDITOR $NAME" unless $REMOVE || $DUMP;

-f $NAME or die qq(Kladd "$NAME" not found);
exec "rm $NAME" if $REMOVE;
exec "cat $NAME" if $DUMP;


__DATA__
Usage: kladd [option] [NAME]

Edit the named kladd.

Options:
    -rm     Remove kladd NAME.
    -ls     List all kladder.
    -dump   Dump the content of a kladd.
    -branch Make the kladd unique for the current git branch.
    -dir    Make the kladd unique for the current directory.