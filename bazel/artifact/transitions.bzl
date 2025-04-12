def _artifact_transition_impl(settings, attr):
    return {
        "//command_line_option:compilation_mode": settings["//bazel/artifact:compilation_mode"] or settings["//command_line_option:compilation_mode"],
        "//command_line_option:platforms": settings["//bazel/artifact:platforms"] or settings["//command_line_option:platforms"],
        "//command_line_option:stamp": bool(settings["//bazel/artifact:stamp"]) if settings["//bazel/artifact:stamp"] != -1 else settings["//command_line_option:stamp"],
    }

artifact_transition = transition(
    implementation = _artifact_transition_impl,
    inputs = [
        "//bazel/artifact:compilation_mode",
        "//bazel/artifact:platforms",
        "//bazel/artifact:stamp",
        "//command_line_option:compilation_mode",
        "//command_line_option:platforms",
        "//command_line_option:stamp",
    ],
    outputs = [
        "//command_line_option:compilation_mode",
        "//command_line_option:platforms",
        "//command_line_option:stamp",
    ],
)

def _artifact_mode_transition_impl(settings, attr):
    result = {
        "//bazel/artifact:compilation_mode": attr.compilation_mode or settings["//bazel/artifact:compilation_mode"],
        "//bazel/artifact:platforms": attr.platforms or settings["//bazel/artifact:platforms"],
        "//bazel/artifact:stamp": bool(attr.stamp) if attr.stamp != -1 else settings["//bazel/artifact:stamp"],
    }
    for key, value in result.items():
        if value != settings[key]:
            return result

artifact_mode_transition = transition(
    implementation = _artifact_mode_transition_impl,
    inputs = [
        "//bazel/artifact:compilation_mode",
        "//bazel/artifact:platforms",
        "//bazel/artifact:stamp",
    ],
    outputs = [
        "//bazel/artifact:compilation_mode",
        "//bazel/artifact:platforms",
        "//bazel/artifact:stamp",
    ],
)
