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
use strict;
use warnings;
use utf8;
use Term::ANSIColor qw(:constants colorstrip);
use Term::ReadLine;

#{{{ Misc

# cmd_exists CMD → BOOL
# 
# Check if the given shell command exists.
# 
sub cmd_exists {{{
    my $cmd = shift;
    my $res = system "which $cmd &>/dev/null";
    $res == 0
}}}


# duration_str NUM → STR
# 
# Format a duration. Input is number of seconds (float or int doesn't matter).
# The output format is a simple and compact.
# 
sub duration_str {{{
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
}}}


# is_repo DIR → BOOL
# 
# Check if the given directory is inside a git repository by looking for a
# .git directory, either in the directory itself or one of its parents.
# 
sub is_repo {{{
    my $dir = shift || die "is_repo missing directory ✗ stopping";
    $dir =~ s/\/$//;
    do {
        return 1 if -d "$dir/.git";
    } while ($dir =~ s/\/[^\/]*$//);
    return 0;
}}}


# sendmail ARGS...
# 
# Send a mail.
# 
# Subroutine arguments:
# 
#     to      => STR
#     from    => STR
#     subject => STR
#     message => STR
#     files   => ARRAY-REF
# 
sub sendmail {{{
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
}}}


# build_message OBJ → STR
# 
# Build a string which is inteded to be used as a mail message body.
# Input is a single object which is formatted as follows:
# 
# A reference to a hash is treated as sections where the keys are
# section headers and values are section content. The content objects
# are recursively formatted.
# 
# A reference to an array which contains one or more references are
# treated as a list of sections without headers.
# 
# A reference to an array without any references are treated as
# an unordered list.
# 
# Anything else is just converted displayed as-is.
# 
sub build_message {{{
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
}}}


# get_env NAME [DEFAULT] → STR
# 
# Get an environment variable.
# 
# If the variable doesn't exist it dies, unless a default value is given.
# 
sub get_env {{{
    my $name = shift || die "get_env missing variable name ✗ stopping";
    my $val = $ENV{$name} || shift;
    $val or die "environment variable '$name' not found ✗\n";
    return $val;
}}}


# uniq ARGS... → LIST
# 
# Uniquify the argument list, returning a list without any duplicates.
# 
sub uniq {{{
    my %seen;
    $seen{$_}++ for @_;
    return keys %seen;
}}}


# timeout DUR SUB → BOOL
# 
# Run a subroutine with a timeout. DUR is the timeout duration in seconds.
# SUB is the subroutine. Any return value is discarded.
# 
# timeout returns true if the subroutine timed out.
# 
sub timeout {{{
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
}}}
#}}}


################################################################################
# User input
#{{{

# input PROMPT → STR
# 
# Ask the user for a single line input with the PROMPT text.
# 
sub input {{{
    my $prompt = shift || die '"input" missing prompt ✗ stopping';
    print $prompt;
    chomp(my $in = <STDIN>);
    $in
}}}


# confirm PROMPT → BOOL
# 
# Ask the user to confirm the PROMPT question. " (Y/n)" is appended to the text.
# 
sub confirm {{{
    my $prompt = shift || die 'missing prompt. Stopping';
    my $line = input($prompt . " (Y/n)");
	$line =~ /n(o|ei?)?/i ? 0 : 1
}}}
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


#
# Printing functions which properly handles terminals.
#
sub echo {{{
	@_ = colorstrip(@_) unless -t STDOUT;
	say @_;
}}}
sub eecho {{{
	@_ = colorstrip(@_) unless -t STDERR;
	say STDERR @_;
}}}


#
# Prefixed printing functions.
#
sub err  { eecho red  "[!!] @_"; }
sub info { echo "[*] @_"; }
sub emph { echo "[↑] @_"; }
sub good { echo green "[✓] @_"; }
sub bad  { echo red "[✗] @_"; }


#
# Print a random affirmatie word to inspire the user. Just for fun ☆
#
sub affirmative {{{
    my @words = (
        "Amazing", "Awesome", "Beautiful", "Brilliant", "Cool",
        "Delightful", "Exquisite", "Extraordinary", "Fabulous",
        "Fantastic", "Glorious", "Good", "Gracious", "Jazzed",
        "Marvelous", "Nice", "Right", "Sensational", "Sweet",
		"Terrific", "Unique ",
    );
    my $word = $words[rand @words];
    print "$word ✓\n";
}}}


$SIG{__DIE__} = sub {{{
    print STDERR RED if -t STDERR;
    print STDERR "[!!] @_";
    print STDERR RESET if -t STDERR;
    exit 1
}}};


$SIG{__WARN__} = sub {{{ 
    print STDERR YELLOW if -t STDERR;
    print STDERR "[!] @_";
    print STDERR RESET if -t STDERR;
}}};


# header ARG...
#
# Print a header text with border with bold formatting.
# The formatting is removed if STDOUT isn't a terminal.
#
sub header {{{
    my $txt = "@_";
    my $border = '=' x (length $txt);
    echo bold "\n$txt\n$border\n\n";
}}}
#}}}
