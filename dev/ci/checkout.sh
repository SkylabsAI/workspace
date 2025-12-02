#!/bin/bash
#
# This script is used to checkout specific commits for all the repositories in
# the workspace, including for the workspace repository itself.
#
# It expects a single command-line argument: a path to the file specifying the
# commits for each repository of the workspace. Each of its lines should be of
# the form "<REPO_DIR>/: <COMMIT_HASH>".
#
# NOTE: the script should be invoked from the workspace root.
#

set -euf -o pipefail

if [[ $# -ne 1 ]]; then
  echo "Error: a single argument is expected (path to the commit config)."
  exit 1
fi

export COMMITS_FILE="$1"

if [[ ! -f "${COMMITS_FILE}" ]]; then
  echo "Error: file ${COMMITS_FILE} does not exist."
  exit 1
fi

if [[ -z "${DO_NOT_CLONE:-}" && "$(make loop LOOP_COMMAND=echo | wc -l)" != "1" ]]; then
  echo "Error: sub-repositories are already cloned."
  exit 1
fi

export LOOP_COMMAND="dev/ci/checkout_command.sh"

# Checkout the specified commit on the workspace repository.
make loop-workspace

# Clone all the sub-repos (shallowly).
if [[ -z "${DO_NOT_CLONE:-}" ]]; then
    make clone -j CLONE_ARGS="--depth 1 --quiet"
fi

# Checkout the specified commit on the sub-repositories.
make loop-subrepos -j
