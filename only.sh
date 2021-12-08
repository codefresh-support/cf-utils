export sourceProjectName=source
export destProjectName=dest
export destProjectId=61b1013dd8e622f71194c7e1
  yq -P eval '.[] | with (.metadata; 
                  .name |= sub(env(sourceProjectName),env(destProjectName)), 
                  .projectId = env(destProjectId),
                  del(.project)) | [.]' pipelines.json
