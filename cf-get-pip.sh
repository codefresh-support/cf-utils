#!/bin/bash
#
# Append yaml from repo under .spec.specTemplates.steps. That will keep output
# of `cf get pip` updated with real steps defintion when "yaml from repo" is used.

test -n "$1" || \
  { echo "Wrapper around \`codefresh get pipeline'"; 
    echo "Run \`ccodefresh get pipeline --help' for the detailed usage message";
    #echo "In case of questions on script implementation and desired modifications contact Codefresh support."
    exit 1; 
  }

# Path to config file, required to retrieve API token
cfconfig=~/.cfconfig

# Must have before we do anything at all..
test -e "$cfconfig" || { echo "Config file is missing"; exit 1; }

# Context
ctx=$( cat ~/.cfconfig | yq e '."current-context"' -)
# Token
token=$( cat ~/.cfconfig | yq e - -o=json | jq -r ".contexts.$ctx.token" )

# Create dump file for json manipulation. Will hold initial output of `cf get pip`
dump_file=`mktemp`

# Get pipeline using same syntax as for native 'cf get pip'. Store format that pipeline was initialy requested,
# to output it properly at the end.
format=`echo $@ | sed -n 's/.*\(yaml\|json\).*/\1/p'`

# Handle the case when format was not specified
if test -z "$format" 
then 
  codefresh get pip $@
  exit
else
  # Always store command output in json array to fit further processing
  eval $(echo codefresh get pip "$@" | sed 's/'"$format"'/json/') | jq 'if type == "object" then [.] else . end' 2>/dev/null > $dump_file
fi
test -s "$dump_file" || { echo "No data retrieved"; exit 1; }
#Check this file for the dump if needed
#echo $dump_file

# Handle the case when we have multiple pipelines in dump. Each pipeline
# will be put in separate file and each filename will be added to array,
# that will allow pipelines to be processed in a loop.

declare -a pipelines    # store filenames here
length=$( jq length $dump_file )
for((i=0; i < $length; i++))
do
  pipelines[$i]=`mktemp`    # generate temporary filename
  jq ".[$i]" $dump_file > ${pipelines[$i]}  # store filename at index (i)

  #echo "[DEBUG] pipelines[$i]: ${pipelines[$i]} `jq '.metadata.name' ${pipelines[$i]}"
done

# We removing file now in order to overwrite it with modified pipelines
rm $dump_file # will be rewritten with the up-to-dated pipelines

# Process each file in loop and collect it's output in one file
for file in ${pipelines[@]}
do
  # Get data needed for API call from .spec.specTemplate
  request_data="$( cat $file | yq eval '.spec.specTemplate' -P - )"

  # if .spec.specTemplate field was present
  if grep -qv null <<<"$request_data";
  then 
  # initialize variables
    eval $( echo "$request_data" | sed 's/: */=/' )

    # Get yaml from repository
    from_repo=$( curl -s -X GET -H "Authorization: $token" https://g.codefresh.io/api/repos/${repo}/${revision}/${path#*/}?context=${context} )

    # Get only the steps in json, needed by yq to substitute current value
    steps=$( echo "$from_repo" | yq -P e .content - | yq e .steps - -o=json)

    # Append steps under .spec.specTemplate.steps
    cat $file | yq -P e ".spec.specTemplate.steps |= $steps" - >> $dump_file
  else
  # if .spec.specTemplate property was not present in the pipeline, then just append file as it
    cat $file >> $dump_file
  fi
done

# This way we were successful to emulate same output as requested with the native syntax and allowing
# multi-pipeline query.

# Print modified pipeline(s) defition with the initial format

cat $dump_file | yq -P e - -o="$format"

# Remove temporary files
rm $dump_file ${pipelines[@]}
