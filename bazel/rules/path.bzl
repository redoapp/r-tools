def path_resolve(label, path):
    if path.startswith("/"):
        return path[len("/"):]
    return "/".join([part for part in [label.repo_name, label.package, path] if part])

def package_path_resolve(label, path):
    if path.startswith("/"):
        return path[len("/"):]
    return "/".join([part for part in [label.package, path] if part])
