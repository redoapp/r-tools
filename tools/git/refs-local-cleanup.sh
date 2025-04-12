cd "$BUILD_WORKSPACE_DIRECTORY"

git fetch --prune
git branch --merged main | sed 's, *,,' | grep -v '^main$' | xargs git branch -D
