Script will move pipelines from the project in one account to the project under another account.

Usage:  ./move-pip-to-account.sh SRC_PRJ DEST_PRJ [SRC_CTX] DEST_CTX

SRC_CTX and DEST_CTX refer to the codefresh authentication context names, and they must be created previously with `codefresh auth create-context`.

Before pipelines are moved they are stored and processed in the file. If something goes wrong this file can be used to recreate pipelines using iterate-*.sh scripts. 

Consider example where pipelines from project "a" from account "A" moved to project "b" under account "B", the command will be:

  ./move-pip-to-account.sh a b A B

If current context is set to "A" then 3rd argument can be ommited and will be equivalent to    ./move-pip-to-account.sh a b B

The flow is:

  1. Use current context
  2. Dump all the source project pipelines to file ($sp)
  3. Change destinationName, accountId and project properties for each pipeline in the file
  4. Switch to the destination context and create destination project if doesn't exist
  5. Iterate through each pipeline in a file and store definition in a file
  6. Use it's id to delete pipeline
  7. Use stored definition to create pipeline
