"""Delete branches that are merged into every given branch.

Without --remote, cleans up local branches. With --remote, cleans up branches
on that remote instead.
"""

from argparse import ArgumentParser
import os
import subprocess


def main():
    parser = ArgumentParser(prog="git-branches-cleanup", description=__doc__)
    parser.add_argument("--remote", help="remote to clean up (default: local)")
    parser.add_argument("branches", nargs="+", help="branches to check merges against")
    args = parser.parse_args()

    workspace = os.environ.get("BUILD_WORKSPACE_DIRECTORY")
    if workspace:
        os.chdir(workspace)

    if args.remote:
        subprocess.run(["git", "fetch", "--prune", args.remote], check=True)
        prefix = f"refs/remotes/{args.remote}/"
    else:
        prefix = "refs/heads/"

    bases = [bare_name(base, args.remote) for base in args.branches]
    per_base = [merged_branches(prefix, base) for base in bases]
    names = set.intersection(*(set(b) for b in per_base)) - set(bases)
    if not names:
        return
    shas = per_base[0]

    if args.remote:
        delete = ["git", "push", args.remote]
        delete += [
            f"--force-with-lease=refs/heads/{name}:{shas[name]}"
            for name in sorted(names)
        ]
        delete += [f":refs/heads/{name}" for name in sorted(names)]
    else:
        delete = ["git", "branch", "-d", *sorted(names)]
    subprocess.run(delete, check=True)


def bare_name(branch, remote):
    """Reduce a base to its bare name, accepting bare, remote-qualified, or
    fully-qualified forms (main, origin/main, refs/heads/main)."""
    prefixes = ["refs/heads/"]
    if remote:
        prefixes += [f"refs/remotes/{remote}/", f"{remote}/"]
    for prefix in prefixes:
        if branch.startswith(prefix):
            return branch[len(prefix) :]
    return branch


def merged_branches(prefix, base):
    """Map of branch name (without `prefix`) to SHA, for refs merged into `base`."""
    output = subprocess.run(
        [
            "git",
            "for-each-ref",
            "--merged",
            f"{prefix}{base}",
            "--format=%(objectname) %(refname)",
            prefix,
        ],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    ).stdout
    branches = {}
    for line in output.splitlines():
        sha, ref = line.split(" ", 1)
        name = ref[len(prefix) :]
        if name != "HEAD":
            branches[name] = sha
    return branches


main()
