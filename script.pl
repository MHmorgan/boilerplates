#!/usr/bin/env perl5.16.3

use v5.16.3;
use utf8;
use warnings;
use open qw(:std :utf8);

use Getopt::Long;
use Pod::Usage;

BEGIN {
    push @INC, "/pri/mahi/lib";
}

use common;

sub foo {
    my ($name, $n) = @_;
    $n = 1 unless $n;
    $name = 'foo' unless $name;
    say "Hello $name!" while $n-- > 0;
}


################################################################################
#                                                                              #
# main
#                                                                              #
################################################################################

my $man = 0;
my $help = 0;
my $foo = 'foo';

GetOptions('help|h' => \$help,
           'foo'    => \$foo,
           'man'    => \$man)
or pod2usage(2);

pod2usage( -exitval  => 0,
           -verbose  => 2) if $man;
pod2usage( -verbose  => 99,
           -sections => "SYNOPSIS|Commands|OPTIONS")
if $help || !(scalar @ARGV);

sub main {
    my $cmd = shift;
    my $args = join '", "', @_;
    eval "$cmd(\"$args\")";
}

main @ARGV;


################################################################################
#                                                                              #
# Documentation
#                                                                              #
################################################################################

__END__

=head1 NAME

rogu - Roger's weird offspring.

=head1 SYNOPSIS

rogu [options] <command> [args...]

=head1 Commands

=over 8

=item B<foo> [name] [num]

Foo-greet!

=back

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut
