load("@bazel_skylib//lib:shell.bzl", "shell")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@bazel_util//util:path.bzl", "runfile_path")
load(":transitions.bzl", "artifact_mode_transition", "artifact_transition")

def _artifact_target_impl(ctx):
    actions = ctx.actions
    dep_default = ctx.attr.dep[0][DefaultInfo]
    name = ctx.attr.name

    if dep_default.files_to_run.executable:
        # Bazel requires executable to come this target.
        # Create symlink to original executable.
        executable = actions.declare_file(name)
        actions.symlink(
            output = executable,
            target_file = dep_default.files_to_run.executable,
        )
        runfiles = ctx.runfiles(files = [executable])
        default_info = DefaultInfo(
            executable = executable,
            data_runfiles = runfiles.merge(dep_default.data_runfiles),
            default_runfiles = runfiles.merge(dep_default.default_runfiles),
        )
    else:
        default_info = dep_default

    return [default_info]

artifact_target = rule(
    attrs = {
        "dep": attr.label(cfg = artifact_mode_transition, doc = "Dependency", mandatory = True),
        "compilation_mode": attr.string(doc = "--compilation_mode, or empty to use existing value"),
        "platforms": attr.string(doc = "--platforms, or empty to use existing value"),
        "stamp": attr.int(default = -1, doc = "--stamp, or -1 to use existing value"),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    implementation = _artifact_target_impl,
)

def _s3_upload_impl(ctx):
    actions = ctx.actions
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    file = ctx.file.file
    name = ctx.attr.name
    runner = ctx.file._runner
    workspace = ctx.workspace_name

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        output = executable,
        substitutions = {
            "%{file}": shell.quote(runfile_path(workspace, file)),
        },
        template = runner,
    )

    runfiles = ctx.runfiles(files = [file])
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    return [default_info]

s3_upload = rule(
    attrs = {
        "file": attr.label(allow_single_file = True, cfg = artifact_transition, doc = "Directory to upload", mandatory = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = "s3-upload-runner.sh.tpl",
        ),
    },
    doc = "Upload file to S3",
    executable = True,
    implementation = _s3_upload_impl,
)
