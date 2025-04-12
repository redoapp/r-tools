load("//bazel/rules:workspace.bzl", "path_executable")

def gzip_repositories():
    path_executable(
        name = "host_gzip",
        executable = "gzip",
    )

    path_executable(
        name = "host_pigz",
        executable = "pigz",
    )

def gzip_toolchains():
    native.register_toolchains(
        str(Label(":pigz_toolchain")),
        str(Label(":gzip_toolchain")),
    )
