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

echo $CF_API_KEY

i=1
while [ "1" ]; do
pagination=`curl --silent  -X GET  -H "Authorization: ${CF_API_KEY}" -H 'X-Pagination-Session-Id: codefresh-oleg'  "http://g.codefresh.io/api/workflow?limit=12&page=$i&after=2022-01-01&before=2022-05-02" | jq ".pagination"`
echo "$((++i))"
echo "i=$i"
echo "$pagination"
if echo "$pagination" | jq ".nextPage" | grep -i true -q; then
   echo "$pagination" | jq ".page"
else
  break
fi
done

#-H "Authorization: ${CF_API_KEY}" -H 'X-Pagination-Session-Id: codefresh-oleg'  "http://g.codefresh.io/api/workflows?limit=12&before=2022-05-02&after=2022-05-01"

#"https://g.codefresh.io/api/workflow?limit=${LIMIT}&page=${PAGE}&status=${STATUS}&trigger=${TRIGGER}&pipeline=${PIPELINE}&provider=${PROVIDER}&repoName=${REPO_NAME}&repoOwner=${REPO_OWNER}&revision=${REVISION}&branchName=${BRANCH_NAME}&pipelineTriggerId=${PIPELINE_TRIGGER_ID}&committer=${COMMITTER}"
