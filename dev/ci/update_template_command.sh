#!/bin/bash
#
# This script is relied on by [update_template.sh] (via LOOP_COMMAND).
#

set -euf -o pipefail

if [[ $# -ne 5 ]]; then
  echo "Error: five command line arguments expected."
  exit 1
fi

REPO_DIR="$4"
CI_DIR="fmdeps/ci/"
CI_TEMPLATE="${CI_DIR}/.github/workflows/ci.yml.template"
WORKFLOW_DIR="${REPO_DIR}/.github/workflows"

if [[ "${REPO_DIR}" = ${CI_DIR} ]]; then
  echo "Skipping the ci directory."
  exit 0
fi

mkdir -p "${WORKFLOW_DIR}/"
grep -v "^#" "${CI_TEMPLATE}" > "${WORKFLOW_DIR}/sl-fm-ci.yml"
git -C "${REPO_DIR}" add .
git -C "${REPO_DIR}" commit -m "[SkyLabs AI, FM CI] Workflow update"
