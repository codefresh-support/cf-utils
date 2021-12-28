#!/bin/bash
# 
# Unit test of cf_api_key() function (sourced from codefresh.sh)

. ../codefresh.sh

report_token() {
  var=$1
  echo "$var: ${!var}"
}

report_token CF_API_KEY
cf_api_key
report_token CF_API_KEY
