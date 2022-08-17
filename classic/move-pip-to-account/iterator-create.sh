p=create.json
if [ -n "$1" ]; then
  ctx=$1
else
  ctx=$(cat ~/.cfconfig | yq e ".current-context" -)
fi
CF_API_KEY=$(  cat ~/.cfconfig | yq e ".contexts.$ctx.token" - | tr -d \" )
echo $CF_API_KEY
for id in $( yq e '.[].metadata.id' $p); do
  echo $id; export id
  echo "Creating new pipeline"
  yq -P e '.[] | select(.metadata.id==env(id))' $p > $id.yaml
  CF_API_KEY=$CF_API_KEY codefresh create pip -f $id.yaml || { echo "Creation failed"; exit; }
done
