#!/bin/bash
#
# This script is relied on by [checkout_command.sh] (via LOOP_COMMAND).
#

set -euf -o pipefail

if [[ $# -ne 5 ]]; then
  echo "Error: five command line arguments expected."
  exit 1
fi

REPO_DIR="$4"

if [[ -z "${COMMITS_FILE}" ]]; then
  echo "Error: the COMMITS_FILE environment is undefined or empty."
  exit 1
fi

REPO_HASH=$(grep "^${REPO_DIR}: " ${COMMITS_FILE} | cut -d ' ' -f 2)

git -C "${REPO_DIR}" fetch --depth 1 --quiet origin "${REPO_HASH}"
git -C "${REPO_DIR}" -c advice.detachedHead=false checkout "${REPO_HASH}"
