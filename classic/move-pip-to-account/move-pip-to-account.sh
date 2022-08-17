#!/bin/bash
# 
# Move pipelines under another project. Projects will display 
# and make accessible only last 300 pipelines, pipelines created
# prior that must be put under another project. The script belt
# as a workaround to automate transfer. 
#
# Jira: https://codefresh-io.atlassian.net/browse/CR-7896
#

usage() {
 echo "Usage: `basename $0` <src_prj> <dest_prj> [<src_ctx>] <dest_ctx>"
 echo "Move pipelines from <src_prj> in the account pointed by <src_ctx> to the <dest_prj> "
 echo "in the account pointed by <dest_ctx>. If <src_ctx> is omitted current account is assumed."
 exit
}

test $# -ge 3 || usage
src_prj=$1 dest_prj=$2 src_ctx=$3 dest_ctx=$4

# if dest_ctx was passed, meaning that src_ctx is passed as well, then use it,
# otherwise dest_ctx=$3=$src_ctx
test -n "$dest_ctx" || { export dest_ctx=$src_ctx; unset src_ctx; } 
test -z "$src_ctx"  || codefresh auth use-context $src_ctx || { exit 1; }

# Store the key, used to delete source pipelines earlier without switching
# context constantly
ctx=$(cat ~/.cfconfig | yq e ".current-context" -)
CF_API_KEY=$(  cat ~/.cfconfig | yq e ".contexts.$ctx.token" - | tr -d \" )

# store destination project data
sp=$src_prj.json
dp=$dest_prj.json
codefresh get pip --project $src_prj --limit 10 -o json > $sp

# project was not found, create one instead
codefresh auth use-context $dest_ctx || { exit 1; }
codefresh get project $dest_prj &>/dev/null && { echo "Project exists, continuing..."; } || \
  {  echo "Creating project '$dest_prj'"; codefresh create project $dest_prj; }

# init account id
accountId=$(codefresh get pip -o json --limit 1 | jq -r '.metadata.accountId')
echo "accountId: $accountId"

# make variables accessible in yq(1)
export accountId src_prj dest_prj 

# 1. Rewrite needed data in the source pipelines and store under $dp
cat $sp |\
yq -P '. | with(.[];  .metadata.name |= sub(env(src_prj),env(dest_prj)) | .metadata = { "name": .metadata.name, "id": .metadata.id } | .metadata += { "accountId": env(accountId), "project": env(dest_prj) })' - > $dp

# 2. Iterate over pipelines, delete and recreate
for id in $( yq e '.[].metadata.id' $dp); do
  echo $id; export id
  yq -P e '.[] | select(.metadata.id==env(id))' $dp > $id.yaml
  echo "Deleting old pipeline"
  CF_API_KEY=$CF_API_KEY codefresh delete pip $id || { echo "Deleting failed"; exit; }
  echo "Creating new pipeline"      # test with removed token
  codefresh create pip -f $id.yaml || { echo "Creation failed, reverting deletion.."; \
                                        CF_API_KEY=$CF_API_KEY codefresh create pip -f $id.yaml; \
                                        exit; }
done

# Remove files
#rm $sp $dp

echo "Original pipeline defitions are kept under '$sp' file. Do not delete it until you"
echo "verify that all the pipelines transferred correctly"
