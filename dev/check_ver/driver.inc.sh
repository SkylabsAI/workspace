#
# Copyright (c) 2025 SkyLabs AI, Inc.
#

set -euf -o pipefail

# Check that the expected variables are defined and non-empty.
for VAR in PROG URL MIN; do
  if [[ ! -v ${VAR} ]] ; then
    echo "Bug: variable ${VAR} not defined."
    exit 2
  fi
done

# Check that the print_ver function is defined.
if [[ ! $(type -t print_ver) == "function" ]]; then
  echo "Bug: function print_ver not defined."
  exit 2
fi

# Usage: available PROG
# Description: indicates whether PROG exists in PATH.
available() {
  type $1 2> /dev/null > /dev/null
}

# Usage: appropriate_version MIN VER [MAX]
# Description: indicates whether MIN ≤ VER < MAX, using version order.
appropriate_version() {
  if [[ "$2" == "$1" ]]; then
    # Version equal to the (included) lower bound.
    true
  elif [[ "$2" != "$(echo -e "$1\n$2" | sort -V | tail -n1)" ]]; then
    # Lower bound constraint violated.
    false
  elif [[ "$#" != "3" ]]; then
    # No upper-bound constraint.
    true
  elif [[ "$2" == "$3" ]]; then
    # Version equal to (excluded) upper bound.
    false
  else
    [[ "$2" == "$(echo -e "$2\n$3" | sort -V | head -n1)" ]]
  fi
}

instructions() {
  echo -e "\033[0;31m$1"
  if [[ -v MAX ]]; then
    echo -e "Install a version VER such that: ${MIN} ≤ VER < ${MAX}."
  else
    echo -e "Install a version VER such that: ${MIN} ≤ VER."
  fi
  if [[ -v RECOMMENDED ]]; then
    echo -e "Recommended version: ${RECOMMENDED}."
  fi
  echo -e "See ${URL} for instructions.\033[0m"
  exit 1
}

if ! available "${PROG}"; then
  instructions "Could not find ${PROG}."
fi

VER=$(print_ver)
if [[ -v MAX ]]; then
  if ! appropriate_version ${MIN} ${VER} ${MAX}; then
    instructions "Your version of ${PROG} (${VER}) is not supported."
  fi
else
  if ! appropriate_version ${MIN} ${VER}; then
    instructions "Your version of ${PROG} (${VER}) is not supported."
  fi
fi

if [[ $(type -t extra_checks) == "function" ]]; then
  extra_checks
fi

echo "Using ${PROG} version ${VER}."
