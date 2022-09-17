. ~/.codefresh.sh
cf_api_key
#echo $CF_API_KEY
CF_ACCOUNT_ID=612c9a543ba6265134394298
curl --silent \
-X GET \
-H "Authorization: ${CF_API_KEY}" \
"https://g.codefresh.io/api/accounts/${CF_ACCOUNT_ID}/users"
