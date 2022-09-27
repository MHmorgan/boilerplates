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


################################################################################
# Text formatting

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


################################################################################
# Logging
#
# Functionality for printing logging information.
# Possibly redirected to a file, but by default to STDERR.
#
#{{{

my $LOG_OUT = *STDERR;

sub set_log_out { $LOG_OUT = shift }

sub logsay {
	@_ = colorstrip(@_) unless -t $LOG_OUT;
	say $LOG_OUT @_;
}

sub logprint {
	@_ = colorstrip(@_) unless -t $LOG_OUT;
	print $LOG_OUT @_;
}

$SIG{__DIE__} = sub { logprint red "[!!] @_"; exit 1 };
$SIG{__WARN__} = sub { logprint yellow "[!] @_" };


#
# Prefixed and colored log messages.
#
sub err  { logsay red   "[!!] @_" }
sub info { logsay       "[*] @_" }
sub emph { logsay bold  "[↑] @_" }
sub good { logsay green "[✓] @_" }
sub bad  { logsay red   "[✗] @_" }

#}}}

################################################################################
# Printing
#{{{

# Returns a random affirmative/inspiring word.
#
sub affirmative {
    my @words = (
        "Amazing", "Awesome", "Beautiful", "Brilliant", "Cool",
        "Delightful", "Exquisite", "Extraordinary", "Fabulous",
        "Fantastic", "Glorious", "Good", "Gracious", "Jazzed",
        "Marvelous", "Nice", "Right", "Sensational", "Sweet",
		"Terrific", "Unique ",
    );
    return $words[rand @words];
}


# Print a header text with border with bold formatting.
# The formatting is removed if STDOUT isn't a terminal.
#
sub header {
    my $txt = "@_";
    my $border = '=' x (length $txt);
    say bold "\n$txt\n$border\n";
}

#}}}

################################################################################
# User input
#{{{

# Ask the user for a single line input with the PROMPT text.
# 
sub input {
    my ($prompt) = @_;
    print italic($prompt);
    chomp(my $in = <STDIN>);
    $in
}


# Ask the user to confirm the PROMPT question. " (Y/n) " is appended to the text.
# Returns true if the user answers anything else than no.
# 
sub confirm {
    my ($prompt) = @_;
    my $line = input($prompt . " (Y/n) ");
	$line =~ /n(o|ei?)?/i ? 0 : 1
}


# Ask the user "Ok?", returning true if the user answers
# anything else than no.
#
sub ok {
    my $line = input("Ok? ");
    $line =~ /n(o|ei?)?/i ? 0 : 1
}

#}}}

################################################################################
# Misc
#{{{

# Check if the given shell command exists.
# 
sub cmd_exists {
    my ($cmd) = @_;
    my $res = system "which $cmd &>/dev/null";
    $res == 0
}


# Format a duration. Input is number of seconds (float or int doesn't matter).
# The output format is a simple and compact.
# 
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


# Check if the given directory is inside a git repository by looking for a
# .git directory, either in the directory itself or one of its parents.
# 
sub is_repo {
    my ($dir) = @_;
    $dir =~ s/\/$//;
    do {
        return 1 if -d "$dir/.git";
    } while ($dir =~ s/\/[^\/]*$//);
    return 0;
}


# Uniquify the argument list, returning a list without any duplicates.
# 
sub uniq {
    my %seen;
    $seen{$_}++ for @_;
    return keys %seen;
}
#}}}

