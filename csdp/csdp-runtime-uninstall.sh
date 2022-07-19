#!/bin/bash
#
# Delete CSDP runtime:

# Check parameter numbers
if [ $# -ne 1 ]; then
  echo "Incorrect number of arguments"
  echo "Usage:"
  echo "cf-runtime-uninstall.sh RUNTIME_NAME"
  exit 1
fi
NAME="$1"

echo "Removing CSDP runtime $NAME"
cf runtime uninstall --force "$NAME" --silent

echo "Deleting remaining objects"
# Edit apps to remove finalizers
for i in $(kubectl get applications -o name -n $NAME)
do
  kubectl patch  $i --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' -n $NAME
done
for OBJ in apps deployments replicaset pods service statefulset sealedSecret
do
  kubectl get $OBJ --no-headers -n $NAME| awk '{print $1}' | xargs kubectl  -n $NAME delete $OBJ
done

echo "Deleting namespace $NAME"
kubectl delete ns $NAME
