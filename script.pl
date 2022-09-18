#!/usr/bin/env perl5.30

use v5.30.0;
use utf8;
use warnings;
use open qw(:std :utf8);

use Getopt::Long;
use Pod::Usage;

BEGIN {
    push @INC, "$ENV{HOME}/lib";
}

use common;

sub foo {{{
    my ($name, $n) = @_;
    $n = 1 unless $n;
    $name = 'foo' unless $name;
    say "Hello $name!" while $n-- > 0;
}}}


################################################################################
# main
#{{{

my $MAN = 0;
my $HELP = 0;
my $FOO = 'foo';

GetOptions('help|h' => \$HELP,
           'foo'    => \$FOO,
           'man'    => \$MAN)
or pod2usage(2);

pod2usage( -exitval  => 0,
           -verbose  => 2) if $MAN;
pod2usage( -verbose  => 99,
           -sections => "SYNOPSIS|Commands|OPTIONS")
if $HELP || !(scalar @ARGV);

sub main {{{
    my $cmd = shift;
    my $args = join '", "', @_;
    my $res = eval "$cmd(\"$args\")";
	say $res if defined $res;
}}}

main @ARGV;
#}}}


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
