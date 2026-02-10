load("@bazel_util//exec:repositories.bzl", "path_executable")

def _gzip_impl(module_ctx):
    path_executable(
        name = "host_gzip",
        executable = "gzip",
    )

    path_executable(
        name = "host_pigz",
        executable = "pigz",
    )

    return module_ctx.extension_metadata(
        reproducible = True,
    )

gzip = module_extension(
    implementation = _gzip_impl,
)
