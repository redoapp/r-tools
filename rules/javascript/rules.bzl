def _js_gen_transition_impl(settings, attrs):
    return {
        "@rules_javascript//javascript:language": "es2020",
        "@rules_javascript//javascript:module": "commonjs",
        "@rules_javascript//javascript:source_map": False,
    }

_js_gen_transition = transition(
    implementation = _js_gen_transition_impl,
    inputs = [],
    outputs = [
        "@rules_javascript//javascript:language",
        "@rules_javascript//javascript:module",
        "@rules_javascript//javascript:source_map",
    ],
)

def _js_gen_impl(ctx):
    src_default = ctx.attr.src[DefaultInfo]

    default_info = src_default

    return [default_info]

js_gen = rule(
    attrs = {
        "src": attr.label(mandatory = True),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    cfg = _js_gen_transition,
    implementation = _js_gen_impl,
)
