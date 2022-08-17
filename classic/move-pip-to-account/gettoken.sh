ctx=$(cat ~/.cfconfig | yq e ".current-context" -)
cat ~/.cfconfig | yq e ".contexts.$ctx.token" - | tr -d \"
