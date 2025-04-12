load("@bazel_skylib//lib:shell.bzl", "shell")
load("@rules_file//util:path.bzl", "runfile_path")

def _ibazel_sock_activate_impl(ctx):
    actions = ctx.actions
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    bin = ctx.executable.bin
    bin_default = ctx.attr.bin[DefaultInfo]
    name = ctx.attr.name
    addrs = ctx.attr.addrs
    server = ctx.executable._server
    server_default = ctx.attr._server[DefaultInfo]
    runner = ctx.file._runner
    workspace = ctx.workspace_name

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        output = executable,
        substitutions = {
            "%{args}": " ".join([shell.quote("--addr=%s" % addr) for addr in addrs]),
            "%{bin}": shell.quote(runfile_path(workspace, bin)),
            "%{sock_activate}": shell.quote(runfile_path(workspace, server)),
        },
        template = runner,
    )

    runfiles = ctx.runfiles()
    runfiles = runfiles.merge(bin_default.default_runfiles)
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    runfiles = runfiles.merge(server_default.default_runfiles)
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    return [default_info]

ibazel_sock_activate = rule(
    attrs = {
        "addrs": attr.string_list(mandatory = True),
        "bin": attr.label(cfg = "target", executable = True, mandatory = True),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = "sock-activate-runner.sh.tpl",
        ),
        "_server": attr.label(
            cfg = "target",
            default = "//bazel/ibazel-sock-activate:bin",
            executable = True,
        ),
    },
    executable = True,
    implementation = _ibazel_sock_activate_impl,
)
