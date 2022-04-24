#!/bin/bash
#
# Delete CSDP runtime:

RE="$1"
cf runtime uninstall --silent --force "$RE"
# force     no erros on cluster or repo resource purging
# silent    disable commands wizard

# 
kubectl delete all --all -n "$RE"   # delete resources within namespace, ossumed same name as a runtime
kubectl delete ns "$RE" &           # delete namespace
kubectl get applications -n $RE -o yaml > $RE.yaml      # dump applications
yq -P -i e 'del(.items[].metadata.finalizers)' $RE.yaml # remove finalizers attribute
kubectl replace -f $RE.yaml         # replace applications
