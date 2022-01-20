#!/bin/bash
#
# Delete CSDP runtime:

RE="$1"
cf runtime uninstall --force "$RE"

# 
kubectl delete all --all -n "$RE"
kubectl delete ns "$RE" &
kubectl get applications -n $RE -o yaml > $RE.yaml
yq -P -i e 'del(.items[].metadata.finalizers)' $RE.yaml
kubectl replace -f $RE.yaml
