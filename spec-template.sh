. codefresh.sh
cf_api_key    # init CF_API_KEY variable
file=$1
test -n "$file" || { echo "missing pipeline spec"; exit 1; }

# Get data needed for API call from .spec.specTemplate
request_data=$( yq --prettyPrint eval '.spec.specTemplate' $file  | sed 's/: */=/;' | sed '/path/ {s,./,,; s,/,%2F,g}' )
echo "$request_data"

# if .spec.specTemplate field was present (not equal to null)
if grep -qv null <<<"$request_data";
then 
  eval "$request_data"
  echo "curl -s -X GET -H \"Authorization: $CF_API_KEY\" https://g.codefresh.io/api/repos/${repo}/${revision}/${path}?context=${context}"
  #steps=$( echo "$from_repo" | yq e .content - | yq e .steps - -o=json)
fi
