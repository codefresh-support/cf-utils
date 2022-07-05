#!/bin/bash

# next improvenment is to take put in the clipboard immediately
echo '{ "settings.allowAdminToLogin" : true, "account" : ObjectId("'$1'") }'
