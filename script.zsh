#!/usr/bin/env zsh
# vim: expandtab:
#
#  _____           
# |  ___|__   ___  
# | |_ / _ \ / _ \ 
# |  _| (_) | (_) |
# |_|  \___/ \___/ 
#                  

source ~/lib/common.zsh

zparseopts -D \
    h=HELP -help=HELP \
    q=QUIET -quiet=QUIET


[[ -n "$HELP" ]] && cat <<EOF
Usage: foo [options]

Options:
    --help -h
            Print this help message.
    --quiet -q
            Print less output.
EOF

