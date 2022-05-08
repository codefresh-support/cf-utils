tag_opt=$( echo $* | grep -o -- '-t *\(\S\+\)' )
cmd=$( echo $* | sed 's/\(.*\)'"$tag_opt"'\(.*\)$/\1\2/' )
tag=$( echo $tag_opt | cut -f2 -d' ' )
echo "tag: $tag"
echo "cmd: $cmd"

#exit

# no arguments to codefresh
if [ -z "$cmd" ]; then
  echo "Usage: `basename $0` CF_FLAGS -t TAG"
  echo "Assign tags to the matched pipelines. CF_FLAGS are the same as to be passed to \`codefresh get pipeline'."
  echo "Then a TAG is appened or created on the retrieved pipelines. If you don't specify a tag, all the pipelines "
  echo "matching CF_FLAGS are printed. Only one tag can be added per execution."
  exit 0
fi

# Setup working directory
test -d 8j1riZ3ksq && rm -rf 8j1riZ3ksq
mkdir 8j1riZ3ksq 
cd 8j1riZ3ksq

# Get pipelines
set -x
codefresh get pipeline $cmd --limit 1000 -o yaml > items.yml   # already in $tmp directory
set +x

# iterate over pipelines
for id in $(cat items.yml | yq e ".items[].metadata.id")
do
  echo "id: $id"
  # separate pipeine
  cat items.yml | yq e '.items[] | select(.metadata.id == env(id))' -o json > $id.json

  # cat $id.json | jq '.metadata | has("labels")' # returns true
  if [ $(  cat $id.json | jq '.metadata | has("labels")' ) == "true" ] 
  then  # has "labels" add tags to existent one
    echo "has labels"
    jq '.metadata.labels.tags |= [ "'$tag'", .[] ]' $id.json | yq -P -o yaml > $id.yaml
  else
    echo "no labels" # no "labels" yet, create new 
    jq '.metadata.labels.tags = [ "'$tag'" ]' $id.json | yq -P -o yaml > $id.yaml
  fi
    ls $id.*
    echo "Updating `jq .metadata.name $id.json` with tag '$tag'..."
    cat $id.yaml | yq -P ".metadata.labels" -
    codefresh replace pipeline -f $id.yaml
done
#yq -i e '.metadata.labels.tags += ["manual", "parasha"]' ~/dumps/scala.yml
