#!/bin/bash
#
# Insert yaml from repo instead outdated steps from
# UI. That will keep output of `cf get pip` updated with
# real steps defintion when "yaml from repo" is used.

# Path to config file, required to retrieve API token
cfconfig=~/.cfconfig

# Must have before we do anything at all..
test -e "$cfconfig" || { echo "Config file is missing"; exit 1; }

# Context
ctx=$( sed -n '/^current/ s/.* \(\w\+\)/\1/p' ~/.cfconfig ) 
# Token
token=$( cat ~/.cfconfig | yq e - -o=json | jq -r ".contexts.$ctx.token" )

# Create dump file for json manipulation
dump_file=`mktemp`

# Get pipeline using same syntax as for native 'cf get pip'
eval $(echo codefresh get pip "$@" | sed 's/\<yaml\>/json/') | jq 'if type == "object" then [.] else . end' 2>/dev/null > $dump_file

#+ always store in json array to fit further processing

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

# Process each file in loop. Why not to do one loop? well.. better is verbal discussion :)
for file in ${pipelines[@]}
do
  # Initialize data needed for API call
  request_data="$( cat $file | yq eval '.spec.specTemplate' -P - )"
  # echo -e "[DEBUG] request_data:\n----------\n $request_data"

  # Expected values example
  #location=git
  #repo=olegcf/golang-sample-app
  #path=./codefresh.yml
  #revision=master
  #context=Codefresh

  # if .spec.specTemplate field was present
  if grep -qv null <<<"$request_data";
  then 
  # initialize variables
    eval $( echo "$request_data" | sed 's/: */=/' )

    # DEBUG
    #echo "location=$location"
    #echo "repo=$repo"
    #echo "path=$path"
    #echo "revision=$revision"
    #echo "context=$context"

    # Get yaml from repository
    from_repo=$( curl -s -X GET -H "Authorization: $token" https://g.codefresh.io/api/repos/${repo}/${revision}/${path#*/}?context=${context} )

    #DEBUG
    #echo "$from_repo"

    # Only the steps in json, needed by yq to substitute current value
    steps=$( echo "$from_repo" | yq -P e .content - | yq e .steps - -o=json)

    #DEBUG
    echo "$steps"

    # Append modified pipeline file output to the dump file. Remove .spec.specTemplate, rewrite
    # steps.
    cat $file | yq -P e "del(.spec.specTemplate),.spec.steps=$steps" - >> $dump_file
  else
  # if .spec.specTemplate property was not present in the pipeline, then just append file as it
    cat $file >> $dump_file
  fi
done

# This was we were successful to emulate same output as requested with the native syntax and allowing
# multi-pipeline query. [!] The only thing I can think about is to remember initial display format variable:
# json or yaml and print final output accordingly, currently we display yaml.

# Print modified pipeline(s) defition
cat $dump_file

# Remove temporary files
rm $dump_file ${pipelines[@]}
