#!/bin/bash
#
# Get yaml from repo under .spec.specTemplates.steps. That will keep output
# of `cf get pip` updated with real steps defintion when "yaml from repo" is used.

test -n "$1" || \
  { echo "Wrapper around \`codefresh get pipeline'"; 
    echo "Run \`codefresh get pipeline --help' for the available options";
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
token=$( cat ~/.cfconfig | yq e ".contexts.$ctx.token" -  | tr -d \" ) 

# Create dump file for json manipulation. Will hold initial output of `cf get pip`
dump_file=`mktemp --tmpdir=. -t .XXXXXX`

# Keep original format
format=`echo $@ | sed -n 's/.*-o *\(yaml\|json\).*/\1/p'`

# If format was not specified no steps are dumped, conform with original command
if test -z "$format" 
then 
  codefresh get pip $@
  exit
fi

# Run the command and store output in json array to fit further processing
eval $(echo codefresh get pip "$@" | sed 's/'"$format"'/json/') | jq 'if type == "object" then [.] else . end' 2>/dev/null > $dump_file

# Fail if no data was retrieved
test -s "$dump_file" || { echo "No data was retrieved"; rm $dump_file;  exit 1; }

#Check this file for the dump if needed
#echo $dump_file

# Iterate through pipeline id's and operate on corresponding blocks of definition within single file
for id in $( cat $dump_file | yq eval '.[].metadata.id' - )
do
  # Get data needed for API call from .spec.specTemplate
  request_data=$( yq --prettyPrint eval '.[] | select(.metadata.id == "'$id'").spec.specTemplate' $dump_file )
  
  # if .spec.specTemplate field was present
  if grep -qv null <<<"$request_data";
  then 
  # initialize variables for the call
    eval $( echo "$request_data" | sed 's/: */=/;' | sed '/path/ {s,./,,; s,/,%2F,g}' )

    # Get yaml from repository
    from_repo=$( curl -s -X GET -H "Authorization: $token" https://g.codefresh.io/api/repos/${repo}/${revision}/${path/}?context=${context} )

    # Get only the steps in json
    steps=$( echo "$from_repo" | yq e .content - | yq e .steps - -o=json)

    # Write steps under .spec.specTemplate.steps
    yq -P -i e '( .[] | select(.metadata.id == "'$id'").spec.specTemplate.steps |= '"$steps"') | [.]' $dump_file
  fi
done

# When multiline pipelines, put them under items array; conforming to the `cf get pip -o yaml` output
if [ `yq eval length $dump_file` -gt 1 ]
then
  if [ $format = yaml ]
  then
    yq -P -i e '. = {"items": .}'  $dump_file 
  fi
  # no modification is needed for json
else
  # when single pipeline, remove it from the array
  yq -i e '.[]' $dump_file
fi

# Print out up-to-dated pipelines
yq -P e . -o=$format $dump_file 

# Remove temporary files
rm $dump_file 
