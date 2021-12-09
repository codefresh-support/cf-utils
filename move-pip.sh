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
 echo "Usage: `basename $0` -s SRC_PRJ -d DEST_PRJ";
 echo "Move excess pipelines to another project. Leave only 300 pipelines "
 echo "in the source project."
 echo ""
 echo "  --source, -s       source project"
 echo "  --dest, -d         destination project"
 exit
}

while [ "$1" ]; do
 case "$1" in
  --src|-s)  SRC_PRJ=$2; shift;;
  --dest|-d) DEST_PRJ=$2; shift;;
  *) usage ;;
 esac
 shift
done

test -n "$SRC_PRJ" -a -n "$DEST_PRJ" || usage

# store destination project data
project=$(mktemp --tmpdir=. -t .pipXXX)

while ! [ -s $project ]
do
  # get data for the project (id and name)
  if codefresh get project $DEST_PRJ -o wide --sc id,name 2>/dev/null 1>$project
  then
    # set variables
    destProjectId=$(tail -1 $project | cut -d " " -f1)
    destProjectName=$(tail -1 $project | cut -d " " -f2)
  else
    # project was not found, create one instead
    echo "Creating project $DEST_PRJ"
    codefresh create project $DEST_PRJ
  fi
done
rm $project # remove temporary file

#echo $destProjectName
#echo $destProjectId

# make variables accessible in yq(1)
export destProjectId destProjectName sourceProjectName=$SRC_PRJ

# yaml files
pipelines=$(mktemp --tmpdir=. -t .pipXXX).json   # $max-300 pipelines
pipeline=$(mktemp --tmpdir=. -t .pipXXX).yaml    # single pipeline file used to create pipeline

# get excees pipelines from the source project (count starts from the top)
codefresh get pip --project $SRC_PRJ --limit --all -o json | jq ".[300:]"> $pipelines


# iterate over pipeline id's
for id in $(jq -r ".[].metadata.id" $pipelines)
do
  export id
  
  cat $pipelines |\
  yq -P eval '.[] | select(.metadata.id==env(id)) 
                  | with(.metadata; 
                      .name |= sub(env(sourceProjectName),env(destProjectName)), 
                      .projectId = env(destProjectId),
                      del(.project)) | .' - > $pipeline
  codefresh delete pip $id
  codefresh create pipeline -f $pipeline
done
rm $pipeline

echo "Original pipeline defitions are kept under '$pipelines' file. Do not delete it until you"
echo "verify that all the pipelines transferred correctly"
