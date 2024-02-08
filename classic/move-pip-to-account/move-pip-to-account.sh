#!/bin/bash

src_prj=$1 
dest_prj=$2 
src_ctx=$3 
dest_ctx=$4

sp=${src_ctx}_${src_prj}.json
dp=${dest_ctx}_${dest_prj}.json

codefresh auth use-context $src_ctx || { exit 1; }

echo "Storing source pipeline data to $sp from project '$src_prj'"
codefresh get pip --project $src_prj -o json > $sp

codefresh auth use-context $dest_ctx || { exit 1; }
echo "Checking if project '$dest_prj' exists"

codefresh get project $dest_prj &>/dev/null && { echo "Project exists, continuing..."; } || \
  {  echo "Creating project '$dest_prj'"; codefresh create project $dest_prj; }

dpID=$(codefresh get project $dest_prj -o json | jq -r '.id')

# make variables accessible in jq(1)
export accountId src_prj dest_prj dpID

echo "store destination pipeline data to $dp from project '$dest_prj'"
cat $sp | \
jq 'map(.metadata.name |= sub("'"${src_prj}"'"; "'"${dest_prj}"'") | .metadata = { "name": .metadata.name } | .metadata += { "project": "'"${dest_prj}"'", "projectId": "'"${dpID}"'"})' - > $dp

echo "Creating pipelines in project '$dest_prj' from $dp file..."
jq -c '.[]' $dp | while read -r line; do
  echo $line > temp.json
  codefresh create pip -f temp.json || { echo "Creation failed"; exit; }
  sleep .002
done
rm temp.json

echo ""
echo "Original pipeline defitions are kept under '$sp' file. Do not delete it until you"
echo "verify that all the pipelines transferred correctly."
echo ""
echo "Original pipelines are still in desitnation project, you may want to delete them"
echo "manually if you are sure that the transfer was successful"
echo ""
echo "You may want to verify triggers and other items to make sure they are working correctly."