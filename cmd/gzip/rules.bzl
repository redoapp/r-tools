def _gzip_toolchain_binary_impl(ctx):
    actions = ctx.actions
    gzip = ctx.toolchains[":toolchain"]
    name = ctx.attr.name

    executable = actions.declare_file(name)
    actions.symlink(output = executable, target_file = gzip.executable.files_to_run.executable)

    default_info = DefaultInfo(executable = executable, runfiles = gzip.executable.default_runfiles)

    return [default_info]

gzip_toolchain_binary = rule(
    executable = True,
    implementation = _gzip_toolchain_binary_impl,
    toolchains = [":toolchain"],
)
