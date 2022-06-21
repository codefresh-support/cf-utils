#!/bin/bash
# https://g.codefresh.io/api/#operation/workflows-list
#
# Call to api/workflows

usage() {
  echo "Usage: `basename $0`"
  exit
}

# Source somewhat usefull functions
. ~/.codefresh.sh
cf_api_key  #&> /dev/null

before=$(date -d "2 month ago" --iso-8601=seconds | sed 's/+/%2B/') 
echo "before=$before"

#BUILD_ID="$1"; test -n "$1" || usage;
echo $CF_API_KEY
#exit
curl --silent \
-X GET \
-H "Authorization: ${CF_API_KEY}" \
   "http://g.codefresh.io/api/workflows?before=${before}&limit=100&page=1"

#"https://g.codefresh.io/api/workflow?limit=${LIMIT}&page=${PAGE}&status=${STATUS}&trigger=${TRIGGER}&pipeline=${PIPELINE}&provider=${PROVIDER}&repoName=${REPO_NAME}&repoOwner=${REPO_OWNER}&revision=${REVISION}&branchName=${BRANCH_NAME}&pipelineTriggerId=${PIPELINE_TRIGGER_ID}&committer=${COMMITTER}"
