. ~/.codefresh.sh
cf_api_key
ID=$1
#echo $CF_API_KEY
curl --silent \
-X GET \
-H "Authorization: ${CF_API_KEY}" \
    "https://g.codefresh.io/api/pipelines/names?id=${ID}"


# WOW!!!!!  convert to ${CONSTRUCT:-}
    #"https://g.codefresh.io/api/pipelines/names?offset=${OFFSET}&id=${ID}&limit=${LIMIT}&labels=${LABELS}&projectId=${PROJECT_ID}"
