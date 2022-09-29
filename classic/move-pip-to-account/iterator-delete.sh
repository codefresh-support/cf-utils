p=delete.json
if [ -n "$1" ]; then
  ctx=$1
else
  ctx=$(cat ~/.cfconfig | yq e ".current-context" -)
fi
CF_API_KEY=$(  cat ~/.cfconfig | yq e ".contexts.$ctx.token" - | tr -d \" )
echo $CF_API_KEY
#codefresh auth use-context mv-project
for id in $( yq e '.[].metadata.id' $p); do
  echo "Deleting pipeline $id"
  echo $id; export id
  CF_API_KEY=$CF_API_KEY codefresh delete pip $id || { echo "Deleting failed"; exit; }
  #echo "Creating new pipeline"
  #codefresh create pip -f $id.yaml
done
