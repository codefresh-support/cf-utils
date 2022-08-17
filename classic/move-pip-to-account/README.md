Script will move pipelines from the project in one account to the project under another account.

Usage:  ./move-pip-to-account.sh SRC_PRJ DEST_PRJ [SRC_CTX] DEST_CTX

SRC_CTX and DEST_CTX refer to the codefresh authentication context names, and they must be created previously with `codefresh auth create-context`.

Before pipelines are moved they are stored and processed in the file. If something goes wrong this file can be used to recreate pipelines using iterate-*.sh scripts. 
