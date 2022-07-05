#!/bin/bash
#
# Add &noAccount=true part
usage() { echo "`basename $0` URL"; exit 1; }
test "$1" && \
echo "$1" | sed 's/\([[:xdigit:]]\{24\}\)?\?/\1?noAccount=true/; s/true\(.\)/true\&\1/' \
 || usage
