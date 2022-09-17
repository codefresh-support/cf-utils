. ~/.codefresh.sh
cf_api_key
#echo $CF_API_KEY

# my account id: 612c9a543ba6265134394298
curl --silent \
-X GET \
-H "Authorization: ${CF_API_KEY}" \
 "https://g.codefresh.io/api/accounts/612c9a543ba6265134394298/users"
