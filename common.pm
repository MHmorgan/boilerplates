#                                                    _ 
#   ___ ___  _ __ ___  _ __ ___   ___  _ __    _ __ | |
#  / __/ _ \| '_ ` _ \| '_ ` _ \ / _ \| '_ \  | '_ \| |
# | (_| (_) | | | | | | | | | | | (_) | | | |_| |_) | |
#  \___\___/|_| |_| |_|_| |_| |_|\___/|_| |_(_) .__/|_|
#                                             |_|      
#
# My personal perl standard library, with helpers usefull
# for most scripts.
#
# Use pod2text to read the documentation. Everything here
# is documented with POD.

use 5.30.0;
use utf8;
use Term::ANSIColor qw(:constants);
use Term::ReadLine;

my $TERM = Term::ReadLine->new('common.pl');

#{{{ Misc
=encoding utf8
=cut


=head2 cmd_exists CMD → BOOL

Check if the given shell command exists.

=cut

sub cmd_exists {
    my $cmd = shift;
    my $res = system "which $cmd &>/dev/null";
    $res == 0
}


=head2 duration_str NUM → STR

Format a duration. Input is number of seconds (float or int doesn't matter).
The output format is a simple and compact.

=cut

sub duration_str {
    my $dur = int(shift);
    my $txt = sprintf "%ds", $dur % 60;
    $dur /= 60;
    return $txt if $dur < 1;
    $txt = sprintf "%dm$txt", $dur % 60;
    $dur /= 60;
    return $txt if $dur < 1;
    $txt = sprintf "%dh$txt", $dur % 24;
    $dur /= 24;
    return $txt if $dur < 1;
    return "${dur}d$txt";
}


=head2 is_repo DIR → BOOL

Check if the given directory is inside a git repository by looking for a
.git directory, either in the directory itself or one of its parents.

=cut

sub is_repo {
    my $dir = shift || die "is_repo missing directory ✗ stopping";
    $dir =~ s/\/$//;
    do {
        return 1 if -d "$dir/.git";
    } while ($dir =~ s/\/[^\/]*$//);
    return 0;
}


=head2 sendmail ARGS...

Send a mail.

Subroutine arguments:

    to      => STR
    from    => STR
    subject => STR
    message => STR
    files   => ARRAY-REF

=cut

sub sendmail {
    cmd_exists 'mailx' or die "mailx not found ✗ stopping";
    my %args = @_;
    my $to = $args{'to'}     || die "sendmail missing recipent ✗ stopping";
    my $from = $args{'from'} || die "sendmail missing sender ✗ stopping";
    my $subject = $args{'subject'} =~ s/'/\\'/r;
    #
    # Prepare attachment options. Limit attachments to a total size
    # below 8MB, as this seems to be the maximum allowed size.
    #
    my $tot_size = 0;
    my $max_size = 8_000_000;
    my $attachments = '';
    foreach (@{$args{'files'}}) {
        my $sz = (stat $_)[7];
        next if ($tot_size + $sz) > $max_size;
        $attachments .= " -a $_";
        $tot_size += $sz;
    }
    #
    # Send mail
    #
    my $cmd = "mailx -s '$subject' -r $from $attachments $to";
    open(my $mail, '|-:encoding(UTF-8)', $cmd) or die "Failed to open mailx pipe: $! ✗ stopping";
    print $mail $args{'message'};
    close $mail or die "Failed to close mailx pipe: $! ✗ stopping";
}


=head2 build_message OBJ → STR

Build a string which is inteded to be used as a mail message body.
Input is a single object which is formatted as follows:

A reference to a hash is treated as sections where the keys are
section headers and values are section content. The content objects
are recursively formatted.

A reference to an array which contains one or more references are
treated as a list of sections without headers.

A reference to an array without any references are treated as
an unordered list.

Anything else is just converted displayed as-is.

=cut 

sub build_message {
    my $arg = shift || return;
    my $lvl = shift || 0; # Header level
    my $txt = '';
    #
    # Hashes are sections with headers.
    # The keys are headers and values are content.
    #
    if (ref $arg eq 'HASH') {
        for my $title (sort keys %$arg) {
            my $content = ${$arg}{$title};
            $txt .= "\n" if $txt;
            $txt .= uc $title . "\n";
            $txt .= '=' x length($title) . "\n\n" if $lvl == 0;
            $txt .= '-' x length($title) . "\n\n" if $lvl == 1;
            $txt .= build_message($content, $lvl + 1);
        }
        return $txt;
    } 
    #
    # Arrays with references are sections without headers.
    # Arrays without any references are lists.
    #
    if (ref $arg eq 'ARRAY') {
        unless (map { ref $_ ? 1 : () } @$arg) {
            $txt .= "\n" if $txt;
            $txt .= "- $_\n" for @$arg;
        } else {
            foreach (@$arg) {
                next unless $_;
                $txt .= "\n" if $txt;
                $txt .= build_message($_);
            }
        }
        return $txt;
    }
    $arg = $$arg if ref $arg;
    chomp $arg;
    return "$arg\n";
}


=head2 get_env NAME [DEFAULT] → STR

Get an environment variable.

If the variable doesn't exist it dies, unless a default value is given.

=cut

sub get_env {
    my $name = shift || die "get_env missing variable name ✗ stopping";
    my $val = $ENV{$name} || shift;
    $val or die "environment variable '$name' not found ✗\n";
    return $val;
}


=head2 uniq ARGS... → LIST

Uniquify the argument list, returning a list without any duplicates.

=cut

sub uniq {
    my %seen;
    $seen{$_}++ for @_;
    return keys %seen;
}


=head2 timeout DUR SUB → BOOL

Run a subroutine with a timeout. DUR is the timeout duration in seconds.
SUB is the subroutine. Any return value is discarded.

C<timeout> returns true if the subroutine timed out.

=cut

sub timeout {
    my $duration = shift || die "timeout missing duration ✗ stopping";
    my $cmd = shift || die "timeout missing command ✗ stopping";
    eval {
        local $SIG{__DIE__} = undef;
        local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
        alarm $duration;
        &$cmd;
        alarm 0;
    };
    if ($@) {
        die unless $@ eq "alarm\n";   # propagate unexpected errors
        return 1;
    }
    return 0
}
#}}}


################################################################################
# User input
#{{{

=head1 User input subroutines

=head2 input PROMPT → STR

Ask the user for a single line input with the PROMPT text.

=cut

sub input {
    my $prompt = shift || die '"input" missing prompt ✗ stopping';
    print $prompt;
    chomp(my $in = <STDIN>);
    $in
}


=head2 confirm PROMPT → BOOL

Ask the user to confirm the PROMPT question. " (Y/n)" is appended to the text.

=cut

sub confirm {
    my $prompt = shift || die 'confirm missing prompt ✗ stopping';
    return $TERM->ask_yn(
        prompt => $prompt,
        default => 'y',
    );
}


=head2 choose PROMPT VALS... → VAL(S)

Ask the user to choose between the given values. In a scalar context the
user chooses one value which is returned. In a list context the user
chooses multiple values and a list of the chosen values are returned.

=cut

sub choose {
    my $prompt = shift || die 'choose missing prompt ✗ stopping';
    my @choices = @_;
    @choices > 0 or die 'choose missing values ✗ stopping';
    if (wantarray) {
        my @vals = $TERM->get_reply(
            prompt => $prompt,
            choices => \@choices,
            multi => 1,
        );
        return @vals;
    }
    my $val = $TERM->get_reply(
        prompt => $prompt,
        choices => \@choices,
    );
    return $val;
}
#}}}


################################################################################
# Printing
#{{{

#
# Text formatting
#
sub black     { BLACK     . "@_" . RESET }
sub red       { RED       . "@_" . RESET }
sub green     { GREEN     . "@_" . RESET }
sub yellow    { YELLOW    . "@_" . RESET }
sub blue      { BLUE      . "@_" . RESET }
sub magenta   { MAGENTA   . "@_" . RESET }
sub cyan      { CYAN      . "@_" . RESET }
sub white     { WHITE     . "@_" . RESET }
sub bold      { BOLD      . "@_" . RESET }
sub faint     { FAINT     . "@_" . RESET }
sub italic    { ITALIC    . "@_" . RESET }
sub underline { UNDERLINE . "@_" . RESET }

sub err  { say STDERR, red . "[!!] @_"; }
sub info { say "[*] @_"; }
sub emph { say "[↑] @_"; }
sub good { say green . "[✓] @_"; }
sub bad  { say red . "[✗] @_"; }

=head1 Printing subroutines

=head2 affirmative

Print a random affirmatie word to inspire the user. Just for fun ☆

=cut

sub affirmative {
    my @words = (
        "Amazing",
        "Awesome",
        "Beautiful",
        "Brilliant",
        "Cool",
        "Delightful",
        "Exquisite",
        "Extraordinary",
        "Fabulous",
        "Fantastic",
        "Glorious",
        "Good",
        "Gracious",
        "Jazzed",
        "Marvelous",
        "Nice",
        "Right",
        "Sensational",
        "Sweet",
        "Terrific",
        "Unique ",
    );
    my $word = $words[rand @words];
    print "$word ✓\n";
}


=head2 affirmativeln

Same as C<affirmative> with an extra trailing newline.

=cut

sub affirmativeln {
    affirmative;
    print "\n";
}


$SIG{__DIE__} = sub {
    print STDERR RED if -t STDERR;
    print STDERR "[!!] @_";
    print STDERR RESET if -t STDERR;
    exit 1
};


$SIG{__WARN__} = sub { 
    print STDERR YELLOW if -t STDERR;
    print STDERR "[!] @_";
    print STDERR RESET if -t STDERR;
};


=head2 err STR...

Print an error message to STDERR. The message is prefixed with C<[!!]>.
The message is colored red if STDERR is a terminal.

=cut

sub err {
    print STDERR RED if -t STDERR;
    print STDERR "[!!] @_\n";
    print STDERR RESET if -t STDERR;
}


=head2 info STR...

Print an info message to STDOUT. The message is prefixed with C<[*]>.

=cut

sub info {
    print "[*] @_\n"
}


=head2 header STR...

Print a header text with border with bold formatting.
The formatting is removed if STDOUT isn't a terminal.

=cut

sub header {
    my $txt = "@_";
    my $border = '=' x (length $txt);
    print BOLD if -t STDOUT;
    print "\n$txt\n$border\n\n";
    print RESET if -t STDOUT;
}

# Colored text #################################################################

=head1 Colored text subroutines

=head2 black STR...

Print text with black color.
The color is removed if STDOUT isn't a terminal.

=cut

sub black {
    print BLACK if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 red STR...

Print text with red color.
The color is removed if STDOUT isn't a terminal.

=cut

sub red {
    print RED if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 green STR...

Print text with green color.
The color is removed if STDOUT isn't a terminal.

=cut

sub green {
    print GREEN if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 yellow STR...

Print text with yellow color.
The color is removed if STDOUT isn't a terminal.

=cut

sub yellow {
    print YELLOW if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 blue STR...

Print text with blue color.
The color is removed if STDOUT isn't a terminal.

=cut

sub blue {
    print BLUE if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 magenta STR...

Print text with magenta color.
The color is removed if STDOUT isn't a terminal.

=cut

sub magenta {
    print MAGENTA if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 cyan STR...

Print text with cyan color.
The color is removed if STDOUT isn't a terminal.

=cut

sub cyan {
    print CYAN if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 white STR...

Print text with white color.
The color is removed if STDOUT isn't a terminal.

=cut

sub white {
    print WHITE if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}

# Bold text ####################################################################

=head1 Bold text subroutines

=head2 bold STR...

Print text with bold formatting.
The formatting is removed if STDOUT isn't a terminal.

=cut

sub bold {
    print BOLD if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 bblack STR...

Print text with black color and bold formatting.
The color and formatting is removed if STDOUT isn't a terminal.

=cut

sub bblack {
    print BOLD BLACK if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 bred STR...

Print text with red color and bold formatting.
The color and formatting is removed if STDOUT isn't a terminal.

=cut

sub bred {
    print BOLD RED if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 bgreen STR...

Print text with green color and bold formatting.
The color and formatting is removed if STDOUT isn't a terminal.

=cut

sub bgreen {
    print BOLD GREEN if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 byellow STR...

Print text with yellow color and bold formatting.
The color and formatting is removed if STDOUT isn't a terminal.

=cut

sub byellow {
    print BOLD YELLOW if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 bblue STR...

Print text with blue color and bold formatting.
The color and formatting is removed if STDOUT isn't a terminal.

=cut

sub bblue {
    print BOLD BLUE if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 bmagenta STR...

Print text with magenta color and bold formatting.
The color and formatting is removed if STDOUT isn't a terminal.

=cut

sub bmagenta {
    print BOLD MAGENTA if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 bcyan STR...

Print text with cyan color and bold formatting.
The color and formatting is removed if STDOUT isn't a terminal.

=cut

sub bcyan {
    print BOLD CYAN if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}


=head2 bwhite STR...

Print text with white color and bold formatting.
The color and formatting is removed if STDOUT isn't a terminal.

=cut

sub bwhite {
    print BOLD WHITE if -t STDOUT;
    print "@_";
    print RESET if -t STDOUT;
}

#}}}
