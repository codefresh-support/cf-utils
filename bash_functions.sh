#### Few functions for easier life ####

#  
# Usage: [GREP_OPTS] dir [DIR] [DEPTH] EXPR
#
# find(1) wrapper, displays filenames in which pattern was found. Searched is
# performed only in the current directory unless "max" specified. 
# 
# Instead of writing:
#   find . -maxdepth 1 -type f -exec grep -ln {} -e pattern \; 
#
# you just do: 
#   dir pattern
#     
#
# Note the options to grep(1). It can be changed by passing another values
# explicitly on the command line by prepending command with grep_opts=
#
# DIR, DEPTH AND PATTERN can be passed in any order. Only PATTERN is mandatory. 
# Special value of "max" for DEPTH will cause search to recurse to the directories.

grep_opts="--color --with-filename --line-number";
function dir() 
{ 
  # Accept asterisk '*' for any depth
  test -n "$GREP_OPTS" && grep_opts=$GREP_OPTS
  # Must by delcared as such, otherwise they retain values after a call
  declare ERROR
  
  if [ $# -gt 3 ]; then
    echo "Excess number of arguments specified" >&2 
    ((ERROR++)) 
  elif [  $# -eq 0 ]; then
    echo "Search pattern must be specified!" >&2;
    ((ERROR++)) 
  fi
  test -z "$ERROR" || { echo "Usage: [grep_opts] dir [DIR] [DEPTH] EXPR" >&2; \
                        return 1; }
  expr=${!#}
  while [ $# -gt 1 ]
  do
    if test $1 = 'max'
    then
      depth='300' 
    elif test -e $1; then
      dir=$1
    else
      depth=$1
    fi
    shift;
  done;
#  echo "dir: $dir"
#  echo "depth: $depth"
#  echo "expr: $expr"
# return 2
  #echo "find ${dir:-.} -maxdepth ${depth:-1} -type f -exec grep ${grep_opts} {} -e \"$expr\" \;"
  find ${dir:-.} -maxdepth ${depth:-1} -type f -exec grep ${grep_opts} {} -e "$expr" \;
}
