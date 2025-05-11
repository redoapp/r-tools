load("@bazel_skylib//lib:shell.bzl", "shell")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@rivet_bazel_util//bazel:aspects.bzl", "digest")
load("@rivet_bazel_util//bazel:providers.bzl", "create_digest")
load("@rules_file//util:path.bzl", "runfile_path")
load(":transitions.bzl", "mode_transition")

def _build_setting_file_impl(ctx):
    actions = ctx.actions
    content_build_info = ctx.attr.content[BuildSettingInfo]
    output = ctx.outputs.out

    actions.write(
        content = content_build_info.value,
        output = output,
    )

    default_info = DefaultInfo(files = depset([output]))

    return [default_info]

build_setting_file = rule(
    attrs = {
        "content": attr.label(providers = [BuildSettingInfo]),
        "out": attr.output(mandatory = True),
    },
    implementation = _build_setting_file_impl,
)

def _command_impl(ctx):
    actions = ctx.actions
    args = ctx.attr.args
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    bin = ctx.executable.bin
    bin_default = ctx.attr.bin[DefaultInfo]
    data = ctx.files.data
    data_default = [target[DefaultInfo] for target in ctx.attr.data]
    name = ctx.attr.name
    runner = ctx.file._runner
    workspace = ctx.workspace_name

    executable = actions.declare_file(name)
    actions.expand_template(
        substitutions = {
            "%{bin}": shell.quote(runfile_path(workspace, bin)),
            "%{args}": " ".join([shell.quote(ctx.expand_location(arg)) for arg in args]),
        },
        is_executable = True,
        output = executable,
        template = runner,
    )

    runfiles = ctx.runfiles(files = data)
    runfiles = runfiles.merge(bin_default.default_runfiles)
    runfiles = runfiles.merge(bash_runfiles_default.default_runfiles)
    runfiles = runfiles.merge_all([default_info.default_runfiles for default_info in data_default])
    default_info = DefaultInfo(executable = executable, runfiles = runfiles)

    return [default_info]

command = rule(
    implementation = _command_impl,
    attrs = {
        "bin": attr.label(
            cfg = "target",
            executable = True,
            mandatory = True,
        ),
        "data": attr.label_list(allow_files = True),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = "command-runner.sh.tpl",
        ),
    },
    executable = True,
)

def _executable_path_impl(ctx):
    actions = ctx.actions
    name = ctx.attr.name
    path = ctx.attr.path

    symlink = actions.declare_symlink(name)
    actions.symlink(output = symlink, target_path = path)

    default_info = DefaultInfo(executable = symlink)

    return [default_info]

executable_path = rule(
    attrs = {
        "path": attr.string(mandatory = True),
    },
    executable = True,
    implementation = _executable_path_impl,
)

def _executable_toolchain_impl(ctx):
    executable_default = ctx.attr.executable[DefaultInfo]

    toolchain_info = platform_common.ToolchainInfo(
        executable = executable_default,
    )

    return [toolchain_info]

executable_toolchain = rule(
    attrs = {
        "executable": attr.label(cfg = "target", executable = True, mandatory = True),
    },
    implementation = _executable_toolchain_impl,
    provides = [platform_common.ToolchainInfo],
)

def _mode_target_impl(ctx):
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

mode_target = rule(
    attrs = {
        "dep": attr.label(cfg = mode_transition, doc = "Dependency", mandatory = True),
        "compilation_mode": attr.string(doc = "--compilation_mode, or empty to use existing value"),
        "platforms": attr.string(doc = "--platforms, or empty to use existing value"),
        "stamp": attr.int(default = -1, doc = "--stamp, or -1 to use existing value"),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    implementation = _mode_target_impl,
)

def _pre_run_impl(ctx):
    actions = ctx.actions
    args = ctx.attr.args
    bash_runfiles_default = ctx.attr._bash_runfiles[DefaultInfo]
    hash = ctx.attr._hash[DefaultInfo]
    name = ctx.attr.name
    pre_program = ctx.executable.pre_program
    pre_program_default = ctx.attr.pre_program[DefaultInfo]
    pre_args = ctx.attr.pre_args
    pre_run = ctx.executable._pre_run
    pre_run_default = ctx.attr._pre_run[DefaultInfo]
    program = ctx.executable.program
    program_default = ctx.attr.program[DefaultInfo]
    program_output_group = ctx.attr.program[OutputGroupInfo]
    runner = ctx.file._runner
    workspace = ctx.workspace_name

    executable = actions.declare_file(name)
    actions.expand_template(
        substitutions = {
            "%{pre_program}": shell.quote(runfile_path(workspace, pre_program)),
            "%{pre_args}": " ".join(["--pre-arg=%s" % shell.quote(arg) for arg in pre_args]),
            "%{program}": shell.quote(runfile_path(workspace, program)),
            "%{args}": " ".join([shell.quote(arg) for arg in args]),
            "%{pre_run}": shell.quote(runfile_path(workspace, pre_run)),
        },
        is_executable = True,
        output = executable,
        template = runner,
    )

    inner_runfiles = ctx.runfiles(files = [executable], transitive_files = program_output_group.digest)
    inner_runfiles = inner_runfiles.merge(bash_runfiles_default.default_runfiles)
    inner_runfiles = inner_runfiles.merge(pre_run_default.default_runfiles)
    digest = create_digest(
        actions = actions,
        hash = hash,
        name = name,
        runfiles = inner_runfiles,
    )

    runfiles = bash_runfiles_default.default_runfiles
    runfiles = runfiles.merge(pre_run_default.default_runfiles)
    runfiles = runfiles.merge(pre_program_default.default_runfiles)
    runfiles = runfiles.merge(program_default.default_runfiles)
    default_info = DefaultInfo(
        executable = executable,
        runfiles = runfiles,
    )

    output_group_info = OutputGroupInfo(
        digest = depset([digest]),
    )

    return [default_info, output_group_info]

pre_run = rule(
    attrs = {
        "pre_program": attr.label(
            cfg = "target",
            executable = True,
            mandatory = True,
        ),
        "pre_args": attr.string_list(),
        "program": attr.label(
            aspects = [digest],
            cfg = "target",
            executable = True,
            mandatory = True,
        ),
        "_bash_runfiles": attr.label(
            default = "@bazel_tools//tools/bash/runfiles",
        ),
        "_hash": attr.label(
            cfg = "exec",
            default = "@rivet_bazel_util//util/hash:bin",
            executable = True,
        ),
        "_pre_run": attr.label(
            cfg = "target",
            default = "//bazel/pre-run:bin",
            executable = True,
        ),
        "_runner": attr.label(
            allow_single_file = True,
            default = "pre-run-runner.sh.tpl",
        ),
    },
    executable = True,
    implementation = _pre_run_impl,
)

def _runfile_package_impl(ctx):
    actions = ctx.actions
    label = ctx.label
    name = label.name
    workspace = ctx.workspace_name

    output = actions.declare_file("%s.txt" % name)
    actions.write(content = "%s/%s" % (workspace, label.package) if label.package else workspace, output = output)

    default_info = DefaultInfo(files = depset([output]))

    return [default_info]

runfile_package = rule(
    implementation = _runfile_package_impl,
)

def _setting_file_impl(ctx):
    actions = ctx.actions
    name = ctx.attr.name
    setting_setting_info = ctx.attr.setting[BuildSettingInfo]

    output = actions.declare_file(name)
    actions.write(content = setting_setting_info.value, output = output)

    default_info = DefaultInfo(files = depset([output]))

    return [default_info]

setting_file = rule(
    attrs = {
        "setting": attr.label(mandatory = True, providers = [BuildSettingInfo]),
    },
    implementation = _setting_file_impl,
)

def _stamp_inner_impl(ctx):
    actions = ctx.actions
    key = ctx.attr.key
    info_file = ctx.info_file
    name = ctx.attr.name
    stamp = ctx.attr.stamp
    stamp_setting = ctx.attr.stamp_setting
    version_file = ctx.version_file

    output = actions.declare_file("%s.txt" % name)

    if stamp == 1 or stamp == -1 and stamp_setting:
        args = actions.args()
        args.add(key)
        args.add(info_file)
        args.add(version_file)
        args.add(output)
        actions.run_shell(
            arguments = [args],
            command = 'sed -n "s/^$1 //p" "$2" "$3" | tr -d "\\n" > "$4"',
            inputs = [ctx.info_file, ctx.version_file],
            outputs = [output],
        )
    else:
        actions.write(content = "", output = output)

    default_info = DefaultInfo(files = depset([output]))

    return [default_info]

_status_inner = rule(
    attrs = {
        "key": attr.string(mandatory = True),
        "stamp": attr.int(default = -1),
        "stamp_setting": attr.bool(mandatory = True),
    },
    implementation = _stamp_inner_impl,
)

def status(name, key, stamp = None):
    _status_inner(
        name = name,
        key = key,
        stamp = stamp,
        stamp_setting = select({
            Label(":stamp"): True,
            "//conditions:default": False,
        }),
    )

def _query_bzl_impl(ctx):
    actions = ctx.actions
    name = ctx.attr.name
    query = ctx.attr.query
    out = ctx.attr.out
    if out.startswith("/"):
        out = out[len("/"):]
    elif ctx.label.package:
        out = "%s/%s" % (ctx.label.package, out)
    runner = ctx.file._runner

    executable = actions.declare_file(name)
    actions.expand_template(
        is_executable = True,
        substitutions = {
            "%{query}": shell.quote(query),
            "%{output}": shell.quote(out),
        },
        output = executable,
        template = runner,
    )

    default_info = DefaultInfo(executable = executable)

    return [default_info]

query_bzl = rule(
    attrs = {
        "query": attr.string(mandatory = True),
        "out": attr.string(mandatory = True),
        "_runner": attr.label(
            allow_single_file = True,
            default = "query-targets.sh.tpl",
        ),
    },
    executable = True,
    implementation = _query_bzl_impl,
)
