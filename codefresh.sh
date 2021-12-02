############### KUBERNETES ###############

# Decode jwt token using jwt-cli package
function sa_token() {

  test "$1" || { echo "Specify a pod name"; return 1; }
  POD=$1

  # 1. Find sa used by pod
  SA=$( kubectl get pod "$POD" -o json | jq -r '.spec | .serviceAccount' )

  # 2. Find secret used by sa
  SECRET=$( kubectl get sa ${SA} -o json | jq -r '.secrets[].name' )

  # 3. Find token used by secret
  TOKEN=$(kubectl get secret $SECRET -o jsonpath="{['data']['token']}" | base64 --decode) 
  # same here
  #TOKEN=$( kubectl describe secret "$1"  | awk -F: '/^token/ {print $2}' | tr -d " " )

  jwt $TOKEN
}

# Usage: ns [get] 
# 
# Print default namespace or set namespaces. With `get' print all namespaces
function ns() {
  if [ "$1" == "get" ]
  then
    kubectl get ns
    return
  fi
  test $1 || {
    kubectl config view -o json --minify | jq '.contexts[].context.namespace';
    return;
  }
  kubectl config set-context --current --namespace "$1"
}



################ CODEFRESH ####################

# Usage: init_build_dump [PIPELINE_ID] 
#
# Set {p} and {t} to the pipeline id and 
# pipeline trigger id respectively. By default retrieve this 
# information for the last build or the last build for the specific pipeline
# passed as first argument.
function init_build_dump() {

  # Dump build to the temp file
  dump=`mktemp` # make temp file 
  cf get build ${1:+"--pid $1"} -l1 -o json > $dump

  p=`jq -r '."pipeline-Id"' $dump`
  t=`jq -r '."pipeline-trigger-id"' $dump`

  #DEBUG 
  #echo -e "p: $p\nt: $t"
  rm $dump
}

# Usage: get_trigger [PIPELINE_ID] [TRIGGER_ID]
#
# Get specific trigger for the specific pipeline. If trigger id is missing
# call ot init_build_dump() to find it's value. By default operate on the last build
# or the last build for the specified pipeline.
function get_trigger() {
  p="$1"; t="$2" # assume that values are initialized 
  test -n "$2" || init_build_dump "$1"
  echo "p: $p"
  echo "t: $t"
  # Accept one or two values
  cf get pipeline ${p} -o json | jq '.spec.triggers[] | select(contains({"id": "'$t'"}))' 
}

# Always set PIPID to the last searched pipeline. history will be parsed for the 
# latest 'cf get pip' pattern. It is usefull when you need to reuse value of the found
# pipeline in the few consequent commands.
function pipid() {
  PIPID=$( eval $( history | awk '/[0-9]+ +cf get pip/ {print}' | tail -n1 |\
                                     sed 's/[0-9]\+//; s/\(-o *.*\)\?$/ -o id/' ) )

  #PIP_NAME=$( cf get pip $PIP_ID -o json | jq '.metadata.name' )
}


# Usage: cf_token [CONTEXT_NAME]
#
# Get token for the specific or current context
function cf_token() {
#  if [ -z $1 ]; then
    ctx=$(cf_ctx) # get current context name
  #else
    #ctx=$1
  #fi
  #exit
  cfconfig=${1:-~/.cfconfig}
  #echo "$cfconfig"
  cat $cfconfig | yq e ".contexts.$ctx.token" - | tr -d \"
}

# Set CF_API_KEY with the token of the specified or current context
function cf_api_key() {
  export CF_API_KEY=$( cf_token $1 )
}

# Wrapper around jq(1). Without arguments or when dot is added at the very
# end display only the keys of the specific object/array.
#
# Useful for quick reviewing on the json file. I.e:
#
# cat pipeline.json | keys    # only top level keys
# cat pipeline.json | keys spec   # all the values under .spec
# cat pipeline.json | keys spec.steps.   # only keys under steps, note the "dot"
function keys() {
  if [ $# -eq 0 ]
  then
    cmdline="keys"
  else
    cmdline="`echo "$*" | sed 's/\(^\| \)/./g; s/\. *$/\| keys/;'`"
  fi
  echo "$cmdline"
  jq "$cmdline"
}


################# Aliases

# Return only name of the current context:
alias cf_ctx="cf auth current-context | tail -n1 | awk '{print \$2}'"

# json stuff
alias jvim='vim -c "set ft=json" -'
alias json='jq -C . | less -r'
alias tojson='yq e - -o=json'
alias lsjson='ls *.json -l'
alias rmjson='rm *.json'
alias gp='k get pods'
alias gs='k get svc'
alias labels='jq .metadata.labels'
