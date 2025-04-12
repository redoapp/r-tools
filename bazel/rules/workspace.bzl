def _http_gz_impl(ctx):
    url = ctx.attr.url
    sha256 = ctx.attr.sha256

    ctx.download(
        output = "file.gz",
        sha256 = sha256,
        url = url,
    )
    ctx.template(
        "BUILD.bazel",
        Label(":http-gz.BUILD.bazel"),
    )

http_gz = repository_rule(
    attrs = {
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
    },
    implementation = _http_gz_impl,
)

def _path_executable_impl(ctx):
    executable = ctx.attr.executable

    path = ctx.which(executable)
    if path:
        ctx.symlink(path, "executable.sh")
    ctx.template(
        "BUILD.bazel",
        Label(":path-executable.bazel.tpl"),
        substitutions = {
            "%{existance}": json.encode(":exists" if path else ":not_exists"),
            "%{path}": json.encode(str(path) if path else ""),
        },
    )

path_executable = repository_rule(
    attrs = {
        "executable": attr.string(mandatory = True),
    },
    implementation = _path_executable_impl,
    local = True,
)
