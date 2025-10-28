#!/bin/bash
#
# This script is relied on by [update_template.sh] (via LOOP_COMMAND).
#

set -euf -o pipefail

if [[ $# -ne 4 ]]; then
  echo "Error: four command line arguments expected."
  exit 1
fi

REPO_DIR="$4"
WORKFLOW_DIR="${REPO_DIR}/.github/workflows"

mkdir -p "${WORKFLOW_DIR}/"
grep -v "^#" .github/workflows/ci.yml.template > "${WORKFLOW_DIR}/sl-fm-ci.yml"
git -C "${REPO_DIR}" add .
git -C "${REPO_DIR}" commit -m "[SkyLabs AI, FM CI] Workflow update"
