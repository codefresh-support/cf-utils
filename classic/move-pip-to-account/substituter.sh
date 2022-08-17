export accountId=5f8db07b4e6ba71a9d6a4bdb src_prj=source dst_prj=destination
p=source.json
cat $p |\
yq -P '. | with(.[];  .metadata.name |= sub(env(src_prj),env(dst_prj)) | .metadata = { "name": .metadata.name, "id": .metadata.id } | .metadata += { "accountId": env(accountId), "project": env(dst_prj) })' -

#for id in $(jq '.[].metadata.id' $p); do
  #jq '.'
