#!/bin/bash
#
# Copyright (c) 2024 BlueRock Security, Inc.
#
# This software is distributed under the terms of the BlueRock Open-Source
# License. See the LICENSE-BlueRock file at the repository root for details.
#

set -euf -o pipefail

EXP_MAJOR_VER="1" # we could have min and max here as well but the range check becomes more complicated
MIN_MINOR_VER="85"
MAX_MINOR_VER="90"
RECOMMENDED_MINOR_VER="90"

RECOMMENDED_VER="${EXP_MAJOR_VER}.${RECOMMENDED_MINOR_VER}"
MIN_VER="${EXP_MAJOR_VER}.${MIN_MINOR_VER}"
MAX_VER="${EXP_MAJOR_VER}.${MAX_MINOR_VER}"

usage () {
    echo -e "A version between ${MIN_VER} and ${MAX_VER} is expected.\033[0m"
    echo -e "We recommend version ${RECOMMENDED_VER} (see https://rust-lang.org/tools/install/).\033[0m"
}

if ! type rustc 2> /dev/null > /dev/null; then
  echo -e "\033[0;31mCould not find rustc."
  usage
  exit 1
fi

VER="$(rustc --version | \
               grep "rustc" | \
               sed -r 's/^.*rustc ([0-9.]+).*$/\1/' | \
               cut -d' ' -f3)"
if ! [[ $VER =~ ([^\.]*)\.([^\.]*)\.([^\.]*) ]]; then
    echo "Unable to parse the output of 'rustc --version':"
    rustc --version
    usage
    exit 1
fi
MAJOR_VER="${BASH_REMATCH[1]}"
MINOR_VER="${BASH_REMATCH[2]}"

if ! (( EXP_MAJOR_VER == MAJOR_VER && \
        MIN_MINOR_VER <= MINOR_VER && MINOR_VER <= MAX_MINOR_VER )); then
  echo -e "\033[0;31mError: rustc version ${VER} is not supported."
  usage
  exit 1
fi

echo "Using rustc version ${VER}."
