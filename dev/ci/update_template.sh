#!/bin/bash
#
# This script is used to update our CI template in all sub-repositories.
#
# NOTE: the script should be invoked from the workspace root.
#

set -euf -o pipefail

if [[ $# -ne 0 ]]; then
  echo "Error: no arguments are expected."
  exit 1
fi

# Update the CI config on all checked-out sub-repositories.
make loop-subrepos LOOP_COMMAND="dev/ci/update_template_command.sh"
