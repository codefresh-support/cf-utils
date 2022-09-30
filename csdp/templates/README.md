ffffffff### Generate workflow that references workflowTemplate

##### Usage: create-workflow-from-template.sh WORKFLOW_TEMPLATE [TEMPLATE|all]

Generate workflow for the referenced template. WORKFLOW_TEMPLATE is usually
workflowTemplate.yaml file and TEMPLATE is one specified inside this file.

##### Example:
Template `create-pr` from the `workflowTemplate.yaml`
with the following input parameters:

    inputs:
       artifacts:
         - name: repo
           path: /code
       parameters:
         - name: BRANCH
         - name: MESSAGE
         - name: PR_TEMPLATE
         - name: GITHUB_TOKEN_SECRET
         - name: GITHUB_USER
           default: 'x-access-token'

After passing it to script as:

`./create-workflow-from-template.sh workflowTemplate.yaml create-pr`

will result in:

    spec:
      entrypoint: main
      templates:
        - name: main
          inputs:
            parameters:
              - name: BRANCH
              - name: MESSAGE
              - name: PR_TEMPLATE
              - name: GITHUB_TOKEN_SECRET
              - name: GITHUB_USER
                default: x-access-token
          dag:
            tasks:
              - name: create-pr
                templateRef:
                  name: argo-hub.github.0.0.5
                  template: create-pr
                arguments:
                  parameters:
                    - name: BRANCH
                      value: '{{ inputs.parameters.BRANCH }}'
                    - name: MESSAGE
                      value: '{{ inputs.parameters.MESSAGE }}'
                    - name: PR_TEMPLATE
                      value: '{{ inputs.parameters.PR_TEMPLATE }}'
                    - name: GITHUB_TOKEN_SECRET
                      value: '{{ inputs.parameters.GITHUB_TOKEN_SECRET }}'
                    - name: GITHUB_USER
                      value: '{{ inputs.parameters.GITHUB_USER }}'

Please notice that `.inputs.parameters` part was added that is necessary for delivery pipeline to accept arguments in UI for example, thus is almost always mandatory, values in `.arguments.parameters` were converted to read `.inputs.parameters`. `.inputs.artifacts` were removed.

 If template was not specified, select prompt will be issued:

    $ bash create-workflow-from-template.sh workflowTemplate.yaml 
    Storing templates in 'github'
    Choose the template to process: 
    1) commit-status
    2) create-pr
    3) create-pr-comment
    4) extract-webhook-variables
    5) create-pr-codefresh
    #? 

Special string `all` can specified instead of `TEMPLATE` in which case, **a**ll the templates will be iterated over and workflow file will be created for each of them. After script is run generated files are found in the separate directory, name depends on the referenced template filename.

    All the templates stored under 'jira'
