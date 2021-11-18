#!/bin/bash
#retrieve pipeline spec from Git
#
# [*] handle yq not installed

cfconfig=~/.cfconfig
test -e "$cfconfig" || { echo "Config file is missing"; exit 1; }
ctx=$( sed -n '/^current/ s/.* \(\w\+\)/\1/p' ~/.cfconfig ) 
#echo $ctx
token=$( cat ~/.cfconfig | yq e - -o=json | jq -r ".contexts.$ctx.token" )

#echo $token
curl -s  \
    -X GET \
    -H "Authorization: $token" \
    "https://g.codefresh.io/api/repos/olegcf/cf-example-unit-tests-with-composition?context=Codefresh"
