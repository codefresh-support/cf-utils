. ~/.codefresh.sh
cf_api_key
#echo $CF_API_KEY
curl --silent \
-X GET \
-H "Authorization: ${CF_API_KEY}" \
"https://g.codefresh.io/api/accounts/${CF_ACCOUNT_ID}/users"
