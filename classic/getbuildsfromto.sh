#!/bin/bash

i=1
#set -x
while codefresh get builds -p $i -l 100 --from=2022-06-17 --to=2022-08-17 | grep -v "no available resources" 
do echo "i: $i"; ((i++)); done
