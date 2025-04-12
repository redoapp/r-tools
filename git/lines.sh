cd "$BUILD_WORKSPACE_DIRECTORY"

"$(rlocation r_tools/git/files)" |
    sed s/^/HEAD:/ |
    git cat-file --batch=----- |
    grep -v '^-----$' |
    wc -l
