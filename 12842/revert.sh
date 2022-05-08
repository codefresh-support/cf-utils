#!/bin/bash
#
# Set tags from items.json or items.yaml generated with `codefresh get pipelines -o ...`

test -e "$1" || \ { 
  echo "Usage: `basename $0` ITEMS_FILE";
  echo "Pass it a file generated previously with \`codefresh get pipeline' to";
  echo "restore the tags. ";
  exit 1; 
  }
items_file="$1"
# iterate over pipelines
for id in $(cat $items_file | yq e ".items[].metadata.id")
do
  echo "id: $id"
  # separate pipeine
  cat $items_file | yq e '.items[] | select(.metadata.id == env(id))' > $id.yaml
  ls -ld $id.yaml
  codefresh replace pipeline -f $id.yaml
  rm -v $id.yaml
done
#yq -i e '.metadata.labels.tags += ["manual", "parasha"]' ~/dumps/scala.yml
