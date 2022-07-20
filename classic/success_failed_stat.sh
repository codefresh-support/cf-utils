#!/bin/bash
#
# Call to api/workflow endpoint and gets statuses of the builds of specific pipeline

usage() {
  echo "Usage: `basename $0` [--from=YYYY-MM-DD] [--to=YYYY-MM-DD] PIPELINE_ID"
}
test $# -eq 0 && usage

while [ "1" ]; do
  ((PAGE++))
  result=$(codefresh get builds --limit 20 $* --page $PAGE --sc created,status )
  #echo "$PAGE A"
  grep -q "no available resources" <<<$result && break
  builds=$( echo -e "$builds\n" "$result" | sed '/^$/d; /CREATED/d' )
done
echo "$builds"

