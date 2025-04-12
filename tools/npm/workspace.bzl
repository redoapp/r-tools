load("@better_rules_javascript//commonjs:workspace.bzl", "cjs_directory_npm_plugin")
load("@better_rules_javascript//npm:workspace.bzl", "npm")
load("@better_rules_javascript//typescript:workspace.bzl", "ts_directory_npm_plugin")
load(":npm.bzl", "PACKAGES", "ROOTS")

def npm_repositories():
    plugins = [
        cjs_directory_npm_plugin(),
        ts_directory_npm_plugin(),
    ]
    npm("npm", roots = ROOTS, packages = PACKAGES, plugins = plugins)
