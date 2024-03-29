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
  #echo "[DEBUG] Processing $INPUT..."

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
  #echo "[DEBUG] templateRef: ${templateRef}"

  # Extract template in a variable
  template=`cat $INPUT | yq-json | jq --arg t "$action" '.spec.templates[] | select(.name == $t)'`
  #echo -e "[DEBUG] template:\n$template"

  # If has inputs.parameters, copy them under templates.name
  inputs=$( echo "$template" | jq -c 'select(has("inputs")) | .inputs | del(.artifacts)' - )

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

### START
[ -n "$1" ] || { \
  echo "Usage: `basename $0` WORKFLOW_TEMPLATE [TEMPLATE|all]"
  echo "Generate workflow for the referenced template. WORKFLOW_TEMPLATE is usually"
  echo "workflowTemplate.yaml file and TEMPLATE is one specified inside this file. If template"
  echo "was not specified, select prompt will be issued, special string 'all' will iterate over all the found templates"
  echo "and create file for each of them. After script is run generated files are found in the separate directory"
  exit 0;
}
WORKFLOW_TEMPLATE="$1"
# Collect all the templates under directory. From 'argo-hub.<tmpl_name>.<ver>' to <tmpl_name>
WORK_DIR=$( yq-print '.metadata.name | sub("(argo-hub.)?([^.]+)(.\d.*)","${2}")' ${WORKFLOW_TEMPLATE} )
mkdir -vp $WORK_DIR     # -p to ignore existing directories
echo "[DEBUG]Storing templates in '$WORK_DIR'"

# Figure out which template to process. Store templates in
# array to allow iteration
declare -a templates=( `yq -P e '.spec.templates[].name' "$WORKFLOW_TEMPLATE"` )
if [ -n "$2" ]; then
  if [[ "$2" = "all" ]]; then
    echo "creating workflow files for all found templates"
  else
    templates=( "${@:2}" )  # template was specified explicitly, from 2nd element onward
  fi 
else
  #+if no arguments were passed, issue select() prompt
  echo "Choose the template to process: "
  select t in ${templates[@]}
  do
    [ -n "$t" ] && break
    echo "choose from the available selections"
  done
  templates=( "$t" )
  # special option 'all' will create workflow files for each found template
fi
   
# put the templates under directory
for TEMPLATE in ${templates[@]}; do
  echo "processing template '$TEMPLATE'..."
  # call to createTemplateRef() here
  createTemplateRef "$WORKFLOW_TEMPLATE" "$TEMPLATE"
done

echo "All the templates stored under '$WORK_DIR'"
