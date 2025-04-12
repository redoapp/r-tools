git ls-files |
    git check-attr --stdin linguist-generated |
    grep -v ' set$' |
    cut -d: -f1 |
    git check-attr --stdin linguist-vendored |
    grep -v ' set$' |
    cut -d: -f1
