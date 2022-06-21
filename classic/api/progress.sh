. ~/.codefresh.sh
cf_api_key

echo $CF_API_KEY

PROGRESS_ID="$1"
curl --silent \
-X GET \
-H "Authorization: ${CF_API_KEY}" \
"https://g.codefresh.io/api/progress/${PROGRESS_ID}" | jq 
