cd "$BUILD_WORKSPACE_DIRECTORY"

git fetch --prune
git branch -r --merged origin/main |
    grep -v ' -> ' |
    grep ' origin/' |
    sed 's, *origin/,,' |
    grep -v '^main$' |
    xargs git push origin --delete
