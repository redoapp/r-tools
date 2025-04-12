load("@better_rules_javascript//nodejs:rules.bzl", "nodejs_binary_package")
load("@rivet_bazel_util//util:rules.bzl", "digest")
load("@rules_pkg//pkg:mappings.bzl", "pkg_mklink")
load("@rules_pkg//pkg:zip.bzl", "pkg_zip")

def _cf_transition_impl(settings, attrs):
    return {"@better_rules_javascript//javascript:source_map": False}

_cf_transition = transition(
    implementation = _cf_transition_impl,
    inputs = [],
    # TODO: @better_rules_javascript//javascript:language
    outputs = ["@better_rules_javascript//javascript:source_map"],
)

def _cf_function_impl(ctx):
    actions = ctx.actions
    name = ctx.attr.name
    src = ctx.file.src

    output = actions.declare_directory(name) if src.is_directory else actions.declare_file(name)
    actions.symlink(output = output, target_file = src)

    default_info = DefaultInfo(files = depset([output]))

    return [default_info]

cf_function = rule(
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    cfg = _cf_transition,
    implementation = _cf_function_impl,
)

def _lambda_nodejs_transition_impl(settings, attrs):
    return {
        "//command_line_option:compilation_mode": "opt",
        "//command_line_option:platforms": "//aws/rules:lambda",
    }

# Could exclude AWS libraries with @better_rules_javascript//javascript:system_lib
# But the versioning lags many months behind.
_lambda_nodejs_transition = transition(
    implementation = _lambda_nodejs_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:compilation_mode", "//command_line_option:platforms"],
)

def _lambda_nodejs_function_env_impl(ctx):
    actions = ctx.actions
    name = ctx.attr.name
    src = ctx.file.src

    output = actions.declare_file("%s.zip" % name)
    actions.symlink(output = output, target_file = src)

    default_info = DefaultInfo(files = depset([output]))

    return [default_info]

_lambda_nodejs_function_env = rule(
    attrs = {
        "src": attr.label(allow_single_file = [".zip"], mandatory = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    cfg = _lambda_nodejs_transition,
    implementation = _lambda_nodejs_function_env_impl,
)

def lambda_nodejs_function(name, dep, **kwargs):
    digest(
        name = "%s.digest" % name,
        srcs = [":%s" % name],
        **kwargs
    )

    nodejs_binary_package(
        name = "%s.pkg" % name,
        dep = dep,
        main = "_",
        node = "@better_rules_javascript//nodejs/default:system_nodejs",
        **kwargs
    )

    pkg_zip(
        name = "%s.pkg.zip" % name,
        srcs = [":%s.pkg" % name],
        **kwargs
    )

    _lambda_nodejs_function_env(
        name = name,
        src = "%s.pkg.zip" % name,
        **kwargs
    )

def lambda_nodejs_symlink(name, file, package_name, target, **kwargs):
    pkg_zip(
        name = name,
        srcs = [":%s.link" % name],
        **kwargs
    )

    pkg_mklink(
        name = "%s.link" % name,
        link_name = file,
        target = "/opt/%s/%s" % (package_name, target),
        **kwargs
    )
