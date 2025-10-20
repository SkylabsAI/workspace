#!/bin/sh -e
repo_relpath=$4
remote_upstream_branch=$3
./dev/worktrees/git-worktree.sh -t add ${topic} ${repo_relpath} ${remote_upstream_branch}
