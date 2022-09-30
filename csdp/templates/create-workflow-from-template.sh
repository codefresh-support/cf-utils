#!/bin/bash
#
# From the workflowTemplate generate a workflow that utilizes it, 
# Processed template name, either accepted from the command line, selected in interactive prompt (not implemented)
# or all the templates can be processed in loop (-a) (not implemented).
    
# Create aliases for yq, that's a lot of manipulations with this tool.
shopt -s expand_aliases
alias yq-print="yq -P e "
alias yq-json="yq -o=json e "
alias yq-insert="yq -i"

# Creates a workflow file for the referenced template. The point to
# have it function is to allow iteration.
#
# Usage: createTemplateRef <workflowTemplate.yaml> [<template>]
function createTemplateRef() {
  
  # Accept workflowTemplate.yaml as an argument
  INPUT=$1
#  echo "[DEBUG] Processing $INPUT..."

  # Second argument is optional and is a tempalte name 
  action=$2
  if [ -z $action ]
  then 
    echo "Template name was not specified. exiting..."
    return 1
  fi
  # store generated template under $OUTPUT
  OUTPUT=${WORK_DIR:-.}/$action.yaml   
  cp template.yaml ${OUTPUT} -v

  # Parse initial template
  #
  # Get workflowTemplate name. Calling template name will be constructed as {action}:{templateRef}
  templateRef=`cat $INPUT | yq-print '.metadata.name' -`
#  echo "[DEBUG] templateRef: ${templateRef}"

  # Extract template in a variable
  template=`cat $INPUT | yq-json | jq --arg t "$action" '.spec.templates[] | select(.name == $t)'`

#  #echo -e "[DEBUG] template:\n$template"

#  echo -e "[DEBUG] Getting inputs\n"
  # If has inputs.parameters, copy them under templates.name
  inputs=$( echo "$template" | jq -c 'select(has("inputs")) | .inputs' )
#  echo -e "[DEBUG] inputs:\n$inputs"

#  echo "[DEBUG] constructing template name.."
  name=\"$action-$templateRef\"
#  echo "[DEBUG] name: $name"

  # All the data collected, writing template,
  # start from:
  #
  #apiVersion: argoproj.io/v1alpha1
  #kind: Workflow
  #metadata:
  #spec:
  #    entrypoint: main
  #    templates:
  #    -   name: main

  # test if file exists (TODO)

  # name
  echo -ne "Writing template name...\n"
  yq -i ".metadata.name = $name" $OUTPUT    # yq-insert

  # inputs
  if [ -n "$inputs" ]; then 
    echo "writing input parameters..."
    yq -i ".spec.templates[0].inputs = $inputs" $OUTPUT
  fi

  # templateRef
#  echo "[DEBUG] creating a reference..."
  #yq-print '.spec.templates[0].dag.tasks += [{"name": "'$action'", "templateRef": { "name": "'$templateRef'", "template": "'$action'" }}]' $OUTPUT
  yq -i '.spec.templates[0].dag.tasks += [{"name": "'$action'", "templateRef": { "name": "'$templateRef'", "template": "'$action'" }}]' $OUTPUT

  # inputs.parameters must be converted to arguments.parameters when passed to external template
  if [ -n "$inputs" ]; then
    arguments=$( echo "$inputs" | yq -o=json '. | with(.parameters[]; . = { "name": .name, "value": .name } | .value |= sub("(.*)", "{{ inputs.parameters.${1} }}"))' - | jq -c )
    echo "Writing argument parameters.."
#    echo "[DEBUG] $arguments"
    yq -i ".spec.templates[0].dag.tasks[].arguments += $arguments" $OUTPUT
  fi
}

WORKFLOW_TEMPLATE="$1"
# Collect all the templates under directory
WORK_DIR=$( yq-print '.metadata.name | sub("(argo-hub.)?([^.]+)(.\d.*)","${2}")' ${WORKFLOW_TEMPLATE} )
mkdir -vp $WORK_DIR     # -p to ignore existing directories
echo "Storing templates in '$WORK_DIR'"

if [ -z "$2" ]; then
  echo "Creating workflow files for all found templates"
  templates=( $( yq-print '.spec.templates[].name' "$WORKFLOW_TEMPLATE" ) )
else
  templates=( "$2"  ) 
fi
   
   #
# put the templates under directory
for TEMPLATE in ${templates[@]}; do
  echo "Processing template '$TEMPLATE'..."
  createTemplateRef "$WORKFLOW_TEMPLATE" "$TEMPLATE"
done
