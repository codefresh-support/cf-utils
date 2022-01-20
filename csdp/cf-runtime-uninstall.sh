#!/bin/bash
#
# Delete CSDP runtime:

RE="$1"
codefresh runtime uninstall --force "$RE"

# 
kubectl get applications $RE -o yaml > $RE.yaml
yq -P -i e 'del(.items[].metadata.finalizers)' $RE.yaml
kubectl replace -f $RE.yaml
